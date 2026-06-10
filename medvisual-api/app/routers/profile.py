"""Kullanici profili — goruntulenen ad (Ayarlar ekrani icin).

E-posta auth.users'tan (JWT) gelir; display_name profiles tablosunda tutulur.
Sifre degisikligi istemcide Supabase Auth ile yapilir (supabase.auth.updateUser).
"""
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.db import get_db
from app.deps import AuthUser, get_current_user

router = APIRouter(prefix="/profile", tags=["profile"])


class ProfileUpdateReq(BaseModel):
    display_name: str


@router.get("")
def get_profile(user: AuthUser = Depends(get_current_user)):
    res = (
        get_db()
        .table("profiles")
        .select("id, display_name, created_at")
        .eq("id", user.id)
        .limit(1)
        .execute()
        .data
    )
    profile = res[0] if res else {"id": user.id, "display_name": None}
    profile["email"] = user.email
    return profile


@router.patch("")
def update_profile(
    req: ProfileUpdateReq, user: AuthUser = Depends(get_current_user)
):
    """Goruntulenen adi gunceller. Profil satiri yoksa olusturur (upsert)."""
    name = req.display_name.strip()[:80]
    get_db().table("profiles").upsert(
        {"id": user.id, "display_name": name}, on_conflict="id"
    ).execute()
    return {"id": user.id, "display_name": name, "email": user.email}
