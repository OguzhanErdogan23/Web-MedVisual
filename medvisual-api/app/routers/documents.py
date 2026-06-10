"""Dokuman yasam dongusu: upload -> DIP isleme -> ready; kart/quiz uretimi.

Ucretsizlik disiplini: PDF Supabase'e yuklenmez, DIP motorunun lokal work/
dizininde kalir; DB'de yalnizca metadata + dip_doc_id tutulur. Uzun isler
BackgroundTasks ile calisir, istemci status alanini poll'lar.
"""
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, UploadFile

from app import dip_client
from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.dip_client import DipError
from app.helpers import get_owned_row, require_ready_document
from app.schemas import GenerateCardsReq, GenerateQuizReq

router = APIRouter(prefix="/documents", tags=["documents"])


# --------------------------------------------------------------------------- #
# Arka plan isleri
# --------------------------------------------------------------------------- #
def _process_upload(document_id: str, filename: str, content: bytes) -> None:
    db = get_db()
    try:
        info = dip_client.upload_pdf(filename, content)
        db.table("documents").update(
            {
                "dip_doc_id": info["doc_id"],
                "page_count": info["page_count"],
                "has_text": info["has_text"],
                "status": "ready",
                "error": None,
            }
        ).eq("id", document_id).execute()
    except Exception as exc:  # DipError dahil — durum DB'ye yazilir
        db.table("documents").update(
            {"status": "failed", "error": str(exc)}
        ).eq("id", document_id).execute()


def _generate_cards_job(
    set_id: str, user_id: str, dip_doc_id: str, req: GenerateCardsReq
) -> None:
    db = get_db()
    try:
        res = dip_client.generate_cards(
            dip_doc_id, req.range, req.source, req.max_cards, req.enhance
        )
        cards = res.get("cards", [])
        if not cards:
            raise DipError(res.get("reason") or "Bu aralikta kart uretilemedi.")
        rows = [
            {
                "set_id": set_id,
                "user_id": user_id,
                "front": c.get("front", ""),
                "back": c.get("back", ""),
                "term": c.get("term"),
                "kind": c.get("kind"),
                "page": c.get("page"),
                "position": i,
            }
            for i, c in enumerate(cards)
        ]
        db.table("flashcards").insert(rows).execute()
        gemini = "Gemini" if res.get("llm_enhanced") else "offline"
        db.table("flashcard_sets").update(
            {
                "status": "ready",
                "error": None,
                "description": f"Sayfa {req.range} | {len(cards)} kart | uretim: {gemini}",
            }
        ).eq("id", set_id).execute()
    except Exception as exc:
        db.table("flashcard_sets").update(
            {"status": "failed", "error": str(exc)}
        ).eq("id", set_id).execute()


def _generate_quiz_job(
    quiz_id: str, dip_doc_id: str, req: GenerateQuizReq
) -> None:
    db = get_db()
    try:
        res = dip_client.generate_quiz(
            dip_doc_id, req.range, req.source, req.n_questions, req.enhance
        )
        questions = res.get("questions", [])
        if not questions:
            raise DipError(
                res.get("warning") or "Bu aralikta quiz sorusu uretilemedi."
            )
        rows = [
            {
                "quiz_id": quiz_id,
                "question": q.get("question", ""),
                "options": q.get("options", []),
                "answer_index": q.get("answer_index", 0),
                "position": i,
            }
            for i, q in enumerate(questions)
        ]
        db.table("quiz_questions").insert(rows).execute()
        db.table("quizzes").update({"status": "ready", "error": None}).eq(
            "id", quiz_id
        ).execute()
    except Exception as exc:
        db.table("quizzes").update({"status": "failed", "error": str(exc)}).eq(
            "id", quiz_id
        ).execute()


# --------------------------------------------------------------------------- #
# Uclar
# --------------------------------------------------------------------------- #
@router.post("", status_code=202)
def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile,
    user: AuthUser = Depends(get_current_user),
):
    if not (file.filename or "").lower().endswith(".pdf"):
        raise HTTPException(400, "Yalnizca PDF dosyalari desteklenir.")
    content = file.file.read()
    if not content:
        raise HTTPException(400, "Bos dosya gonderildi.")
    row = (
        get_db()
        .table("documents")
        .insert(
            {"user_id": user.id, "filename": file.filename, "status": "processing"}
        )
        .execute()
        .data[0]
    )
    background_tasks.add_task(_process_upload, row["id"], file.filename, content)
    return row


@router.get("")
def list_documents(user: AuthUser = Depends(get_current_user)):
    res = (
        get_db()
        .table("documents")
        .select("*")
        .eq("user_id", user.id)
        .order("created_at", desc=True)
        .execute()
    )
    return {"documents": res.data}


@router.get("/{document_id}")
def get_document(document_id: str, user: AuthUser = Depends(get_current_user)):
    return get_owned_row("documents", document_id, user.id)


@router.delete("/{document_id}", status_code=204)
def delete_document(document_id: str, user: AuthUser = Depends(get_current_user)):
    get_owned_row("documents", document_id, user.id)
    get_db().table("documents").delete().eq("id", document_id).execute()


@router.post("/{document_id}/generate/cards", status_code=202)
def generate_cards(
    document_id: str,
    req: GenerateCardsReq,
    background_tasks: BackgroundTasks,
    user: AuthUser = Depends(get_current_user),
):
    doc = get_owned_row("documents", document_id, user.id)
    dip_doc_id = require_ready_document(doc)
    title = req.set_title or f"{doc['filename']} (s. {req.range})"
    set_row = (
        get_db()
        .table("flashcard_sets")
        .insert(
            {
                "user_id": user.id,
                "document_id": document_id,
                "title": title,
                "status": "generating",
            }
        )
        .execute()
        .data[0]
    )
    background_tasks.add_task(
        _generate_cards_job, set_row["id"], user.id, dip_doc_id, req
    )
    return set_row


@router.post("/{document_id}/generate/quiz", status_code=202)
def generate_quiz(
    document_id: str,
    req: GenerateQuizReq,
    background_tasks: BackgroundTasks,
    user: AuthUser = Depends(get_current_user),
):
    doc = get_owned_row("documents", document_id, user.id)
    dip_doc_id = require_ready_document(doc)
    title = req.title or f"{doc['filename']} quiz (s. {req.range})"
    quiz_row = (
        get_db()
        .table("quizzes")
        .insert(
            {
                "user_id": user.id,
                "document_id": document_id,
                "title": title,
                "status": "generating",
            }
        )
        .execute()
        .data[0]
    )
    background_tasks.add_task(_generate_quiz_job, quiz_row["id"], dip_doc_id, req)
    return quiz_row
