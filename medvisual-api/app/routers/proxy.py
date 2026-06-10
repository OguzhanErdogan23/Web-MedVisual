"""DIP work/ gorsellerinin kimlik dogrulamali proxy'si.

<img src> etiketleri Authorization basligi gonderemedigi icin token ayrica
?token=<jwt> query parametresiyle de kabul edilir (web/mobil istemciler
gorsel URL'lerine access token ekler).
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app import dip_client
from app.db import get_db
from app.deps import AuthUser, _decode
from app.dip_client import DipError

router = APIRouter(tags=["proxy"])
_bearer = HTTPBearer(auto_error=False)


def _user_from_header_or_query(
    cred: Optional[HTTPAuthorizationCredentials] = Depends(_bearer),
    token: Optional[str] = Query(None),
) -> AuthUser:
    raw = cred.credentials if cred else token
    if not raw:
        raise HTTPException(401, "Token gerekli (Authorization basligi veya ?token=).")
    try:
        payload = _decode(raw)
    except Exception as exc:
        raise HTTPException(401, f"Gecersiz token: {exc}")
    return AuthUser(id=payload["sub"], email=payload.get("email"))


@router.get("/dip-images/{dip_doc_id}/{subpath:path}")
def dip_image(
    dip_doc_id: str,
    subpath: str,
    user: AuthUser = Depends(_user_from_header_or_query),
):
    if ".." in subpath:
        raise HTTPException(400, "Gecersiz yol.")
    owned = (
        get_db()
        .table("documents")
        .select("id")
        .eq("user_id", user.id)
        .eq("dip_doc_id", dip_doc_id)
        .limit(1)
        .execute()
        .data
    )
    if not owned:
        raise HTTPException(404, "Dokuman bulunamadi.")
    try:
        content, content_type = dip_client.fetch_work_file(dip_doc_id, subpath)
    except DipError as exc:
        raise HTTPException(502 if exc.status == 0 else 404, str(exc))
    return Response(content=content, media_type=content_type or "image/png")
