"""Latince terim sozlugu — DIP motorunun /api/terms ucundan beslenir.

Otomatik tamamlama (gorsel arama, kart duzenleme) icin kullanilir.
Sozluk nadir degisir, surec icinde bir kez onbelleklenir.
"""
from fastapi import APIRouter, Depends

from app import dip_client
from app.deps import AuthUser, get_current_user
from app.dip_client import DipError

router = APIRouter(prefix="/terms", tags=["terms"])

_cache: list = []


@router.get("")
def list_terms(user: AuthUser = Depends(get_current_user)):
    """{terms: [...]} — DIP sozlugu (~140 Latince anatomi terimi)."""
    global _cache
    if not _cache:
        try:
            _cache = dip_client.terms().get("terms", [])
        except DipError:
            _cache = []
    return {"terms": _cache}
