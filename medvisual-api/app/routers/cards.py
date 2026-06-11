"""Kart islemleri: import, gorsel aday eslestirme, gorsel secimi, duzenleme.

Gorsel akisi (ucretsizlik disiplini): adaylar DIP motorundan proxy ile gecici
gosterilir; yalnizca kullanicinin SECTIGI gorsel Supabase Storage'a yuklenir
ve flashcards.image_url kalici olur.
"""
from typing import Optional

from fastapi import APIRouter, Depends, Form, HTTPException, UploadFile

from app import dip_client
from app.config import settings
from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.dip_client import DipError
from app.helpers import get_owned_row, mark_document_expired, require_ready_document
from app.schemas import CardUpdateReq, MatchReq, SelectImageReq

router = APIRouter(prefix="/cards", tags=["cards"])


@router.post("/import", status_code=201)
def import_cards(
    file: UploadFile,
    set_title: Optional[str] = Form(None),
    user: AuthUser = Depends(get_current_user),
):
    """CSV/JSON/TSV/APKG/TXT kart dosyasini DIP motoruna parse ettirir,
    yeni bir set olarak DB'ye yazar (baska yerde olusturulmus kartlara
    gorsel ekleme senaryosunun ilk adimi)."""
    content = file.file.read()
    if not content:
        raise HTTPException(400, "Bos dosya gonderildi.")
    try:
        res = dip_client.import_cards(file.filename or "cards.csv", content)
    except DipError as exc:
        raise HTTPException(502 if exc.status == 0 else 400, str(exc))

    cards = res.get("cards", [])
    if not cards:
        raise HTTPException(400, "Dosyada kart bulunamadi.")

    db = get_db()
    set_row = (
        db.table("flashcard_sets")
        .insert(
            {
                "user_id": user.id,
                "title": set_title or f"Iceri aktarilan: {file.filename}",
                "description": f"{len(cards)} kart iceri aktarildi",
                "status": "ready",
            }
        )
        .execute()
        .data[0]
    )
    rows = [
        {
            "set_id": set_row["id"],
            "user_id": user.id,
            "front": c.get("front", ""),
            "back": c.get("back", ""),
            "term": c.get("term"),
            "kind": c.get("kind", "imported"),
            "position": i,
        }
        for i, c in enumerate(cards)
    ]
    db.table("flashcards").insert(rows).execute()
    set_row["card_count"] = len(rows)
    return set_row


def _resolve_document_for_card(card: dict, req: MatchReq, user_id: str) -> dict:
    """Eslestirme yapilacak dokumani bul: istekte verilen ya da setin dokumani."""
    if req.document_id:
        return get_owned_row("documents", req.document_id, user_id)
    set_row = get_owned_row("flashcard_sets", card["set_id"], user_id)
    if not set_row.get("document_id"):
        raise HTTPException(
            400,
            "Bu set bir dokumana bagli degil; istekte document_id belirtin "
            "(orn. iceri aktarilan kartlar icin kaynak PDF).",
        )
    return get_owned_row("documents", set_row["document_id"], user_id)


@router.post("/{card_id}/match")
def match_card(
    card_id: str, req: MatchReq, user: AuthUser = Depends(get_current_user)
):
    """DIP motorunda sayfa araligini tarayip karta uygun gorsel adaylarini doner.
    Aday URL'leri bu API'nin /dip-images proxy'sine yeniden yazilir."""
    card = get_owned_row("flashcards", card_id, user.id)
    doc = _resolve_document_for_card(card, req, user.id)
    dip_doc_id = require_ready_document(doc)
    try:
        res = dip_client.match_card(
            dip_doc_id,
            req.range,
            front=card.get("front", ""),
            back=card.get("back", ""),
            term=req.term or card.get("term") or "",
            source=req.source,
        )
    except DipError as exc:
        if exc.status == 404:
            mark_document_expired(doc["id"])
            raise HTTPException(
                409, "Dokuman DIP motorunda artik yok; lutfen yeniden yukleyin."
            )
        raise HTTPException(502 if exc.status == 0 else 400, str(exc))

    prefix = f"/work/{dip_doc_id}/"
    candidates = []
    for c in res.get("candidates", []):
        url = c.get("url", "")
        subpath = url.split(prefix, 1)[1] if prefix in url else url.lstrip("/")
        candidates.append(
            {
                "label": c.get("label"),
                "page": c.get("page"),
                "distance": c.get("distance"),
                "dip_doc_id": dip_doc_id,
                "path": subpath,
                "url": f"/dip-images/{dip_doc_id}/{subpath}",
            }
        )
    return {
        "card_id": card_id,
        "term": res.get("term"),
        "matched": res.get("matched"),
        "similarity": res.get("similarity"),
        "best_page": res.get("best_page"),
        "truncated": res.get("truncated"),
        "candidates": candidates,
    }


