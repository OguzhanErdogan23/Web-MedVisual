"""Bilgi karti desteleri (flashcard_sets) CRUD + kart listeleme/ekleme."""
import urllib.parse

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, Response

from app import dip_client, exporters
from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.dip_client import DipError
from app.helpers import get_owned_row, mark_document_expired, require_ready_document
from app.schemas import AutoImagesReq, CardCreateReq, SetCreateReq, SetUpdateReq

router = APIRouter(prefix="/sets", tags=["sets"])


@router.get("")
def list_sets(user: AuthUser = Depends(get_current_user)):
    res = (
        get_db()
        .table("flashcard_sets")
        .select("*, flashcards(count)")
        .eq("user_id", user.id)
        .order("created_at", desc=True)
        .execute()
    )
    sets = []
    for s in res.data:
        counts = s.pop("flashcards", [])
        s["card_count"] = counts[0]["count"] if counts else 0
        sets.append(s)
    return {"sets": sets}


@router.post("", status_code=201)
def create_set(req: SetCreateReq, user: AuthUser = Depends(get_current_user)):
    return (
        get_db()
        .table("flashcard_sets")
        .insert(
            {
                "user_id": user.id,
                "title": req.title,
                "description": req.description,
                "status": "ready",
            }
        )
        .execute()
        .data[0]
    )


@router.get("/{set_id}")
def get_set(set_id: str, user: AuthUser = Depends(get_current_user)):
    """Set + kartlari (istemci 'generating' durumunu burada poll'lar)."""
    set_row = get_owned_row("flashcard_sets", set_id, user.id)
    cards = (
        get_db()
        .table("flashcards")
        .select("*")
        .eq("set_id", set_id)
        .order("position")
        .execute()
        .data
    )
    set_row["cards"] = cards
    return set_row


@router.patch("/{set_id}")
def update_set(
    set_id: str, req: SetUpdateReq, user: AuthUser = Depends(get_current_user)
):
    get_owned_row("flashcard_sets", set_id, user.id)
    fields = {k: v for k, v in req.model_dump().items() if v is not None}
    if not fields:
        return get_owned_row("flashcard_sets", set_id, user.id)
    return (
        get_db()
        .table("flashcard_sets")
        .update(fields)
        .eq("id", set_id)
        .execute()
        .data[0]
    )


@router.delete("/{set_id}", status_code=204)
def delete_set(set_id: str, user: AuthUser = Depends(get_current_user)):
    get_owned_row("flashcard_sets", set_id, user.id)
    get_db().table("flashcard_sets").delete().eq("id", set_id).execute()


@router.get("/{set_id}/export")
def export_set(
    set_id: str,
    format: str = Query("json", description="json|csv|tsv|anki|txt|pdf|apkg"),
    user: AuthUser = Depends(get_current_user),
):
    """Desteyi secilen formatta indirir. Gorselli kartlar PDF/APKG'ye gomulur."""
    fmt = format.lower()
    if fmt not in exporters.CARD_FORMATS:
        raise HTTPException(400, f"Desteklenmeyen format: {format}")
    set_row = get_owned_row("flashcard_sets", set_id, user.id)
    cards = (
        get_db()
        .table("flashcards")
        .select("*")
        .eq("set_id", set_id)
        .order("position")
        .execute()
        .data
    )
    if not cards:
        raise HTTPException(404, "Bu destede kart yok.")
    fn = exporters.CARD_FORMATS[fmt]
    # PDF/APKG baslik parametresi alir
    if fmt in ("pdf", "apkg"):
        data, mime, ext = fn(cards, set_row["title"])
    else:
        data, mime, ext = fn(cards)
    safe = urllib.parse.quote(set_row["title"][:60])
    return Response(
        content=data,
        media_type=mime,
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{safe}.{ext}"},
    )


def _auto_images_job(set_id: str, user_id: str, dip_doc_id: str, page_count: int,
                     page_range: str) -> None:
    db = get_db()
    cards = (
        db.table("flashcards")
        .select("*")
        .eq("set_id", set_id)
        .is_("image_url", "null")
        .order("position")
        .execute()
        .data
    )
    added = 0
    for c in cards:
        page = c.get("page")
        if page:
            rng = f"{max(1, page - 4)}-{min(page_count, page + 4)}"
        else:
            rng = page_range
        try:
            res = dip_client.match_card(
                dip_doc_id, rng, front=c.get("front", ""),
                back=c.get("back", ""), term=c.get("term") or "",
            )
        except DipError:
            continue
        cands = res.get("candidates") or []
        if not cands:
            continue
        url = cands[0].get("url", "")
        prefix = f"/work/{dip_doc_id}/"
        subpath = url.split(prefix, 1)[1] if prefix in url else url.lstrip("/")
        try:
            content, _ = dip_client.fetch_work_file(dip_doc_id, subpath)
        except DipError:
            continue
        storage_path = f"{user_id}/{c['id']}.png"
        storage = db.storage.from_("card-images")
        storage.upload(storage_path, content,
                       file_options={"content-type": "image/png", "upsert": "true"})
        public_url = storage.get_public_url(storage_path)
        db.table("flashcards").update({"image_url": public_url}).eq("id", c["id"]).execute()
        added += 1
    db.table("flashcard_sets").update(
        {"status": "ready", "description": f"{added} karta otomatik gorsel eklendi"}
    ).eq("id", set_id).execute()


@router.post("/{set_id}/auto-images", status_code=202)
def auto_images(
    set_id: str,
    req: AutoImagesReq,
    background_tasks: BackgroundTasks,
    user: AuthUser = Depends(get_current_user),
):
    """Destedeki gorseli olmayan TUM kartlara otomatik figur ekler (arka plan).
    Istemci set 'generating' -> 'ready' gecisini poll'lar."""
    set_row = get_owned_row("flashcard_sets", set_id, user.id)
    doc_id = req.document_id or set_row.get("document_id")
    if not doc_id:
        raise HTTPException(400, "Bu set bir dokumana bagli degil; document_id verin.")
    doc = get_owned_row("documents", doc_id, user.id)
    dip_doc_id = require_ready_document(doc)
    page_range = req.range or f"1-{doc['page_count']}"
    get_db().table("flashcard_sets").update({"status": "generating"}).eq(
        "id", set_id
    ).execute()
    background_tasks.add_task(
        _auto_images_job, set_id, user.id, dip_doc_id, doc["page_count"], page_range
    )
    return {"status": "generating", "set_id": set_id}


@router.post("/{set_id}/cards", status_code=201)
def add_card(
    set_id: str, req: CardCreateReq, user: AuthUser = Depends(get_current_user)
):
    get_owned_row("flashcard_sets", set_id, user.id)
    db = get_db()
    count = (
        db.table("flashcards")
        .select("id", count="exact")
        .eq("set_id", set_id)
        .execute()
        .count
        or 0
    )
    return (
        db.table("flashcards")
        .insert(
            {
                "set_id": set_id,
                "user_id": user.id,
                "front": req.front,
                "back": req.back,
                "term": req.term,
                "kind": req.kind,
                "page": req.page,
                "position": count,
            }
        )
        .execute()
        .data[0]
    )
