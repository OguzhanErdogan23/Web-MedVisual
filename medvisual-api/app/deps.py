"""Kimlik dogrulama bagimliligi — Supabase JWT dogrulamasi.

Istemciler (web/mobil) Supabase Auth ile giris yapar ve access token'i
Authorization: Bearer <token> olarak gonderir. Iki dogrulama yolu desteklenir:
- SUPABASE_JWT_SECRET tanimliysa: legacy HS256 paylasimli sir.
- Tanimli degilse: projenin JWKS ucundan asimetrik anahtar (ES256/RS256).
"""
from dataclasses import dataclass
from typing import Optional

import jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jwt import PyJWKClient

from app.config import settings

_bearer = HTTPBearer(auto_error=False)
_jwks_client: Optional[PyJWKClient] = None


@dataclass(frozen=True)
class AuthUser:
    id: str
    email: Optional[str]


# Supabase sunucusu ile lokal makine arasindaki saat kaymasi toleransi (sn)
_CLOCK_LEEWAY = 90


def _decode(token: str) -> dict:
    if settings.SUPABASE_JWT_SECRET:
        return jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated",
            leeway=_CLOCK_LEEWAY,
        )
    global _jwks_client
    if _jwks_client is None:
        _jwks_client = PyJWKClient(
            f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json"
        )
    key = _jwks_client.get_signing_key_from_jwt(token).key
    return jwt.decode(
        token,
        key,
        algorithms=["ES256", "RS256"],
        audience="authenticated",
        leeway=_CLOCK_LEEWAY,
    )


def get_current_user(
    cred: Optional[HTTPAuthorizationCredentials] = Depends(_bearer),
) -> AuthUser:
    if cred is None:
        raise HTTPException(401, "Authorization: Bearer <token> basligi gerekli.")
    try:
        payload = _decode(cred.credentials)
    except jwt.PyJWTError as exc:
        raise HTTPException(401, f"Gecersiz veya suresi dolmus token: {exc}")
    return AuthUser(id=payload["sub"], email=payload.get("email"))
