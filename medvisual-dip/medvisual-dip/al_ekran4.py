# -*- coding: utf-8 -*-
"""
Flask (thread) + Selenium — saglamastirilan selector ve bekleme mantigi.
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

for i in range(60):
    try:
        urllib.request.urlopen("http://127.0.0.1:5000/api/health", timeout=2)
        print(f"  Flask hazir ({i+1}s)"); break
    except: time.sleep(1)
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
W = WebDriverWait(driver, 120)   # 2 dakika timeout
BASE = "http://127.0.0.1:5000"

def ss(name, delay=1.0):
    time.sleep(delay)
    path = os.path.join(OUT, name)
    driver.save_screenshot(path)
    print(f"  [SS] {name}  ({os.path.getsize(path)//1024} KB)")

def wait_run_enabled():
    """runBtn enabled olana kadar bekle (max 10s)."""
    for _ in range(20):
        btn = driver.find_element(By.ID, "runBtn")
        if btn.is_enabled():
            return btn
        time.sleep(0.5)
    return driver.find_element(By.ID, "runBtn")  # yine de dene

def wait_output_visible(timeout=120):
    """output div'i hidden sinifi kaybolana kadar bekle."""
    for _ in range(timeout):
        try:
            el = driver.find_element(By.ID, "output")
            cls = el.get_attribute("class") or ""
            if "hidden" not in cls:
                return True
        except: pass
        time.sleep(1)
    return False

def upload_and_wait():
    driver.get(BASE)
    W.until(EC.presence_of_element_located((By.ID, "fileInput")))
    time.sleep(0.5)
    driver.find_element(By.ID, "fileInput").send_keys(PDF)
    W.until(EC.visibility_of_element_located((By.ID, "docInfo")))
    time.sleep(1.0)

def click_mode(mode):
    btn = driver.find_element(By.CSS_SELECTOR, f".mode[data-mode='{mode}']")
    driver.execute_script("arguments[0].click();", btn)
    time.sleep(0.8)

def set_range(val):
    ri = driver.find_element(By.ID, "rangeInput")
    ri.clear(); ri.send_keys(val)
    time.sleep(0.3)

def run_task():
    btn = wait_run_enabled()
    print(f"    runBtn enabled: {btn.is_enabled()}")
    driver.execute_script("arguments[0].click();", btn)
    time.sleep(2)
    # spinner gozuk
    ok = wait_output_visible(timeout=180)
    if not ok:
        print("    [!] output goruntulenemedi (timeout)")
    time.sleep(2)

try:
    # ===== 1. ANA SAYFA =====
    print("\n[1] Ana sayfa...")
    driver.get(BASE)
    W.until(EC.presence_of_element_located((By.CLASS_NAME, "drop")))
    ss("01_ana_sayfa.png", delay=1.5)

    # ===== 2. PDF YUKLE =====
    print("[2] PDF yukleniyor...")
    upload_and_wait()
    ss("02_pdf_yuklendi.png")

    # ===== 3. SEGMENTASYON =====
    print("[3] Segmentasyon modu...")
    click_mode("segment")
    pi = driver.find_element(By.ID, "pageInput")
    pi.clear(); pi.send_keys("45")
    time.sleep(0.5)
    ss("03_seg_ayarlar.png")
    print("  Analiz calistiriliyor (sayfa 45)...")
    run_task()
    ss("04_seg_sonucu.png", delay=1)

    # ===== 4. KART URETIMI =====
    print("[4] Kart uretimi modu...")
    upload_and_wait()
    click_mode("cards")
    set_range("30-38")
    mc = driver.find_element(By.ID, "maxCards")
    mc.clear(); mc.send_keys("20")
    ss("05_kart_ayarlar.png")
    print("  Kartlar uretiliyor (30-38)...")
    run_task()
    ss("06_kart_sonucu.png", delay=1)

    # ===== 5. QUIZ =====
    print("[5] Quiz modu...")
    upload_and_wait()
    click_mode("quiz")
    set_range("30-42")
    nq = driver.find_element(By.ID, "nQuiz")
    nq.clear(); nq.send_keys("10")
    print("  Quiz uretiliyor (30-42)...")
    run_task()
    ss("07_quiz_sonucu.png", delay=1)

    # ===== 6. GORSELLI KART =====
    print("[6] Gorselli kart modu...")
    upload_and_wait()
    click_mode("image-cards")
    set_range("44-52")
    mc = driver.find_element(By.ID, "maxCards")
    mc.clear(); mc.send_keys("8")
    print("  Gorselli kartlar uretiliyor (44-52)...")
    run_task()
    ss("08_gorselli_kart.png", delay=2)

    # ===== 7. KARTA GORSEL EKLE — panel =====
    print("[7] Karta gorsel ekle paneli...")
    upload_and_wait()
    click_mode("add-image")
    set_range("30-50")
    ss("09_karta_gorsel_ekle.png")

    print("\n=== TAMAMLANDI ===")
    for f in sorted(os.listdir(OUT)):
        print(f"  {f}  {os.path.getsize(os.path.join(OUT,f))//1024} KB")

except Exception as ex:
    import traceback
    print(f"\n[!!] Hata: {ex}")
    traceback.print_exc()
    try: ss("HATA.png", delay=0.5)
    except: pass
finally:
    driver.quit()
    print("Chrome kapatildi.")
