# -*- coding: utf-8 -*-
"""
Flask (thread) + Selenium ekran goruntu otomasyonu — duzeltilmis selector'lar.
"""
import os, sys, time, threading, urllib.request, shutil

os.environ["PATH"] = (
    r"C:\Program Files\Tesseract-OCR" + os.pathsep +
    r"C:\Users\ogito\AppData\Local\Microsoft\WinGet\Packages"
    r"\oschwartz10612.Poppler_Microsoft.Winget.Source_8wekyb3d8bbwe"
    r"\poppler-25.07.0\Library\bin" + os.pathsep +
    os.environ.get("PATH", "")
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PDF = r"C:\Users\ogito\Desktop\3 proje\Moore's Clinically Oriented Anatomy 7E-1-585.pdf"
OUT  = r"C:\Users\ogito\Desktop\3 proje\screenshots"
shutil.rmtree(OUT, ignore_errors=True)
os.makedirs(OUT, exist_ok=True)

# ---- Flask thread --------------------------------------------------------
print("Flask baslatiliyor...")
sys.argv = ["app.py"]
os.chdir(BASE_DIR)

def run_flask():
    import app as flask_app
    flask_app.app.run(host="127.0.0.1", port=5000, debug=False,
                      threaded=True, use_reloader=False)

threading.Thread(target=run_flask, daemon=True).start()

print("Hazir bekleniyor...")
for i in range(60):
    try:
        urllib.request.urlopen("http://127.0.0.1:5000/api/health", timeout=2)
        print(f"  Flask hazir ({i+1}s)")
        break
    except Exception:
        time.sleep(1)
else:
    print("HATA: Flask baslamadi"); sys.exit(1)

# ---- Selenium -----------------------------------------------------------
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

opts = Options()
opts.add_argument("--window-size=1360,860")
opts.add_argument("--force-device-scale-factor=1")
opts.add_argument("--headless=new")
opts.add_argument("--disable-gpu")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-dev-shm-usage")

print("Chrome baslatiliyor...")
driver = webdriver.Chrome(options=opts)
driver.set_window_size(1360, 860)
wait = WebDriverWait(driver, 50)
BASE = "http://127.0.0.1:5000"

def ss(name, delay=1.5):
    time.sleep(delay)
    path = os.path.join(OUT, name)
    driver.save_screenshot(path)
    print(f"  [OK] {name}  ({os.path.getsize(path)//1024} KB)")

def upload_and_wait(pdf_path=PDF):
    """Ana sayfaya don, PDF yukle, doküman bilgisi gorunene kadar bekle."""
    driver.get(BASE)
    wait.until(EC.presence_of_element_located((By.ID, "fileInput")))
    time.sleep(0.5)
    driver.find_element(By.ID, "fileInput").send_keys(pdf_path)
    # docInfo gorundugunde hazir
    wait.until(EC.visibility_of_element_located((By.ID, "docInfo")))
    time.sleep(0.8)

def click_mode(mode):
    btn = driver.find_element(By.CSS_SELECTOR, f".mode[data-mode='{mode}']")
    driver.execute_script("arguments[0].click();", btn)
    time.sleep(0.5)

def set_range(val):
    ri = driver.find_element(By.ID, "rangeInput")
    ri.clear(); ri.send_keys(val)

def run_and_wait():
    driver.find_element(By.ID, "runBtn").click()
    wait.until(EC.visibility_of_element_located((By.ID, "output")))
    # spinner kaybolana kadar bekle
    for _ in range(60):
        busy = driver.find_element(By.ID, "busy")
        if "hidden" in (busy.get_attribute("class") or ""):
            break
        time.sleep(1)
    time.sleep(2)

try:
    # ===========================================================
    # 1. ANA SAYFA — yukleme oncesi
    # ===========================================================
    print("\n[1] Ana sayfa...")
    driver.get(BASE)
    wait.until(EC.presence_of_element_located((By.ID, "fileInput")))
    time.sleep(1.5)
    ss("01_ana_sayfa.png", delay=0.5)

    # ===========================================================
    # 2. PDF YUKLEME SONRASI
    # ===========================================================
    print("[2] PDF yukleniyor...")
    upload_and_wait()
    ss("02_pdf_yuklendi.png", delay=0.5)

    # ===========================================================
    # 3. SEGMENTASYON MODU — ayarlar paneli
    # ===========================================================
    print("[3] Segmentasyon modu seciliyor...")
    click_mode("segment")
    # Sayfa numarasi
    pi = driver.find_element(By.ID, "pageInput")
    pi.clear(); pi.send_keys("45")
    ss("03_segment_mod_ayarlar.png", delay=0.8)

    # Calistir
    print("  [3b] Analiz calistiriliyor...")
    run_and_wait()
    ss("04_segment_sonucu.png", delay=1.5)

    # ===========================================================
    # 4. BILGI KARTI URETIMI
    # ===========================================================
    print("[4] Bilgi karti modu...")
    upload_and_wait()
    click_mode("cards")
    set_range("30-38")
    ss("05_kart_mod_ayarlar.png", delay=0.5)

    print("  [4b] Kartlar uretiliyor...")
    run_and_wait()
    ss("06_kart_uretimi_sonucu.png", delay=1.5)

    # ===========================================================
    # 5. QUIZ MODU
    # ===========================================================
    print("[5] Quiz modu...")
    upload_and_wait()
    click_mode("quiz")
    set_range("30-42")
    n = driver.find_element(By.ID, "nQuiz")
    n.clear(); n.send_keys("10")

    print("  [5b] Quiz uretiliyor...")
    run_and_wait()
    ss("07_quiz_sonucu.png", delay=1.5)

    # ===========================================================
    # 6. GORSELLI KART MODU
    # ===========================================================
    print("[6] Gorselli kart modu...")
    upload_and_wait()
    click_mode("image-cards")
    set_range("44-52")
    mc = driver.find_element(By.ID, "maxCards")
    mc.clear(); mc.send_keys("10")

    print("  [6b] Gorselli kartlar uretiliyor...")
    run_and_wait()
    ss("08_gorselli_kart_sonucu.png", delay=2)

    # ===========================================================
    # 7. KARTA GORSEL EKLE MODU — panel gorunumu
    # ===========================================================
    print("[7] Karta gorsel ekle modu paneli...")
    upload_and_wait()
    click_mode("add-image")
    set_range("30-50")
    ss("09_karta_gorsel_ekle_panel.png", delay=0.8)

    print("\n=== Tamamlandi ===")
    for f in sorted(os.listdir(OUT)):
        print(f"  {f}  ({os.path.getsize(os.path.join(OUT,f))//1024} KB)")

except Exception as ex:
    print(f"\n[!!] Hata: {ex}")
    try:
        ss("HATA.png", delay=0.3)
    except Exception:
        pass
finally:
    driver.quit()
    print("Chrome kapatildi.")
