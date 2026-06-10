"""Ortam degiskenleri — .env dosyasindan yuklenir."""
import os

from dotenv import load_dotenv

load_dotenv()


class Settings:
    SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "")
    # service_role (legacy) veya sb_secret_... (yeni) anahtar — RLS'i bypass eder,
    # sahiplik kontrolu API katmaninda user_id filtresiyle yapilir.
    SUPABASE_SERVICE_ROLE_KEY: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
    # Legacy projelerde HS256 dogrulama icin; bos birakilirsa JWKS kullanilir.
    SUPABASE_JWT_SECRET: str = os.environ.get("SUPABASE_JWT_SECRET", "")
    DIP_ENGINE_URL: str = os.environ.get("DIP_ENGINE_URL", "http://localhost:5000")
    STORAGE_BUCKET: str = os.environ.get("STORAGE_BUCKET", "card-images")


settings = Settings()
