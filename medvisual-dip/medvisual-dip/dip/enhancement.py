"""
enhancement.py
--------------
Goruntu Netlestirme (Enhancement).

Ayiklanan tibbi figurlerin incelemeye uygun hale getirilmesi icin:
  * Histogram Esitleme (global Histogram Equalization)
  * CLAHE (Contrast Limited Adaptive Histogram Equalization) - tibbi
    goruntulerde global esitlemeye gore daha dengeli kontrast verir.
  * Gurultu giderme (Denoising): Median, Gaussian, Bilateral filtre.

Renkli figurlerde histogram esitleme YCrCb uzayinda yalnizca parlaklik (Y)
kanalina uygulanir; boylece renk dengesi bozulmaz.
"""

from __future__ import annotations

import cv2
import numpy as np


def histogram_equalization(bgr: np.ndarray) -> np.ndarray:
    """Global histogram esitleme (renk korunarak, Y kanali uzerinde)."""
    if bgr.ndim == 2:
        return cv2.equalizeHist(bgr)
    ycrcb = cv2.cvtColor(bgr, cv2.COLOR_BGR2YCrCb)
    ycrcb[:, :, 0] = cv2.equalizeHist(ycrcb[:, :, 0])
    return cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)


def clahe(bgr: np.ndarray, clip_limit: float = 2.0, grid: int = 8) -> np.ndarray:
    """Adaptif (bolgesel) histogram esitleme - tibbi goruntuler icin onerilir."""
    clahe_op = cv2.createCLAHE(clipLimit=clip_limit, tileGridSize=(grid, grid))
    if bgr.ndim == 2:
        return clahe_op.apply(bgr)
    ycrcb = cv2.cvtColor(bgr, cv2.COLOR_BGR2YCrCb)
    ycrcb[:, :, 0] = clahe_op.apply(ycrcb[:, :, 0])
    return cv2.cvtColor(ycrcb, cv2.COLOR_YCrCb2BGR)


def denoise_median(bgr: np.ndarray, ksize: int = 3) -> np.ndarray:
    """Median filtre - tuz-biber (salt&pepper) gurultusune karsi etkili."""
    if ksize % 2 == 0:
        ksize += 1
    return cv2.medianBlur(bgr, ksize)


def denoise_gaussian(bgr: np.ndarray, ksize: int = 3, sigma: float = 0) -> np.ndarray:
    """Gaussian bulaniklastirma - genel gurultu yumusatma."""
    if ksize % 2 == 0:
        ksize += 1
    return cv2.GaussianBlur(bgr, (ksize, ksize), sigma)


def denoise_bilateral(bgr: np.ndarray, d: int = 7) -> np.ndarray:
    """Bilateral filtre - kenarlari korurken gurultu giderir (detay korunur)."""
    return cv2.bilateralFilter(bgr, d, 50, 50)


def enhance_for_review(bgr: np.ndarray) -> np.ndarray:
    """
    Inceleme icin varsayilan zincir: kenar koruyan denoising + CLAHE.
    Histoloji/diyagram gibi tibbi figurlerde okunabilirligi artirir.
    """
    out = denoise_bilateral(bgr, d=7)
    out = clahe(out, clip_limit=2.0, grid=8)
    return out
