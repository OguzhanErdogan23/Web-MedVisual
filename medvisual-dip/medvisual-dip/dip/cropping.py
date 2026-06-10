"""
cropping.py
-----------
Kirpma (Cropping) ve Aday Gorsel Uretimi.

  * Kontur tespiti (Contour Detection) ile bir figur blogundaki gereksiz beyaz
    bosluklar kirpilir (trim).
  * Bir hedef terimin konumuna EN YAKIN figur blogu bulunur.
  * Kullaniciya sunulmak uzere 3-5 ADAY gorsel uretilir. PRD geregi adaylar
    arasinda "ilgili gorselin tamami" (sayfanin degil, figurun butunu) da yer alir.

Aday seti tipik olarak:
  1. Sikica kirpilmis en yakin figur (tight crop)
  2. Figurun tamami / hafif genis cerceve (caption dahil olabilir)
  3. Netlestirilmis (CLAHE) versiyon
  4. Ikinci en yakin figur (alternatif)
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import List, Optional, Tuple

import cv2
import numpy as np

from .segmentation import Block
from .ocr import TermMatch
from . import enhancement


@dataclass
class Candidate:
    label: str           # aday aciklamasi
    image: np.ndarray    # BGR goruntu
    distance: float      # hedef terime uzaklik (px); -1 = ilgisiz
    path: str = ""       # kaydedildikten sonra dosya yolu


def trim_whitespace(bgr: np.ndarray, pad: int = 6) -> np.ndarray:
    """
    Kontur tespiti ile figurun cevresindeki bos (beyaz) bolgeleri kirpar.
    """
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    _, thr = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
    thr = cv2.morphologyEx(
        thr, cv2.MORPH_CLOSE,
        cv2.getStructuringElement(cv2.MORPH_RECT, (5, 5)),
    )
    contours, _ = cv2.findContours(thr, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return bgr
    xs, ys, xe, ye = [], [], [], []
    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        if w * h < 0.001 * bgr.shape[0] * bgr.shape[1]:
            continue
        xs.append(x); ys.append(y); xe.append(x + w); ye.append(y + h)
    if not xs:
        return bgr
    H, W = bgr.shape[:2]
    x0 = max(0, min(xs) - pad)
    y0 = max(0, min(ys) - pad)
    x1 = min(W, max(xe) + pad)
    y1 = min(H, max(ye) + pad)
    return bgr[y0:y1, x0:x1]


def _crop_block(bgr: np.ndarray, b: Block, pad: int = 0) -> np.ndarray:
    H, W = bgr.shape[:2]
    x0 = max(0, b.x - pad)
    y0 = max(0, b.y - pad)
    x1 = min(W, b.x + b.w + pad)
    y1 = min(H, b.y + b.h + pad)
    return bgr[y0:y1, x0:x1]


def _distance(match: TermMatch, b: Block) -> float:
    """Terim merkezi ile blok merkezi arasindaki Oklid uzakligi."""
    dx = match.word.cx - b.cx
    dy = match.word.cy - b.cy
    return float((dx * dx + dy * dy) ** 0.5)


def nearest_figures(
    match: TermMatch, figures: List[Block], k: int = 2
) -> List[Tuple[Block, float]]:
    """Terime en yakin k figur blogunu (uzakliklariyla) dondurur."""
    ranked = sorted(((b, _distance(match, b)) for b in figures), key=lambda t: t[1])
    return ranked[:k]


def generate_candidates(
    bgr: np.ndarray,
    match: Optional[TermMatch],
    figures: List[Block],
    max_candidates: int = 5,
) -> List[Candidate]:
    """
    Bir terim eslesmesi (veya None) ve figur bloklari icin aday gorseller uretir.

    match None ise: en buyuk figurler dogrudan aday olur (terim bazli degil).
    """
    candidates: List[Candidate] = []
    if not figures:
        return candidates

    if match is None:
        for i, b in enumerate(figures[:max_candidates]):
            crop = trim_whitespace(_crop_block(bgr, b))
            candidates.append(Candidate(f"Figur #{i + 1}", crop, -1.0))
        return candidates

    ranked = nearest_figures(match, figures, k=min(3, len(figures)))
    if not ranked:
        return candidates

    best_block, best_dist = ranked[0]

    # 1) Sikica kirpilmis en yakin figur
    tight = trim_whitespace(_crop_block(bgr, best_block))
    candidates.append(Candidate("En yakin figur (kirpilmis)", tight, best_dist))

    # 2) Figurun tamami (hafif genis cerceve - caption dahil olabilir)
    pad = int(0.04 * max(bgr.shape[:2]))
    whole = _crop_block(bgr, best_block, pad=pad)
    candidates.append(Candidate("Figurun tamami (genis cerceve)", whole, best_dist))

    # 3) Netlestirilmis (CLAHE + denoise) versiyon
    enhanced = enhancement.enhance_for_review(tight)
    candidates.append(Candidate("Netlestirilmis (CLAHE)", enhanced, best_dist))

    # 4) Alternatif yakin figurler
    for idx, (b, dist) in enumerate(ranked[1:], start=2):
        alt = trim_whitespace(_crop_block(bgr, b))
        candidates.append(Candidate(f"Alternatif figur #{idx}", alt, dist))

    return candidates[:max_candidates]


def save_candidates(
    candidates: List[Candidate], out_dir: str, prefix: str = "cand"
) -> List[Candidate]:
    """Adaylari diske kaydeder ve path alanlarini doldurur."""
    os.makedirs(out_dir, exist_ok=True)
    for i, c in enumerate(candidates):
        fname = f"{prefix}_{i + 1}.png"
        fpath = os.path.join(out_dir, fname)
        cv2.imwrite(fpath, c.image)
        c.path = fpath
    return candidates