@router.post("/{card_id}/select-image")
def select_image(
    card_id: str, req: SelectImageReq, user: AuthUser = Depends(get_current_user)
):
    """Secilen aday gorseli DIP'ten indirir, Supabase Storage'a yukler ve
    kartin kalici image_url alanini gunceller."""
    card = get_owned_row("flashcards", card_id, user.id)
    # Sahiplik: dip_doc_id kullanicinin bir dokumanina ait olmali
    owned = (
        get_db()
        .table("documents")
        .select("id")
        .eq("user_id", user.id)
        .eq("dip_doc_id", req.dip_doc_id)
        .limit(1)
        .execute()
        .data
    )
    if not owned:
        raise HTTPException(404, "Dokuman bulunamadi.")
    if ".." in req.path or req.path.startswith("/"):
        raise HTTPException(400, "Gecersiz dosya yolu.")

    try:
        content, _ = dip_client.fetch_work_file(req.dip_doc_id, req.path)
    except DipError as exc:
        raise HTTPException(502 if exc.status == 0 else 404, str(exc))

    storage_path = f"{user.id}/{card_id}.png"
    storage = get_db().storage.from_(settings.STORAGE_BUCKET)
    storage.upload(
        storage_path,
        content,
        file_options={"content-type": "image/png", "upsert": "true"},
    )
    public_url = storage.get_public_url(storage_path)
    updated = (
        get_db()
        .table("flashcards")
        .update({"image_url": public_url})
        .eq("id", card["id"])
        .execute()
        .data[0]
    )
    return updated


@router.post("/{card_id}/upload-image")
def upload_image(
    card_id: str,
    file: UploadFile,
    user: AuthUser = Depends(get_current_user),
):
    """Istemcide kirpilmis (veya ozel) gorseli dogrudan Storage'a yukler ve
    kartin kalici image_url alanini gunceller (PRD: 'secip kirparak onaylar')."""
    card = get_owned_row("flashcards", card_id, user.id)
    content = file.file.read()
    if not content:
        raise HTTPException(400, "Bos dosya gonderildi.")
    if len(content) > 8 * 1024 * 1024:
        raise HTTPException(413, "Gorsel 8MB'tan kucuk olmali.")

    storage_path = f"{user.id}/{card_id}.png"
    storage = get_db().storage.from_(settings.STORAGE_BUCKET)
    storage.upload(
        storage_path,
        content,
        file_options={"content-type": file.content_type or "image/png", "upsert": "true"},
    )
    public_url = storage.get_public_url(storage_path)
    return (
        get_db()
        .table("flashcards")
        .update({"image_url": public_url})
        .eq("id", card["id"])
        .execute()
        .data[0]
    )


@router.delete("/{card_id}/image")
def remove_image(card_id: str, user: AuthUser = Depends(get_current_user)):
    """Karttaki gorseli kaldirir: image_url=null + Storage dosyasini siler.
    (Degistirme icin ayri uc gerekmez: select-image/upload-image ayni yola
    upsert eder, eski gorselin uzerine yazar.)"""
    card = get_owned_row("flashcards", card_id, user.id)
    try:
        get_db().storage.from_(settings.STORAGE_BUCKET).remove(
            [f"{user.id}/{card_id}.png"]
        )
    except Exception:
        pass  # dosya yoksa veya disaridan URL ise sorun degil
    return (
        get_db()
        .table("flashcards")
        .update({"image_url": None})
        .eq("id", card["id"])
        .execute()
        .data[0]
    )


@router.patch("/{card_id}")
def update_card(
    card_id: str, req: CardUpdateReq, user: AuthUser = Depends(get_current_user)
):
    get_owned_row("flashcards", card_id, user.id)
    # exclude_unset: gonderilen null "alani temizle" demektir (orn. term: null);
    # gonderilmeyen alanlar ise hic dokunulmaz.
    fields = req.model_dump(exclude_unset=True)
    for required in ("front", "back"):  # DB'de NOT NULL — null'a cekilemez
        if fields.get(required) is None:
            fields.pop(required, None)
    if not fields:
        return get_owned_row("flashcards", card_id, user.id)
    return (
        get_db()
        .table("flashcards")
        .update(fields)
        .eq("id", card_id)
        .execute()
        .data[0]
    )


@router.delete("/{card_id}", status_code=204)
def delete_card(card_id: str, user: AuthUser = Depends(get_current_user)):
    get_owned_row("flashcards", card_id, user.id)
    get_db().table("flashcards").delete().eq("id", card_id).execute()
