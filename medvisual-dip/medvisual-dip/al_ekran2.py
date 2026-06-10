# -*- coding: utf-8 -*-
"""
Flask sunucusunu thread ile baslatip Selenium ile ekran goruntuleri al.
"""
import os, sys, time, threading, urllib.request

# PATH ayarla
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
os.makedirs(OUT, exist_ok=True)

# ---- Flask'i thread olarak baslat ----------------------------------------
print("Flask baslatiliyor...")
sys.argv = ["app.py"]
os.chdir(BASE_DIR)

def run_flask():
    import app as flask_app
    flask_app.app.run(host="127.0.0.1", port=5000, debug=False, threaded=True, use_reloader=False)

t = threading.Thread(target=run_flask, daemon=True)
t.start()

# Flask hazir olana kadar bekle
print("Flask hazir bekleniyor...")
for i in range(60):
    try:
        urllib.request.urlopen("http://127.0.0.1:5000/api/health", timeout=2)
        print(f"  Flask hazir ({i+1}s)")
        break
    except Exception:
        time.sleep(1)
else:
    print("HATA: Flask baslamadi")
    sys.exit(1)

# ---- Selenium ile ekran goruntuleri --------------------------------------
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

BASE = "http://127.0.0.1:5000"

opts = Options()
opts.add_argument("--window-size=1280,900")
opts.add_argument("--force-device-scale-factor=1")
opts.add_argument("--headless=new")
opts.add_argument("--disable-gpu")
opts.add_argument("--no-sandbox")
opts.add_argument("--disable-dev-shm-usage")

print("Chrome baslatiliyor...")
driver = webdriver.Chrome(options=opts)
driver.set_window_size(1280, 900)
wait = WebDriverWait(driver, 40)

def ss(name, delay=1.5):
    time.sleep(delay)
    path = os.path.join(OUT, name)
    driver.save_screenshot(path)
    size = os.path.getsize(path) // 1024
    print(f"  [SS] {name}  ({size} KB)")
    return path

def find_radio(value):
    """Radio butonu bul: value veya data-mode attribute ile"""
    try:
        return driver.find_element(By.CSS_SELECTOR, f"input[value='{value}']")
    except Exception:
        try:
            return driver.find_element(By.CSS_SELECTOR, f"[data-mode='{value}']")
        except Exception:
            # tum radiolari listele
            radios = driver.find_elements(By.CSS_SELECTOR, "input[type='radio']")
            print(f"  Radios: {[r.get_attribute('value') for r in radios]}")
            raise

def upload_pdf():
    driver.get(BASE)
    wait.until(EC.presence_of_element_located((By.TAG_NAME, "input[type='file']")))
    time.sleep(0.5)
    inputs = driver.find_elements(By.CSS_SELECTOR, "input[type='file']")
    inputs[0].send_keys(PDF)
    # Yukleme tamamlanana kadar bekle
    for _ in range(30):
        try:
            el = driver.find_element(By.ID, "task-section")
            if el.is_displayed():
                break
        except Exception:
            pass
        time.sleep(1)
    time.sleep(1)

try:
    # ===== 1. ANA SAYFA =====
    print("\n[1] Ana sayfa...")
    driver.get(BASE)
    time.sleep(2)
    ss("01_ana_sayfa.png", delay=1)

    # ===== 2. PDF YUKLE SONRASI =====
    print("[2] PDF yukleniyor...")
    upload_pdf()
    ss("02_pdf_yuklendi.png", delay=0.5)

    # ===== 3. SEGMENTASYON MODU =====
    print("[3] Segmentasyon modu...")
    try:
        r = find_radio("segment")
        driver.execute_script("arguments[0].click();", r)
        time.sleep(0.5)
        ri = driver.find_element(By.ID, "page-range")
        ri.clear(); ri.send_keys("45")
        ss("03_seg_mod_secildi.png", delay=0.8)
        driver.find_element(By.ID, "run-btn").click()
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(4)
        ss("04_segmentasyon_sonucu.png", delay=1)
    except Exception as e:
        print(f"  [!] {e}")
        ss("04_segmentasyon_HATA.png", delay=1)

    # ===== 4. KART URETIMI =====
    print("[4] Kart uretimi modu...")
    upload_pdf()
    try:
        r = find_radio("cards")
        driver.execute_script("arguments[0].click();", r)
        time.sleep(0.5)
        ri = driver.find_element(By.ID, "page-range")
        ri.clear(); ri.send_keys("30-38")
        ss("05_kart_mod_secildi.png", delay=0.5)
        driver.find_element(By.ID, "run-btn").click()
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(5)
        ss("06_kart_uretimi_sonucu.png", delay=1)
    except Exception as e:
        print(f"  [!] {e}")
        ss("06_kart_HATA.png", delay=1)

    # ===== 5. QUIZ =====
    print("[5] Quiz modu...")
    upload_pdf()
    try:
        r = find_radio("quiz")
        driver.execute_script("arguments[0].click();", r)
        time.sleep(0.5)
        ri = driver.find_element(By.ID, "page-range")
        ri.clear(); ri.send_keys("30-40")
        driver.find_element(By.ID, "run-btn").click()
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(5)
        ss("07_quiz_sonucu.png", delay=1)
    except Exception as e:
        print(f"  [!] {e}")
        ss("07_quiz_HATA.png", delay=1)

    # ===== 6. GORSELLI KART =====
    print("[6] Gorselli kart modu...")
    upload_pdf()
    try:
        r = find_radio("img_cards")
        driver.execute_script("arguments[0].click();", r)
        time.sleep(0.5)
        ri = driver.find_element(By.ID, "page-range")
        ri.clear(); ri.send_keys("44-50")
        driver.find_element(By.ID, "run-btn").click()
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(8)
        ss("08_gorselli_kart.png", delay=1)
    except Exception as e:
        print(f"  [!] {e}")
        ss("08_gorselli_HATA.png", delay=1)

    print("\n=== Tum ekran goruntuleri alindi ===")
    for f in sorted(os.listdir(OUT)):
        sz = os.path.getsize(os.path.join(OUT, f)) // 1024
        print(f"  {f}  ({sz} KB)")

except Exception as e:
    print(f"Beklenmedik hata: {e}")
    ss("HATA_genel.png", delay=0.5)
finally:
    driver.quit()
    print("Chrome kapatildi.")
