"""Bilgi karti desteleri (flashcard_sets) CRUD + kart listeleme/ekleme."""
from fastapi import APIRouter, Depends

from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.helpers import get_owned_row
from app.schemas import CardCreateReq, SetCreateReq, SetUpdateReq

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
