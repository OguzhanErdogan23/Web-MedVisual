@echo off
chcp 65001 >nul
title MedVisual Durdurucu
echo ============================================================
echo   MedVisual - Tum servisler durduruluyor
echo ============================================================
echo.

rem Portlari dinleyen surecleri kapat (DIP 5000, API 8000, Web 5173)
for %%P in (5000 8000 5173) do (
  for /f "tokens=5" %%I in ('netstat -ano -p tcp ^| findstr /r ":%%P .*LISTENING"') do (
    taskkill /F /PID %%I >nul 2>&1
  )
)

rem Servis pencerelerini kapat
taskkill /F /FI "WINDOWTITLE eq MedVisual DIP (5000)*" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq MedVisual API (8000)*" >nul 2>&1
taskkill /F /FI "WINDOWTITLE eq MedVisual Web (5173)*" >nul 2>&1

echo Tum servisler durduruldu. Laptopu guvenle kapatabilirsiniz.
echo Sunum yerinde tekrar baslatmak icin: BASLAT.bat
echo.
pause
