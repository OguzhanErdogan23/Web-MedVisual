"""DIP motorunun hazir kitap kutuphanesi (books/ klasoru) proxy'si."""
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException

from app import dip_client
from app.db import get_db
from app.deps import AuthUser, get_current_user
from app.dip_client import DipError
from app.schemas import LoadBookReq

router = APIRouter(prefix="/books", tags=["books"])


@router.get("")
def list_books(user: AuthUser = Depends(get_current_user)):
    try:
        return dip_client.list_books()
    except DipError as exc:
        raise HTTPException(502, str(exc))


def _load_book_job(document_id: str, name: str) -> None:
    db = get_db()
    try:
        info = dip_client.load_book(name)
        db.table("documents").update(
            {
                "dip_doc_id": info["doc_id"],
                "page_count": info["page_count"],
                "has_text": info["has_text"],
                "status": "ready",
                "error": None,
            }
        ).eq("id", document_id).execute()
    except Exception as exc:
        db.table("documents").update(
            {"status": "failed", "error": str(exc)}
        ).eq("id", document_id).execute()


@router.post("/load", status_code=202)
def load_book(
    req: LoadBookReq,
    background_tasks: BackgroundTasks,
    user: AuthUser = Depends(get_current_user),
):
    row = (
        get_db()
        .table("documents")
        .insert({"user_id": user.id, "filename": req.name, "status": "processing"})
        .execute()
        .data[0]
    )
    background_tasks.add_task(_load_book_job, row["id"], req.name)
    return row
