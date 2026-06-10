@echo off
rem MedVisual Web baslatici — once API'nin (:8000) calistigindan emin olun.
cd /d "%~dp0"

if not exist node_modules (
  echo [kurulum] Bagimliliklar yukleniyor...
  call npm install
)

if not exist .env (
  echo [UYARI] .env yok! .env.example dosyasini .env olarak kopyalayin.
  pause
  exit /b 1
)

echo MedVisual Web: http://localhost:5173
call npm run dev -- --host
