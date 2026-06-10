@echo off
chcp 65001 >nul
title MedVisual DIP
cd /d "%~dp0"

echo.
echo  ╔══════════════════════════════════╗
echo  ║       MedVisual DIP              ║
echo  ║   http://localhost:5000          ║
echo  ╚══════════════════════════════════╝
echo.

REM Tesseract ve Poppler'i PATH'e ekle (varsa)
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\UB-Mannheim.TesseractOCR*") do set "PATH=%%D;%PATH%"
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\oschwartz10612.Poppler*\poppler-*\Library\bin") do set "PATH=%%D;%PATH%"

call venv\Scripts\activate.bat

echo Sunucu baslatiliyor (lutfen bekleyin)...

REM Once Flask'i ayri bir pencerede baslat (engellemez)
start "MedVisual DIP - Sunucu" venv\Scripts\python.exe app.py

REM Flask'in tamamen yuklenmesi icin 5 saniye bekle
timeout /t 5 /nobreak >nul

REM Tarayiciyi Flask hazir olduktan sonra ac
echo Tarayici aciliyor...
start "" "http://localhost:5000"

echo.
echo  Sunucu "MedVisual DIP - Sunucu" penceresinde calisiyor.
echo  O pencereyi kapatirsan uygulama durur.
echo  Bu pencereyi kapatabilirsin.
echo.
pause
