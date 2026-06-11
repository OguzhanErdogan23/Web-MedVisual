@echo off
chcp 65001 >nul
title MedVisual Baslatici
cd /d "%~dp0"

echo ============================================================
echo   MedVisual - Tum servisler baslatiliyor
echo ============================================================
echo.
echo  Acilacak 3 pencere (KAPATMAYIN):
echo    1) DIP Motoru   - http://localhost:5000
echo    2) API          - http://localhost:8000
echo    3) Web          - http://localhost:5173
echo.

rem --- 1) Goruntu isleme motoru (DIP) ---
rem NOT: bosluklu yol ("3 proje") nedeniyle bat'lar TAM TIRNAKLI yolla
rem cagrilir (cift-cift tirnak cmd /k kuralidir); bat'lar zaten kendi
rem dizinlerine cd yapar. Eski cd /d && bicimi pencereleri dusuruyordu.
echo [1/3] DIP motoru baslatiliyor...
start "MedVisual DIP (5000)" cmd /k ""%~dp0medvisual-dip\medvisual-dip\run_server.bat""

rem DIP'in ayaga kalkmasi icin bekle
timeout /t 10 /nobreak >nul

rem --- 2) Merkezi API ---
echo [2/3] API baslatiliyor...
start "MedVisual API (8000)" cmd /k ""%~dp0medvisual-api\run_api.bat""

timeout /t 6 /nobreak >nul

rem --- 3) Web arayuzu ---
echo [3/3] Web baslatiliyor...
start "MedVisual Web (5173)" cmd /k ""%~dp0medvisual-web\run_web.bat""

rem --- 4) Telefon USB tuneli (telefon bagliysa) ---
set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"
echo.
echo [Telefon] USB tuneli kuruluyor (telefon bagli degilse onemsiz)...
"%ADB%" reverse tcp:8000 tcp:8000 >nul 2>&1
if %errorlevel%==0 (echo    -> Telefon tuneli hazir.) else (echo    -> Telefon bagli degil ^(USB takip tekrar calistirin^).)

rem --- 5) Tarayiciyi ac ---
echo.
echo Web hazir olunca tarayici acilacak...
timeout /t 10 /nobreak >nul
start "" http://localhost:5173

echo.
echo ============================================================
echo   HAZIR. Web: http://localhost:5173
echo   Telefon: USB tunelli uygulamayi acin (ayni hesapla giris).
echo ============================================================
echo Bu pencereyi kapatabilirsiniz; diger 3 pencere acik kalsin.
pause
