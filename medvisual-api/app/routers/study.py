"""Aralikli tekrar (SM-2) calisma uclari.

SM-2 otoritesi sunucudur: istemci yalnizca grade gonderir, yeni durum
burada hesaplanir ve DB'ye yazilir (Single Source of Truth).
"""
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.helpers import get_owned_row
from app.schemas import ReviewReq
from app.sm2 import ReviewState, apply_sm2

router = APIRouter(prefix="/study", tags=["study"])


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _parse_ts(value: str) -> datetime:
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


@router.get("/due")
def due_cards(
    set_id: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    mode: str = Query("due", description="due | cram (cram: vade filtresi yok)"),
    user: AuthUser = Depends(get_current_user),
):
    """Vadesi gelmis kartlar: hic calisilmamis olanlar + due_at <= simdi.
    Hic calisilmamis kartlar one alinir (yeni kart onceligi).
    mode=cram: TUM kartlar vade durumuna bakilmadan doner (serbest calisma;
    istemci karistirir, notlar sunucuya YAZILMAZ)."""
    if set_id:
        get_owned_row("flashcard_sets", set_id, user.id)
    q = (
        get_db()
        .table("flashcards")
        .select("*, card_reviews(*)")
        .eq("user_id", user.id)
    )
    if set_id:
        q = q.eq("set_id", set_id)
    # PostgREST varsayilan 1000 satir tavanini asabilmek icin acik limit
    rows = q.order("position").limit(5000).execute().data

    now = _now()
    fresh, due = [], []
    for card in rows:
        # PostgREST birebir iliskiyi (PK=FK) nesne olarak gomer, listeye degil
        raw = card.pop("card_reviews", None)
        review = (raw[0] if raw else None) if isinstance(raw, list) else raw
        card["review"] = review
        if mode == "cram":
            fresh.append(card)
        elif review is None:
            fresh.append(card)
        elif _parse_ts(review["due_at"]) <= now:
            due.append(card)
    due.sort(key=lambda c: c["review"]["due_at"])
    result = (fresh + due)[:limit]
    return {
        "cards": result,
        "total_due": len(fresh) + len(due),
        "new_count": 0 if mode == "cram" else len(fresh),
    }


@router.post("/reviews")
def submit_review(req: ReviewReq, user: AuthUser = Depends(get_current_user)):
    get_owned_row("flashcards", req.card_id, user.id)
    db = get_db()
    existing = (
        db.table("card_reviews")
        .select("*")
        .eq("card_id", req.card_id)
        .limit(1)
        .execute()
        .data
    )
    if existing:
        r = existing[0]
        state = ReviewState(
            ease_factor=r["ease_factor"],
            interval_days=r["interval_days"],
            repetitions=r["repetitions"],
            due_at=_parse_ts(r["due_at"]),
        )
    else:
        state = ReviewState()

    now = _now()
    new_state = apply_sm2(state, req.grade, now)
    row = {
        "card_id": req.card_id,
        "user_id": user.id,
        "ease_factor": new_state.ease_factor,
        "interval_days": new_state.interval_days,
        "repetitions": new_state.repetitions,
        "due_at": new_state.due_at.isoformat(),
        "last_grade": req.grade,
        "updated_at": now.isoformat(),
    }
    db.table("card_reviews").upsert(row, on_conflict="card_id").execute()
    # Gecmis/istatistik icin her cevabi olay olarak da kaydet (best-effort)
    try:
        db.table("review_events").insert(
            {"user_id": user.id, "card_id": req.card_id,
             "grade": req.grade, "reviewed_at": now.isoformat()}
        ).execute()
    except Exception:
        pass  # review_events tablosu yoksa stats yine card_reviews'tan calisir
    return row


@router.get("/history")
def study_history(
    days: int = Query(14, ge=1, le=366),
    tz_offset_minutes: int = Query(0, ge=-840, le=840,
                                   description="Istemci yerel saat farki (dk), orn. TR=180"),
    user: AuthUser = Depends(get_current_user),
):
    """Son N gunun gunluk calisma ozeti (ilerleme grafigi / isi haritasi).

    Gun siniri istemcinin yerel saatine gore cizilir (tz_offset_minutes);
    aksi halde TR'de 21:00 sonrasi cevaplar ertesi gune yazilirdi."""
    from collections import defaultdict
    from datetime import timedelta

    try:
        rows = (
            get_db()
            .table("review_events")
            .select("grade, reviewed_at")
            .eq("user_id", user.id)
            .order("reviewed_at", desc=True)
            .limit(5000)
            .execute()
            .data
        )
    except Exception:
        # review_events tablosu (migration_02) henuz uygulanmadiysa bos don.
        return {"days": [], "total_reviews": 0, "needs_migration": True}
    offset = timedelta(minutes=tz_offset_minutes)
    by_day = defaultdict(lambda: {"total": 0, "correct": 0})
    for r in rows:
        local_day = (_parse_ts(r["reviewed_at"]) + offset).date().isoformat()
        by_day[local_day]["total"] += 1
        # SM-2 ile tutarli basari tanimi: hard (1) de dogru sayilir (sm2.py:53)
        if r["grade"] >= 1:
            by_day[local_day]["correct"] += 1
    series = [
        {"date": d, "total": v["total"], "correct": v["correct"]}
        for d, v in sorted(by_day.items())
    ][-days:]
    # total_reviews pencereyle uyumlu (eski hali tum zamanlari sayiyordu)
    return {"days": series, "total_reviews": sum(d["total"] for d in series)}


@router.get("/stats")
def study_stats(user: AuthUser = Depends(get_current_user)):
    """Dashboard sayaclari."""
    db = get_db()

    def _count(table: str) -> int:
        return (
            db.table(table)
            .select("id", count="exact", head=True)
            .eq("user_id", user.id)
            .execute()
            .count
            or 0
        )

    reviews = (
        db.table("card_reviews")
        .select("due_at")
        .eq("user_id", user.id)
        .limit(5000)  # PostgREST varsayilan 1000 tavanini asabilmek icin
        .execute()
        .data
    )
    now = _now()
    due_reviewed = sum(1 for r in reviews if _parse_ts(r["due_at"]) <= now)
    total_cards = _count("flashcards")
    return {
        "documents": _count("documents"),
        "sets": _count("flashcard_sets"),
        "cards": total_cards,
        "quizzes": _count("quizzes"),
        "due_now": due_reviewed + (total_cards - len(reviews)),
        "studied_cards": len(reviews),
    }
