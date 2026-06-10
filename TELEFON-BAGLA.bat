@echo off
chcp 65001 >nul
title MedVisual - Telefon Baglantisi
echo Telefonu USB ile baglayip "USB hata ayiklama" izni verdikten sonra
echo bu dosyaya cift tiklayin. (Uygulama zaten kurulu; sadece tuneli kurar.)
echo.

set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=adb"

echo Bagli cihazlar:
"%ADB%" devices
echo.

echo USB tuneli kuruluyor (telefon 127.0.0.1:8000 -> PC API)...
"%ADB%" reverse tcp:8000 tcp:8000
if %errorlevel%==0 (
  echo.
  echo BASARILI. Artik telefondaki MedVisual uygulamasi API'ye ulasir.
  echo Uygulamayi acip web ile AYNI hesapla giris yapin.
) else (
  echo.
  echo HATA: Cihaz gorunmuyor. USB takili mi? "USB hata ayiklama" acik mi?
)
echo.
pause
