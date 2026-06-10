"""
pipeline.py
-----------
Tum DIP adimlarini birlestiren ana akis.

Akis:
  PDF sayfasi (veya goruntu)
    -> Bolutleme (Otsu + morfoloji + CCA)  [segmentation]
    -> OCR (Tesseract) + kelime kutulari    [ocr]
    -> Terim arama / otomatik terim tespiti [ocr]
    -> En yakin figur + aday gorsel uretimi  [cropping]
    -> Netlestirme                           [enhancement]

Bu fonksiyon Web (Flask) ve ileride Mobil istemcinin cagiracagi tek giris
noktasidir. Donus tipleri JSON'a serilestirilmeye uygun saf veri yapilaridir.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Iterator, List, Optional, Sequence, Tuple

import cv2
import numpy as np

from . import pdf_loader, segmentation, ocr, cropping, textextract

# Render edilen sayfa cozunurlugu (app.py ile tutarli olmali).
RENDER_DPI = 200


@dataclass
class PageAnalysis:
    page_number: int
    width: int
    height: int
    median_char_h: float
    text_blocks: list = field(default_factory=list)
    figure_blocks: list = field(default_factory=list)
    detected_terms: list = field(default_factory=list)   # otomatik tespit
    seg_result: Optional[segmentation.SegmentationResult] = None
    words: list = field(default_factory=list)
    page_image: Optional[np.ndarray] = None
    source: str = "ocr"        # kelimelerin kaynagi: "text" (gomulu) | "ocr"
    page_text: str = ""        # sayfanin duz metni (kart/quiz uretimi icin)


# --------------------------------------------------------------------------- #
# Kelime kaynagi: once gomulu metin katmani, gerekirse OCR
# --------------------------------------------------------------------------- #
def get_page_words(
    pdf_path: str,
    page_number: int,
    dpi: int = RENDER_DPI,
    lang: str = "eng",
    source: str = "auto",
    bgr: Optional[np.ndarray] = None,
) -> Tuple[List[ocr.Word], str, str]:
    """
    Bir sayfanin kelimelerini en uygun yoldan dondurur.

    source : "auto" -> once gomulu metin (pdftotext), bos ise OCR'a duser.
             "text" -> yalnizca gomulu metin (tarama PDF'de bos donebilir).
             "ocr"  -> her zaman goruntu uzerinden OCR (kullanici 'tum sayfayi
                       gorsel olarak isle' dediginde).

    Donus: (kelimeler, duz_metin, kullanilan_kaynak["text"|"ocr"]).
    Not: 'bgr' verilmezse ve OCR gerekiyorsa sayfa burada render edilir.
    """
    if source in ("auto", "text") and textextract.available():
        words, text = textextract.extract_words(pdf_path, page_number, dpi=dpi)
        if words:
            return words, text, "text"
        if source == "text":
            return [], "", "text"

    # OCR yolu
    if bgr is None:
        bgr = pdf_loader.render_page(pdf_path, page_number, dpi=dpi)
    words = ocr.ocr_words(bgr, lang=lang)
    text = " ".join(w.text for w in words)
    return words, text, "ocr"


def analyze_page(
    bgr: np.ndarray,
    page_number: int = 1,
    dictionary: Optional[List[str]] = None,
    lang: str = "eng",
    words: Optional[List[ocr.Word]] = None,
    page_text: str = "",
    source: str = "ocr",
) -> PageAnalysis:
    """
    Tek bir sayfayi tam olarak analiz eder (bolutleme + kelimeler + terim tespiti).

    'words' verilmezse bgr uzerinde OCR yapilir (geriye uyumluluk). Cagiran taraf
    gomulu metin katmanini get_page_words ile alip buraya gecirebilir; bu durumda
    OCR atlanir ve daha hizli/dogru calisir.
    """
    h, w = bgr.shape[:2]
    seg = segmentation.segment_page(bgr)
    if words is None:
        words = ocr.ocr_words(bgr, lang=lang)
        source = "ocr"
        page_text = " ".join(wd.text for wd in words)

    detected = []
    if dictionary:
        detected = ocr.detect_dictionary_terms(words, dictionary)

    return PageAnalysis(
        page_number=page_number,
        width=w, height=h,
        median_char_h=seg.median_char_h,
        text_blocks=seg.text_blocks,
        figure_blocks=seg.figure_blocks,
        detected_terms=detected,
        seg_result=seg,
        words=words,
        page_image=bgr,
        source=source,
        page_text=page_text,
    )


def analyze_pdf_page(
    pdf_path: str,
    page_number: int,
    dpi: int = RENDER_DPI,
    dictionary: Optional[List[str]] = None,
    lang: str = "eng",
    source: str = "auto",
) -> PageAnalysis:
    """
    PDF + sayfa numarasindan tam analiz: sayfayi render eder, kelimeleri
    en uygun yoldan (metin katmani / OCR) alir ve analyze_page'i cagirir.
    Tek giris noktasi olarak Web/Mobil istemciler bunu kullanabilir.
    """
    bgr = pdf_loader.render_page(pdf_path, page_number, dpi=dpi)
    words, text, used = get_page_words(
        pdf_path, page_number, dpi=dpi, lang=lang, source=source, bgr=bgr
    )
    return analyze_page(
        bgr, page_number=page_number, dictionary=dictionary, lang=lang,
        words=words, page_text=text, source=used,
    )


def find_candidates_for_term(
    analysis: PageAnalysis,
    term: str,
    out_dir: str,
    threshold: float = 0.72,
) -> dict:
    """
    Bir terim icin: sayfada bulanik eslesme yapar, en yakin figuru bulur,
    3-5 aday gorsel uretir ve diske kaydeder.
    """
    matches = ocr.match_term(analysis.words, term, threshold=threshold)
    if not matches:
        # Eslesme yoksa terimden bagimsiz en buyuk figurleri aday sun
        cands = cropping.generate_candidates(
            analysis.page_image, None, analysis.figure_blocks
        )
        cands = cropping.save_candidates(cands, out_dir, prefix=f"{_slug(term)}")
        return {
            "term": term, "matched": False, "match_text": None,
            "similarity": None,
            "candidates": [_cand_dict(c) for c in cands],
        }

    best = matches[0]
    cands = cropping.generate_candidates(
        analysis.page_image, best, analysis.figure_blocks
    )
    cands = cropping.save_candidates(cands, out_dir, prefix=f"{_slug(term)}")
    return {
        "term": term, "matched": True,
        "match_text": best.found_text,
        "similarity": best.similarity,
        "match_box": {"x": best.word.x, "y": best.word.y,
                      "w": best.word.w, "h": best.word.h},
        "candidates": [_cand_dict(c) for c in cands],
    }


def _cand_dict(c: cropping.Candidate) -> dict:
    return {
        "label": c.label,
        "distance": round(c.distance, 1),
        "path": c.path,
        "filename": os.path.basename(c.path) if c.path else "",
    }


def _slug(text: str) -> str:
    return "".join(ch if ch.isalnum() else "_" for ch in text.lower())[:30] or "term"


# --------------------------------------------------------------------------- #
# Sayfa araligi yardimcilari
# --------------------------------------------------------------------------- #
def parse_page_range(spec, max_pages: int) -> List[int]:
    """
    Kullanici sayfa araligi ifadesini 1 tabanli, sirali, benzersiz sayfa
    listesine cevirir. Desteklenen bicimler:
        "30"            -> [30]
        "25-50"         -> [25..50]
        "10, 12, 40-42" -> [10, 12, 40, 41, 42]
        {"start":25,"end":50} / (25, 50) -> [25..50]
    Sinir disi degerler kirpilir.
    """
    pages: set = set()

    def add_range(a: int, b: int) -> None:
        if a > b:
            a, b = b, a
        for p in range(a, b + 1):
            if 1 <= p <= max_pages:
                pages.add(p)

    if isinstance(spec, dict):
        add_range(int(spec.get("start", 1)), int(spec.get("end", spec.get("start", 1))))
    elif isinstance(spec, (list, tuple)) and len(spec) == 2 and all(
        isinstance(v, (int, float)) for v in spec
    ):
        add_range(int(spec[0]), int(spec[1]))
    else:
        for chunk in str(spec).replace(";", ",").split(","):
            chunk = chunk.strip()
            if not chunk:
                continue
            if "-" in chunk:
                a, _, b = chunk.partition("-")
                try:
                    add_range(int(a), int(b))
                except ValueError:
                    continue
            else:
                try:
                    p = int(chunk)
                except ValueError:
                    continue
                if 1 <= p <= max_pages:
                    pages.add(p)
    return sorted(pages)


def iter_page_text(
    pdf_path: str,
    pages: Sequence[int],
    dpi: int = RENDER_DPI,
    lang: str = "eng",
    source: str = "auto",
) -> Iterator[Tuple[int, str, List[ocr.Word]]]:
    """
    Verilen sayfalar icin (sayfa_no, duz_metin, kelimeler) uretir.
    Metin katmani varsa sayfa GORUNTUYE cevrilmeden metin alinir (cok hizli);
    yoksa sayfa render edilip OCR yapilir. Bellek dostudur: goruntu tutulmaz.
    """
    for p in pages:
        words, text, _used = get_page_words(
            pdf_path, p, dpi=dpi, lang=lang, source=source
        )
        yield p, text, words


def find_candidates_in_range(
    pdf_path: str,
    pages: Sequence[int],
    term: str,
    out_dir: str,
    dpi: int = RENDER_DPI,
    lang: str = "eng",
    source: str = "auto",
    threshold: float = 0.72,
    max_pages_scan: int = 40,
    keep_top_pages: int = 3,
) -> dict:
    """
    Bir terim icin BIR SAYFA ARALIGI boyunca en uygun figur adaylarini bulur.

    Her sayfa render edilir, bolutlenir ve (metin katmani/OCR ile) terim
    bulanik olarak aranir. Terimin en guclu eslestigi sayfalardaki figurler
    siralanir; en iyi sayfadan tam aday seti, diger guclu sayfalardan ise birer
    alternatif uretilir. PRD geregi adaylar arasinda "ilgili figurun tamami"
    (sayfanin degil) de bulunur.

    Bellek: yalnizca o ana kadarki en iyi 'keep_top_pages' sayfanin goruntusu
    bellekte tutulur; digerleri serbest birakilir.
    """
    scanned = list(pages)[:max_pages_scan]
    truncated = len(pages) > len(scanned)

    # (skor, sayfa, match, figures, image) -- yalnizca en iyi sayfalar tutulur
    hits: List[Tuple[float, int, ocr.TermMatch, list, np.ndarray]] = []

    for p in scanned:
        bgr = pdf_loader.render_page(pdf_path, p, dpi=dpi)
        seg = segmentation.segment_page(bgr)
        words, _text, _used = get_page_words(
            pdf_path, p, dpi=dpi, lang=lang, source=source, bgr=bgr
        )
        matches = ocr.match_term(words, term, threshold=threshold)
        if not matches or not seg.figure_blocks:
            continue
        best = matches[0]
        # Skor: benzerlik agirlikli, en yakin figure uzakligi ile hafif cezali
        nf = cropping.nearest_figures(best, seg.figure_blocks, k=1)
        ndist = nf[0][1] if nf else 1e9
        score = best.similarity - min(ndist, 4000.0) / 40000.0
        hits.append((score, p, best, seg.figure_blocks, bgr))
        hits.sort(key=lambda t: t[0], reverse=True)
        # Sadece en iyi K sayfanin goruntusunu sakla (bellek)
        for i in range(keep_top_pages, len(hits)):
            s, pg, mb, fb, _img = hits[i]
            hits[i] = (s, pg, mb, fb, None)  # type: ignore[assignment]

    if not hits:
        # Hic eslesme yok -> ilk sayfa(lar)dan terimden bagimsiz en buyuk figurler
        for p in scanned:
            bgr = pdf_loader.render_page(pdf_path, p, dpi=dpi)
            seg = segmentation.segment_page(bgr)
            if seg.figure_blocks:
                cands = cropping.generate_candidates(bgr, None, seg.figure_blocks)
                cands = cropping.save_candidates(cands, out_dir, prefix=f"{_slug(term)}_p{p}")
                out = []
                for c in cands:
                    d = _cand_dict(c)
                    d["page"] = p
                    out.append(d)
                return {
                    "term": term, "matched": False, "match_text": None,
                    "similarity": None, "best_page": p, "pages_scanned": len(scanned),
                    "truncated": truncated, "candidates": out,
                }
        return {
            "term": term, "matched": False, "match_text": None, "similarity": None,
            "best_page": None, "pages_scanned": len(scanned),
            "truncated": truncated, "candidates": [],
        }

    # En iyi sayfadan tam aday seti, sonraki guclu sayfalardan birer alternatif
    out: List[dict] = []
    top = hits[:keep_top_pages]
    best_score, best_page, best_match, best_figs, best_img = top[0]

    main = cropping.generate_candidates(best_img, best_match, best_figs, max_candidates=4)
    main = cropping.save_candidates(main, out_dir, prefix=f"{_slug(term)}_p{best_page}")
    for c in main:
        d = _cand_dict(c)
        d["page"] = best_page
        out.append(d)

    for score, pg, mb, fb, img in top[1:]:
        if img is None:
            continue
        alt = cropping.generate_candidates(img, mb, fb, max_candidates=2)
        # Sadece en yakin figuru alternatif olarak ekle (cesitlilik)
        alt = alt[:1]
        alt = cropping.save_candidates(alt, out_dir, prefix=f"{_slug(term)}_p{pg}_alt")
        for c in alt:
            d = _cand_dict(c)
            d["label"] = f"Alternatif (s.{pg}) - {c.label}"
            d["page"] = pg
            out.append(d)

    return {
        "term": term, "matched": True,
        "match_text": best_match.found_text,
        "similarity": round(best_match.similarity, 3),
        "best_page": best_page,
        "pages_scanned": len(scanned),
        "truncated": truncated,
        "candidates": out,
    }
