"""Router'larin ortak yardimcilari."""
from fastapi import HTTPException

from app.db import get_db


def get_owned_row(table: str, row_id: str, user_id: str) -> dict:
    """Satiri getirir; yoksa 404, baskasininsa da 404 (bilgi sizdirmamak icin)."""
    res = (
        get_db()
        .table(table)
        .select("*")
        .eq("id", row_id)
        .eq("user_id", user_id)
        .limit(1)
        .execute()
    )
    if not res.data:
        raise HTTPException(404, f"Kayit bulunamadi: {table}/{row_id}")
    return res.data[0]


def require_ready_document(document: dict) -> str:
    """Dokumanin DIP motorunda kullanilabilir oldugunu dogrular, dip_doc_id doner."""
    if document["status"] == "processing":
        raise HTTPException(409, "Dokuman hala isleniyor, lutfen bekleyin.")
    if document["status"] != "ready" or not document.get("dip_doc_id"):
        raise HTTPException(
            409,
            "Dokuman kullanilabilir degil (durum: %s). Yeniden yuklemeniz gerekebilir."
            % document["status"],
        )
    return document["dip_doc_id"]


def mark_document_expired(document_id: str) -> None:
    """DIP work/ dosyasi silinmisse dokumani 'expired' isaretle (plan: yeniden yukleme akisi)."""
    get_db().table("documents").update(
        {"status": "expired", "error": "DIP motorundaki dosya artik mevcut degil."}
    ).eq("id", document_id).execute()
