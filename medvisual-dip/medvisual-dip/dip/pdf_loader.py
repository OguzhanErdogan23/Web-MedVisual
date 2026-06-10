"""
pdf_loader.py
-------------
PDF dokumanlarini sayfa goruntulerine cevirir.

PRD'de PyMuPDF (fitz) onerilmistir; bu prototipte ortamda hazir olan
pdf2image + poppler kullanilmaktadir. Arayuz (page_count / render_page)
bilincli olarak sade tutulmustur; ilerideki entegrasyonda govde PyMuPDF
ile degistirilse dahi cagri imzalari ayni kalir.

600+ sayfalik dokumanlar icin tum dokumani belege yuklemeyiz; yalnizca
istenen sayfa 'render_page' ile cizilir (lazy / sayfa-bazli isleme).
"""

from __future__ import annotations

import numpy as np
import cv2
from pdf2image import convert_from_path
from pdf2image.pdf2image import pdfinfo_from_path


def page_count(pdf_path: str) -> int:
    """Dokumandaki toplam sayfa sayisini (render etmeden) dondurur."""
    info = pdfinfo_from_path(pdf_path)
    return int(info["Pages"])


def render_page(pdf_path: str, page_number: int, dpi: int = 200) -> np.ndarray:
    """
    Tek bir PDF sayfasini BGR (OpenCV) numpy dizisi olarak dondurur.

    page_number: 1 tabanli sayfa numarasi.
    dpi        : Cozunurluk. 200 dpi metin/figur ayrimi icin iyi bir denge.
                 Taranmis (scanned) dusuk kaliteli PDF'lerde 300'e cikarilabilir.
    """
    pages = convert_from_path(
        pdf_path,
        dpi=dpi,
        first_page=page_number,
        last_page=page_number,
    )
    if not pages:
        raise ValueError(f"Sayfa render edilemedi: {page_number}")

    pil_img = pages[0].convert("RGB")
    rgb = np.array(pil_img)
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    return bgr


def load_image(image_path: str) -> np.ndarray:
    """Dogrudan bir goruntu dosyasini (PNG/JPG) BGR olarak yukler."""
    img = cv2.imread(image_path, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError(f"Goruntu okunamadi: {image_path}")
    return img
