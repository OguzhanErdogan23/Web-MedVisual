"""
textextract.py
--------------
Metin katmani cikarimi (gomulu PDF metni) - OCR'a alternatif/oncelikli yol.

Cok sayfali tibbi dokumanlarin onemli bir kismi (dijital ders kitaplari)
*metin secilebilen* PDF'lerdir: sayfada karakterler gomulu vektor metin olarak
durur. Bu durumda sayfayi goruntuye cevirip Tesseract ile OKUMAK yerine, metni
ve kelime KONUMLARINI dogrudan PDF'ten almak hem cok daha hizli hem de
hatasizdir (OCR hatasi olmaz).

  * pdftotext (poppler) -bbox modu, her kelimeyi PDF NOKTA (point, 72 dpi)
    koordinatlariyla XHTML olarak dokar. Bu modul ciktiyi ayristirip, render
    edilmis sayfa goruntusuyle AYNI piksel uzayina olcekler (dpi/72), boylece
    cikan Word kutulari bolutleme figur bloklariyla ayni koordinat sisteminde
    olur ve terim->figur uzakligi dogrudan hesaplanabilir.

Akis karari (bkz. pipeline.get_page_words):
  - Once metin katmani denenir; sayfada yeterli kelime varsa o kullanilir.
  - Sayfa taranmis (gomulu metin yok) ise OCR'a (ocr.ocr_words) dusulur.

Donus tipi, OCR ile birebir degistirilebilir olmasi icin ocr.Word'dur.
"""

from __future__ import annotations

import os
import re
import html
import shutil
import subprocess
from typing import List, Optional, Tuple

from .ocr import Word

# pdftotext yurutulebiliri. PATH'te degilse POPPLER_PATH ortam degiskeni ya da
# set_poppler_path() ile elle gosterilebilir (Windows'ta winget bin dizini gibi).
_POPPLER_BIN: Optional[str] = os.environ.get("POPPLER_PATH") or None

_PAGE_RE = re.compile(r'<page[^>]*\bwidth="([0-9.]+)"[^>]*\bheight="([0-9.]+)"', re.I)
_WORD_RE = re.compile(
    r'<word[^>]*\bxMin="([0-9.]+)"[^>]*\byMin="([0-9.]+)"'
    r'[^>]*\bxMax="([0-9.]+)"[^>]*\byMax="([0-9.]+)"[^>]*>(.*?)</word>',
    re.I | re.S,
)


def set_poppler_path(path: str) -> None:
    """pdftotext'in bulundugu dizini elle ayarlar (PATH'te yoksa)."""
    global _POPPLER_BIN
    _POPPLER_BIN = path


def _pdftotext_exe() -> Optional[str]:
    """pdftotext yurutulebilirinin tam yolunu bulur (yoksa None)."""
    if _POPPLER_BIN:
        cand = os.path.join(_POPPLER_BIN, "pdftotext")
        for c in (cand, cand + ".exe"):
            if os.path.isfile(c):
                return c
    return shutil.which("pdftotext")


def available() -> bool:
    """Metin katmani cikarimi bu ortamda kullanilabilir mi?"""
    return _pdftotext_exe() is not None


def extract_words(
    pdf_path: str,
    page_number: int,
    dpi: int = 200,
    min_conf: float = 100.0,
) -> Tuple[List[Word], str]:
    """
    Tek bir PDF sayfasinin gomulu metnini kelime kutulariyla dondurur.

    page_number : 1 tabanli.
    dpi         : render_page ile AYNI dpi verilmeli; kutular bu cozunurluge
                  olceklenir, boylece bolutleme bloklariyla ayni uzayda olur.

    Donus: (kelimeler, sayfanin duz metni). Sayfada gomulu metin yoksa
           ([], "") doner -> cagiran taraf OCR'a duser.
    """
    exe = _pdftotext_exe()
    if not exe:
        return [], ""

    try:
        out = subprocess.run(
            [exe, "-bbox", "-enc", "UTF-8",
             "-f", str(page_number), "-l", str(page_number), pdf_path, "-"],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=60,
        ).stdout
    except (OSError, subprocess.SubprocessError):
        return [], ""

    if not out:
        return [], ""

    # PDF noktasi (point, 72 dpi) -> piksel olcegi
    scale = dpi / 72.0

    words: List[Word] = []
    text_tokens: List[str] = []
    for m in _WORD_RE.finditer(out):
        x_min, y_min, x_max, y_max = (float(m.group(i)) for i in range(1, 5))
        raw = html.unescape(m.group(5)).strip()
        if not raw:
            continue
        words.append(Word(
            text=raw,
            x=int(round(x_min * scale)),
            y=int(round(y_min * scale)),
            w=int(round((x_max - x_min) * scale)),
            h=int(round((y_max - y_min) * scale)),
            conf=min_conf,
        ))
        text_tokens.append(raw)

    return words, " ".join(text_tokens)


def page_has_text(pdf_path: str, page_number: int, min_words: int = 8) -> bool:
    """
    Sayfanin gomulu (secilebilen) metin katmani var mi? Tarama PDF'lerinde
    genelde 0 kelime doner -> False (OCR gerekir).
    """
    words, _ = extract_words(pdf_path, page_number, dpi=72)
    return len(words) >= min_words
