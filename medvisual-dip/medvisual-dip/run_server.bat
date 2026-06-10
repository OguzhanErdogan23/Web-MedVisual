@echo off
REM MedVisual DIP - Windows baslatici.
REM Tesseract ve Poppler'i PATH'e ekleyip Flask sunucusunu venv ile baslatir.
setlocal
set "PATH=C:\Program Files\Tesseract-OCR;%LOCALAPPDATA%\Microsoft\WinGet\Packages\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe\poppler-25.07.0\Library\bin;%PATH%"
"%~dp0venv\Scripts\python.exe" "%~dp0app.py"
