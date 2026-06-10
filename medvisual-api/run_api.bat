@echo off
rem MedVisual API baslatici — once medvisual-dip motorunu (:5000) baslatin.
cd /d "%~dp0"

if not exist .venv (
  echo [kurulum] Sanal ortam olusturuluyor...
  py -m venv .venv || python -m venv .venv
  call .venv\Scripts\activate.bat
  pip install -r requirements.txt
) else (
  call .venv\Scripts\activate.bat
)

if not exist .env (
  echo [UYARI] .env dosyasi yok! .env.example dosyasini .env olarak kopyalayip
  echo         Supabase anahtarlarinizi girin.
  pause
  exit /b 1
)

echo MedVisual API: http://0.0.0.0:8000  (Swagger: http://localhost:8000/docs)
uvicorn app.main:app --host 0.0.0.0 --port 8000
