@echo off
chcp 65001 >nul
title MedVisual - Kaynak Kodu Inceleme
echo Kaynak kodlar VS Code'da SALT OKUNUR olarak aciliyor...
echo (Dosyalar kilitli acilir; yanlislikla degisiklik yapilamaz.)
echo.
echo Sol panelde 4 klasor goreceksiniz:
echo   1) API   - FastAPI backend   (app\routers, app\sm2.py)
echo   2) Web   - React istemci     (src\pages, src\components)
echo   3) Mobil - Flutter istemci   (lib\features, lib\core)
echo   4) DIP   - Goruntu isleme    (app.py, dip\)
echo.
call code "%~dp0medvisual.code-workspace"
