# -*- coding: utf-8 -*-
"""
Selenium ile MedVisual arayuzunun ekran goruntuleri.
Flask sunucusu localhost:5000'de calisirken calistir.
"""
import os, time, sys
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

BASE = "http://localhost:5000"
PDF = r"C:\Users\ogito\Desktop\3 proje\Moore's Clinically Oriented Anatomy 7E-1-585.pdf"
OUT = r"C:\Users\ogito\Desktop\3 proje\screenshots"
os.makedirs(OUT, exist_ok=True)

opts = Options()
opts.add_argument("--window-size=1280,900")
opts.add_argument("--force-device-scale-factor=1")
# Headless modda ekran goruntusu al
opts.add_argument("--headless=new")
opts.add_argument("--disable-gpu")
opts.add_argument("--no-sandbox")

print("Chrome baslatiliyor...")
driver = webdriver.Chrome(options=opts)
driver.set_window_size(1280, 900)
wait = WebDriverWait(driver, 30)

def ss(name, delay=1.5):
    time.sleep(delay)
    path = os.path.join(OUT, name)
    driver.save_screenshot(path)
    print(f"  [SS] {name}")
    return path

try:
    # ---- 1. Ana sayfa ----
    print("1. Ana sayfa...")
    driver.get(BASE)
    wait.until(EC.presence_of_element_located((By.ID, "upload-btn")))
    ss("01_ana_sayfa.png")

    # ---- 2. PDF yukle ----
    print("2. PDF yukleniyor...")
    file_input = driver.find_element(By.ID, "pdf-file")
    file_input.send_keys(PDF)
    time.sleep(3)
    # Yukleme sonrasi goster
    try:
        wait.until(EC.visibility_of_element_located((By.ID, "task-section")))
        ss("02_pdf_yuklendi.png")
    except Exception:
        ss("02_pdf_yuklendi.png", delay=2)

    # ---- 3. Bolut leme inceleme modu ----
    print("3. Bolut leme modu seciliyor...")
    try:
        seg_radio = driver.find_element(By.CSS_SELECTOR, "input[value='segment']")
        driver.execute_script("arguments[0].click();", seg_radio)
        ss("03_mod_segmentasyon_secildi.png", delay=0.8)

        # Sayfa 45 gir
        range_inp = driver.find_element(By.ID, "page-range")
        range_inp.clear()
        range_inp.send_keys("45")

        run_btn = driver.find_element(By.ID, "run-btn")
        driver.execute_script("arguments[0].click();", run_btn)
        print("   Analiz calistirildi, bekleniyor...")
        # Gorsel yuklenene kadar bekle
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(3)
        ss("04_segmentasyon_sonucu.png", delay=1)
    except Exception as e:
        print(f"   [!] Segmentasyon modu hatasi: {e}")
        ss("04_segmentasyon_sonucu_hata.png", delay=1)

    # ---- 4. Kart uretimi modu ----
    print("4. Kart uretim modu...")
    try:
        driver.get(BASE)
        wait.until(EC.presence_of_element_located((By.ID, "pdf-file")))
        file_input = driver.find_element(By.ID, "pdf-file")
        file_input.send_keys(PDF)
        wait.until(EC.visibility_of_element_located((By.ID, "task-section")))
        time.sleep(1)

        card_radio = driver.find_element(By.CSS_SELECTOR, "input[value='cards']")
        driver.execute_script("arguments[0].click();", card_radio)
        time.sleep(0.5)

        range_inp = driver.find_element(By.ID, "page-range")
        range_inp.clear()
        range_inp.send_keys("30-35")

        run_btn = driver.find_element(By.ID, "run-btn")
        driver.execute_script("arguments[0].click();", run_btn)
        print("   Kartlar uretiliyor, bekleniyor...")
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(4)
        ss("05_kart_uretimi_sonucu.png", delay=1)
    except Exception as e:
        print(f"   [!] Kart modu hatasi: {e}")
        ss("05_kart_uretimi_hata.png", delay=1)

    # ---- 5. Quiz modu ----
    print("5. Quiz modu...")
    try:
        driver.get(BASE)
        wait.until(EC.presence_of_element_located((By.ID, "pdf-file")))
        file_input = driver.find_element(By.ID, "pdf-file")
        file_input.send_keys(PDF)
        wait.until(EC.visibility_of_element_located((By.ID, "task-section")))
        time.sleep(1)

        quiz_radio = driver.find_element(By.CSS_SELECTOR, "input[value='quiz']")
        driver.execute_script("arguments[0].click();", quiz_radio)
        time.sleep(0.5)

        range_inp = driver.find_element(By.ID, "page-range")
        range_inp.clear()
        range_inp.send_keys("30-40")

        run_btn = driver.find_element(By.ID, "run-btn")
        driver.execute_script("arguments[0].click();", run_btn)
        print("   Quiz uretiliyor, bekleniyor...")
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(4)
        ss("06_quiz_sonucu.png", delay=1)
    except Exception as e:
        print(f"   [!] Quiz modu hatasi: {e}")
        ss("06_quiz_hata.png", delay=1)

    # ---- 6. Gorselli kart modu ----
    print("6. Gorselli kart modu...")
    try:
        driver.get(BASE)
        wait.until(EC.presence_of_element_located((By.ID, "pdf-file")))
        file_input = driver.find_element(By.ID, "pdf-file")
        file_input.send_keys(PDF)
        wait.until(EC.visibility_of_element_located((By.ID, "task-section")))
        time.sleep(1)

        img_radio = driver.find_element(By.CSS_SELECTOR, "input[value='img_cards']")
        driver.execute_script("arguments[0].click();", img_radio)
        time.sleep(0.5)

        range_inp = driver.find_element(By.ID, "page-range")
        range_inp.clear()
        range_inp.send_keys("30-35")

        run_btn = driver.find_element(By.ID, "run-btn")
        driver.execute_script("arguments[0].click();", run_btn)
        print("   Gorselli kartlar uretiliyor, bekleniyor...")
        wait.until(EC.visibility_of_element_located((By.ID, "results-section")))
        time.sleep(5)
        ss("07_gorselli_kart.png", delay=1)
    except Exception as e:
        print(f"   [!] Gorselli kart hatasi: {e}")
        ss("07_gorselli_kart_hata.png", delay=1)

    print("\nTum ekran goruntuleri alindi:", OUT)
    print("Dosyalar:", sorted(os.listdir(OUT)))

finally:
    driver.quit()
