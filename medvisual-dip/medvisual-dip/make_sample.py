"""
Sentetik tip kitabi sayfasi uretir (gercek PDF gelene kadar test icin).
Metin paragraflari (Latince terimler dahil) + 2 renkli figur icerir.
"""
import os
import numpy as np
import cv2
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

W, H = 1240, 1600  # ~A4 @ 150dpi
img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)

def font(size):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
              "C:/Windows/Fonts/georgia.ttf",
              "C:/Windows/Fonts/times.ttf",
              "C:/Windows/Fonts/arial.ttf"]:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()

title_f = font(34)
body_f = font(22)

d.text((80, 60), "Bolum 7: Iskelet Sistemi ve Kemik Dokusu", font=title_f, fill="black")

para1 = [
    "Femur, insan vucudundaki en uzun ve en guclu kemiktir. Proximal ucunda",
    "caput femoris yer alir ve pelvis ile eklem yapar. Musculus quadriceps",
    "femoris, patella araciligiyla tibia uzerine kuvvet aktarir. Arteria",
    "femoralis bacagin ana kan akimini saglar.",
]
y = 130
for line in para1:
    d.text((80, y), line, font=body_f, fill="black")
    y += 34

# --- Figur 1: histoloji benzeri renkli doku (mor/pembe noktalar) ---
fx, fy, fw, fh = 120, 320, 460, 360
d.rectangle([fx, fy, fx + fw, fy + fh], fill=(245, 235, 240))
rng = np.random.default_rng(7)
for _ in range(900):
    cx = rng.integers(fx + 10, fx + fw - 10)
    cy = rng.integers(fy + 10, fy + fh - 10)
    r = int(rng.integers(3, 9))
    col = (int(rng.integers(120, 200)), int(rng.integers(20, 80)), int(rng.integers(120, 200)))
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=col)
d.text((fx, fy + fh + 6), "Sekil 7.1: Kemik dokusu histolojisi (H&E)", font=font(18), fill="black")

# --- Figur 2: anatomik sema (renkli sekiller) sag tarafta ---
gx, gy, gw, gh = 700, 320, 420, 380
d.rectangle([gx, gy, gx + gw, gy + gh], fill=(235, 245, 250))
d.ellipse([gx + 120, gy + 30, gx + 300, gy + 110], fill=(70, 130, 200), outline="black", width=3)
d.rectangle([gx + 170, gy + 110, gx + 250, gy + 300], fill=(220, 120, 60), outline="black", width=3)
d.ellipse([gx + 140, gy + 300, gx + 280, gy + 360], fill=(90, 180, 110), outline="black", width=3)
d.text((gx, gy + gh + 6), "Sekil 7.2: Femur anatomik semasi", font=font(18), fill="black")

para2 = [
    "Tibia ve fibula, bacagin alt kismini olusturan iki kemiktir. Bu kemikler",
    "ligamentum araciligiyla birbirine baglanir. Nervus ischiadicus bolgenin",
    "duyusal ve motor inervasyonunu saglar. Vertebra kolonu ise govdenin",
    "eksenel iskeletini meydana getirir ve medulla spinalis'i korur.",
]
y = 740
for line in para2:
    d.text((80, y), line, font=body_f, fill="black")
    y += 34

para3 = [
    "Histolojik kesitlerde osteon yapilari ve canaliculi acikca gozlenir.",
    "Collagen lifleri kemige esneklik kazandirirken, mineral matriks",
    "sertligi saglar. Endothelium ile dosenmiis damar kanallari besin tasir.",
]
y = 900
for line in para3:
    d.text((80, y), line, font=body_f, fill="black")
    y += 34

out_path = os.path.join(BASE_DIR, "samples", "sample_page.png")
os.makedirs(os.path.dirname(out_path), exist_ok=True)
img.save(out_path)
print("Sentetik sayfa olusturuldu: samples/sample_page.png", (W, H))
