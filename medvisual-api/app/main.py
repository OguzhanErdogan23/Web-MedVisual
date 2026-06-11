"""MedVisual Merkezi RESTful API (Web Programlama dersi backend'i).

Istemciler: medvisual-web (React) ve medvisual-mobile (Flutter).
Veri katmani: Supabase (PostgreSQL + Auth + Storage) — Single Source of Truth.
Goruntu isleme: medvisual-dip Flask motoru (:5000), ic mikroservis.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app import dip_client
from app.config import settings
from app.routers import (
    books,
    cards,
    documents,
    profile,
    proxy,
    quizzes,
    sets,
    study,
    terms,
)

app = FastAPI(
    title="MedVisual API",
    description="Tibbi dokumanlardan gorsel destekli bilgi karti ureten "
    "ekosistemin merkezi RESTful API'si.",
    version="1.0.0",
)

# Kimlik dogrulama cookie degil Bearer token ile yapildigi icin genis CORS
# guvenlik riski olusturmaz (ders projesi, lokal ag).
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    # Export dosya adinin (filename*=UTF-8'') JS tarafindan okunabilmesi icin
    expose_headers=["Content-Disposition"],
)

app.include_router(documents.router)
app.include_router(books.router)
app.include_router(sets.router)
app.include_router(cards.router)
app.include_router(quizzes.router)
app.include_router(study.router)
app.include_router(terms.router)
app.include_router(profile.router)
app.include_router(proxy.router)


@app.get("/health", tags=["health"])
def health():
    """API + DIP motoru + Supabase yapilandirma durumu."""
    dip_status = "ok"
    dip_detail = None
    try:
        info = dip_client.health()
        if not info.get("tesseract"):
            dip_status = "degraded"
            dip_detail = "tesseract bulunamadi"
    except Exception as exc:
        dip_status = "down"
        dip_detail = str(exc)

    supabase_configured = bool(
        settings.SUPABASE_URL and settings.SUPABASE_SERVICE_ROLE_KEY
    )
    return {
        "api": "ok",
        "dip_engine": {"status": dip_status, "detail": dip_detail},
        "supabase_configured": supabase_configured,
        "auth_mode": "hs256" if settings.SUPABASE_JWT_SECRET else "jwks",
    }
