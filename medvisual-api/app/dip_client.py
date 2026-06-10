"""DIP motoru (Flask, :5000) HTTP sarmalayicisi.

DIP motoru ayri ders teslimi oldugu icin koduna dokunulmaz; bu modul onu
ic mikroservis olarak cagirir. Uzun sure calisan uclar (kart/quiz uretimi,
gorsel tarama) icin genis timeout kullanilir.
"""
from typing import Optional, Tuple

import httpx

from app.config import settings


class DipError(Exception):
    """DIP motoru hata yaniti veya erisim sorunu."""

    def __init__(self, message: str, status: int = 0):
        super().__init__(message)
        self.status = status  # 0 = baglanti hatasi (HTTP yaniti yok)


# Taranmis (OCR gerektiren) kitaplarda genis sayfa araliklari dakikalar
# surebilir; okuma timeout'u bu yuzden cok genis tutulur. Istemciler zaten
# polling yapar, bu istekler arka plan gorevlerinde calisir.
_client = httpx.Client(
    base_url=settings.DIP_ENGINE_URL,
    timeout=httpx.Timeout(connect=10.0, read=1800.0, write=120.0, pool=30.0),
)


def _check(resp: httpx.Response) -> dict:
    try:
        data = resp.json()
    except ValueError:
        raise DipError(
            f"DIP motoru beklenmedik yanit dondu (HTTP {resp.status_code}).",
            status=resp.status_code,
        )
    if resp.status_code >= 400:
        raise DipError(
            data.get("error", f"DIP hatasi (HTTP {resp.status_code})."),
            status=resp.status_code,
        )
    return data


def _post(path: str, **kwargs) -> dict:
    try:
        return _check(_client.post(path, **kwargs))
    except httpx.HTTPError as exc:
        raise DipError(f"DIP motoruna ulasilamadi ({settings.DIP_ENGINE_URL}): {exc}")


def _get(path: str, **kwargs) -> dict:
    try:
        return _check(_client.get(path, **kwargs))
    except httpx.HTTPError as exc:
        raise DipError(f"DIP motoruna ulasilamadi ({settings.DIP_ENGINE_URL}): {exc}")


def health() -> dict:
    return _get("/api/health")


def upload_pdf(filename: str, content: bytes) -> dict:
    """-> {doc_id, filename, page_count, has_text}"""
    return _post(
        "/api/upload",
        files={"file": (filename, content, "application/pdf")},
    )


def list_books() -> dict:
    return _get("/api/books")


def load_book(name: str) -> dict:
    """-> upload ile ayni sema: {doc_id, filename, page_count, has_text}"""
    return _post("/api/books/load", json={"name": name})


def generate_cards(
    doc_id: str, page_range: str, source: str, max_cards: int, enhance: bool
) -> dict:
    """-> {cards:[{front,back,term,kind,page,source}], pages, llm_enhanced, ...}"""
    return _post(
        "/api/generate/cards",
        json={
            "doc_id": doc_id,
            "range": page_range,
            "source": source,
            "max_cards": max_cards,
            "enhance": enhance,
        },
    )


def generate_quiz(
    doc_id: str, page_range: str, source: str, n_questions: int, enhance: bool
) -> dict:
    """-> {questions:[{question,options,answer_index}], llm_enhanced, ...}"""
    return _post(
        "/api/generate/quiz",
        json={
            "doc_id": doc_id,
            "range": page_range,
            "source": source,
            "n": n_questions,
            "enhance": enhance,
        },
    )


def import_cards(filename: str, content: bytes) -> dict:
    """-> {count, cards:[{front,back,...}]}"""
    return _post("/api/cards/import", files={"file": (filename, content)})


def match_card(
    doc_id: str,
    page_range: str,
    front: str = "",
    back: str = "",
    term: str = "",
    source: str = "auto",
) -> dict:
    """-> {candidates:[{label,distance,page,url}], term, matched, best_page, ...}"""
    return _post(
        "/api/cards/match",
        json={
            "doc_id": doc_id,
            "range": page_range,
            "front": front,
            "back": back,
            "term": term,
            "source": source,
        },
    )


def fetch_work_file(dip_doc_id: str, subpath: str) -> Tuple[bytes, Optional[str]]:
    """work/ altindaki bir gorseli (aday/sayfa PNG) byte olarak getirir."""
    try:
        resp = _client.get(f"/work/{dip_doc_id}/{subpath}")
    except httpx.HTTPError as exc:
        raise DipError(f"DIP motoruna ulasilamadi: {exc}")
    if resp.status_code >= 400:
        raise DipError(
            f"Gorsel bulunamadi (HTTP {resp.status_code}).", status=resp.status_code
        )
    return resp.content, resp.headers.get("content-type")
