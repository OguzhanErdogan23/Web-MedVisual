"""
segmentation.py
---------------
Sayfa Bolutleme (Page Segmentation).

Amac: Bir tip kitabi sayfasini (taranmis olsa dahi) METIN bloklari ve
GORSEL/FIGUR bloklari (diyagram, histoloji slayti, anatomik sema vb.)
olarak ayristirmak.

Kullanilan klasik DIP teknikleri (ders kapsamiyla birebir ortusur):
  * Gri tonlama + Otsu Esikleme (otomatik esik secimi)
  * Morfolojik islemler: Dilation / Erosion / Closing (RLSA benzeri birlestirme)
  * BaglI Bilesen Analizi (Connected Component Analysis)
  * Renk uzayi (HSV) doygunluk analizi -> renkli figur tespiti
  * Kontur tespiti (boundingRect)

Siniflandirma sezgisi:
  - Metin karakterleri birbirine yakin, kucuk ve duzenli yukseklikte bilesenlerdir.
    Once metnin medyan karakter yuksekligi (h_t) bulunur.
  - h_t'nin birkac katindan buyuk / cok genis alanli / renkli bilesenler FIGUR adayidir.
  - Kalan kucuk bilesenler yatay olarak birlestirilerek METIN bloklarini olusturur.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Tuple

import cv2
import numpy as np


@dataclass
class Block:
    """Sayfada tespit edilen tek bir blok (metin ya da figur)."""
    x: int
    y: int
    w: int
    h: int
    kind: str  # "text" | "figure"
    area: int = 0
    fill: float = 0.0          # bbox icindeki onplan piksel orani
    saturation: float = 0.0    # ortalama renk doygunlugu (0-255)

    @property
    def bbox(self) -> Tuple[int, int, int, int]:
        return (self.x, self.y, self.w, self.h)

    @property
    def cx(self) -> float:
        return self.x + self.w / 2.0

    @property
    def cy(self) -> float:
        return self.y + self.h / 2.0

    def to_dict(self) -> dict:
        return {
            "x": self.x, "y": self.y, "w": self.w, "h": self.h,
            "kind": self.kind, "area": self.area,
            "fill": round(self.fill, 3), "saturation": round(self.saturation, 1),
        }


@dataclass
class SegmentationResult:
    binary: np.ndarray
    text_blocks: List[Block] = field(default_factory=list)
    figure_blocks: List[Block] = field(default_factory=list)
    median_char_h: float = 0.0


# --------------------------------------------------------------------------- #
# Temel adimlar
# --------------------------------------------------------------------------- #
def to_grayscale(bgr: np.ndarray) -> np.ndarray:
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)


def otsu_binarize(gray: np.ndarray) -> np.ndarray:
    """
    Otsu otomatik esikleme. Onplan (murekkep) = 255 olacak sekilde ters cevirir.
    Hafif Gaussian bulaniklastirma tarama gurultusunu bastirir.
    """
    blur = cv2.GaussianBlur(gray, (3, 3), 0)
    _, binary = cv2.threshold(
        blur, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
    )
    return binary


def _saturation_map(bgr: np.ndarray) -> np.ndarray:
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    return hsv[:, :, 1]  # S kanali


# --------------------------------------------------------------------------- #
# Ana bolutleme
# --------------------------------------------------------------------------- #
def segment_page(
    bgr: np.ndarray,
    figure_height_factor: float = 3.0,
    min_figure_area_ratio: float = 0.004,
    saturation_thresh: float = 45.0,
    max_proc_dim: int = 1600,
) -> SegmentationResult:
    """
    Sayfayi metin ve figur bloklarina ayristirir.

    figure_height_factor : Bir bilesen "buyuk nesne" sayilmasi icin medyan
                           karakter yuksekliginin kac kati olmali.
    min_figure_area_ratio: Figur blogunun sayfa alanina gore minimum orani.
    saturation_thresh    : Bu degerin uzerindeki ortalama doygunluk renkli
                           (dolayisiyla figur) kabul edilir.
    max_proc_dim         : Bolutleme HESAPLAMASI bu uzun-kenar pikseline kadar
                           kuculterek yapilir (hiz icin). 600+ sayfalik, 200 dpi
                           taranmis kitaplarda sayfa ~3300 px olabilir; morfoloji
                           ve baglanti-bileseni analizi tam cozunurlukte cok yavas
                           (sayfa basina ~30 sn). Kucuk olcekte calisip blok
                           koordinatlari tekrar tam cozunurluge olceklenir; tum
                           esikler medyan karakter yuksekligine GORELI oldugundan
                           sonuc degismez, yalnizca ~5-6x hizlanir.
    """
    orig_bgr = bgr
    orig_h, orig_w = bgr.shape[:2]
    long_side = max(orig_h, orig_w)
    if long_side > max_proc_dim:
        scale = max_proc_dim / float(long_side)
        bgr = cv2.resize(
            bgr, (max(1, int(orig_w * scale)), max(1, int(orig_h * scale))),
            interpolation=cv2.INTER_AREA,
        )
    else:
        scale = 1.0

    h_img, w_img = bgr.shape[:2]
    page_area = h_img * w_img

    gray = to_grayscale(bgr)
    binary = otsu_binarize(gray)
    sat = _saturation_map(bgr)

    # 1) Baglanti bilesenleri (ham, birlestirmeden once) -> karakter istatistigi
    num, labels, stats, _ = cv2.connectedComponentsWithStats(binary, connectivity=8)

    heights = []
    for i in range(1, num):  # 0 = arkaplan
        ch = stats[i, cv2.CC_STAT_HEIGHT]
        cw = stats[i, cv2.CC_STAT_WIDTH]
        ca = stats[i, cv2.CC_STAT_AREA]
        # Gurultu ve cizgi disindaki "harf benzeri" bilesenler
        if 4 <= ch <= 80 and ca >= 6 and cw <= 80:
            heights.append(ch)

    median_char_h = float(np.median(heights)) if heights else 12.0

    # 2) FIGUR adayi pikselleri uc bagimsiz ipucu ile topla:
    big_object_mask = np.zeros((h_img, w_img), dtype=np.uint8)
    small_mask = np.zeros((h_img, w_img), dtype=np.uint8)

    h_big = figure_height_factor * median_char_h
    for i in range(1, num):
        cw = stats[i, cv2.CC_STAT_WIDTH]
        ch = stats[i, cv2.CC_STAT_HEIGHT]
        ca = stats[i, cv2.CC_STAT_AREA]
        comp = (labels == i)

        # (a) Buyuk nesne / cizgi-resim: tek bir baglI bilesen 2 boyutta da
        #     metin yuksekliginin cok ustunde (orn. diyagram dis hatti, sema).
        is_big_object = (
            max(cw, ch) > h_big and min(cw, ch) > 1.5 * median_char_h
        )
        if is_big_object:
            big_object_mask[comp] = 255
        else:
            small_mask[comp] = 255

    # (b) Renkli bolgeler (doygun histoloji/diyagram): doygunluk maskesi.
    color_mask = (sat > saturation_thresh).astype(np.uint8) * 255
    color_kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT, (max(8, int(median_char_h)), max(8, int(median_char_h)))
    )
    color_mask = cv2.morphologyEx(color_mask, cv2.MORPH_CLOSE, color_kernel, iterations=2)
    big_object_mask = cv2.bitwise_or(big_object_mask, color_mask)

    # Figur bloklarini konsolide et
    fig_kernel = cv2.getStructuringElement(
        cv2.MORPH_RECT,
        (max(8, int(median_char_h)), max(8, int(median_char_h))),
    )
    fig_closed = cv2.morphologyEx(big_object_mask, cv2.MORPH_CLOSE, fig_kernel, iterations=2)
    fig_closed = cv2.dilate(fig_closed, fig_kernel, iterations=1)
    figure_blocks = _extract_blocks(
        fig_closed, binary, sat, "figure",
        min_area=min_figure_area_ratio * page_area,
    )

    # 3) Metin bloklari: kucuk bilesenleri yatay RLSA ile satirlara, sonra dikey
    #    kapama ile paragraflara birlestir. Bilinen figur alanlarini cikar.
    small_mask[fig_closed > 0] = 0
    h_dilate = cv2.getStructuringElement(
        cv2.MORPH_RECT, (max(15, int(median_char_h * 1.8)), 1)
    )
    text_lines = cv2.dilate(small_mask, h_dilate, iterations=1)
    v_close = cv2.getStructuringElement(
        cv2.MORPH_RECT, (1, max(3, int(median_char_h * 0.8)))
    )
    text_blocks_mask = cv2.morphologyEx(text_lines, cv2.MORPH_CLOSE, v_close, iterations=1)
    raw_text_blocks = _extract_blocks(
        text_blocks_mask, binary, sat, "text",
        min_area=max(200.0, 6 * median_char_h * median_char_h),
    )

    # 4) (c) DOKU ipucu: cok-satirli ama satir-arasi bosluk barindirmayan bloklar
    #    (orn. soluk renkli histoloji dokusu) aslinda FIGUR'dur. Satir-bosluk
    #    orani dusukse (yogun dolu) blok figure olarak yeniden siniflandirilir.
    #    ANCAK: saf siyah-beyaz, sik dizilmis metin paragraflari da dusuk
    #    bosluk oranina sahip olabilir. Bu yuzden ek olarak blogun bir miktar
    #    renk doygunlugu (saturation > 20) barindirmasini sart kosuyoruz; boylece
    #    siyah metin paragraflari (sat ~ 0) yanlislikla figure sayilmaz.
    text_blocks: List[Block] = []
    for tb in raw_text_blocks:
        roi = binary[tb.y:tb.y + tb.h, tb.x:tb.x + tb.w]
        multiline = tb.h > 3 * median_char_h
        if multiline and _gap_ratio(roi) < 0.30 and tb.saturation > 20:
            tb.kind = "figure"
            figure_blocks.append(tb)
        else:
            text_blocks.append(tb)

    # Cakisan / ic ice figur bloklarini birlestir
    figure_blocks = _merge_overlapping(figure_blocks, binary, sat)
    figure_blocks = [b for b in figure_blocks
                     if b.area >= min_figure_area_ratio * page_area]
    figure_blocks.sort(key=lambda b: b.area, reverse=True)

    # Figur bloklarinin icine dusen yanlis metin bloklarini ele
    text_blocks = [tb for tb in text_blocks
                   if not _center_inside_any(tb, figure_blocks)]

    # Kucuk olcekte bulunan bloklari TAM cozunurluge geri olcekle
    if scale != 1.0:
        inv = 1.0 / scale
        text_blocks = [_rescale_block(b, inv) for b in text_blocks]
        figure_blocks = [_rescale_block(b, inv) for b in figure_blocks]
        median_char_h *= inv
        # Sonuctaki ikili goruntuyu tam cozunurlukte uret (downstream tutarlilik)
        binary = otsu_binarize(to_grayscale(orig_bgr))

    return SegmentationResult(
        binary=binary,
        text_blocks=text_blocks,
        figure_blocks=figure_blocks,
        median_char_h=median_char_h,
    )


def _rescale_block(b: Block, factor: float) -> Block:
    """Bir blogun koordinatlarini verilen carpan ile tam cozunurluge tasir.
    fill ve saturation oransal/yogunluk degerleridir; degismez. area px^2 olarak
    olceklenir."""
    return Block(
        x=int(round(b.x * factor)),
        y=int(round(b.y * factor)),
        w=int(round(b.w * factor)),
        h=int(round(b.h * factor)),
        kind=b.kind,
        area=b.area * factor * factor,
        fill=b.fill,
        saturation=b.saturation,
    )


def _gap_ratio(roi_binary: np.ndarray, row_thresh: float = 0.02) -> float:
    """
    Satir-bosluk orani: neredeyse bos olan yatay satirlarin orani.
    Metin paragraflarinda yuksek (satir araları), yogun figur/doku da dusuk.
    """
    if roi_binary.size == 0:
        return 1.0
    rows = (roi_binary > 0).sum(axis=1)
    empty = int((rows < row_thresh * roi_binary.shape[1]).sum())
    return empty / float(roi_binary.shape[0])


def _merge_overlapping(blocks: List[Block], binary: np.ndarray,
                       sat: np.ndarray) -> List[Block]:
    """Cakisan bloklarin birlesim dikdortgenini alarak tekillestirir."""
    if not blocks:
        return []
    boxes = [[b.x, b.y, b.x + b.w, b.y + b.h] for b in blocks]
    merged = True
    while merged:
        merged = False
        out = []
        used = [False] * len(boxes)
        for i in range(len(boxes)):
            if used[i]:
                continue
            ax0, ay0, ax1, ay1 = boxes[i]
            for j in range(i + 1, len(boxes)):
                if used[j]:
                    continue
                bx0, by0, bx1, by1 = boxes[j]
                if ax0 < bx1 and bx0 < ax1 and ay0 < by1 and by0 < ay1:
                    ax0, ay0 = min(ax0, bx0), min(ay0, by0)
                    ax1, ay1 = max(ax1, bx1), max(ay1, by1)
                    used[j] = True
                    merged = True
            out.append([ax0, ay0, ax1, ay1])
            used[i] = True
        boxes = out
    result = []
    for x0, y0, x1, y1 in boxes:
        w, h = x1 - x0, y1 - y0
        roi = binary[y0:y1, x0:x1]
        fill = float((roi > 0).mean()) if roi.size else 0.0
        msat = float(sat[y0:y1, x0:x1].mean()) if roi.size else 0.0
        result.append(Block(x0, y0, w, h, "figure", w * h, fill, msat))
    return result


def _center_inside_any(block: "Block", figures: List["Block"]) -> bool:
    """block'un merkezi herhangi bir figur blogunun icinde mi?"""
    for f in figures:
        if f.x <= block.cx <= f.x + f.w and f.y <= block.cy <= f.y + f.h:
            return True
    return False


def _extract_blocks(
    mask: np.ndarray,
    binary: np.ndarray,
    sat: np.ndarray,
    kind: str,
    min_area: float,
) -> List[Block]:
    """Bir maskeden kontur/boundingRect ile bloklari cikarir."""
    contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    blocks: List[Block] = []
    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        if w * h < min_area:
            continue
        roi_bin = binary[y:y + h, x:x + w]
        roi_sat = sat[y:y + h, x:x + w]
        fg = int((roi_bin > 0).sum())
        fill = fg / float(w * h) if w * h else 0.0
        blocks.append(Block(
            x=int(x), y=int(y), w=int(w), h=int(h),
            kind=kind, area=int(w * h),
            fill=fill, saturation=float(roi_sat.mean()),
        ))
    blocks.sort(key=lambda b: b.area, reverse=True)
    return blocks


def draw_segmentation(bgr: np.ndarray, result: SegmentationResult) -> np.ndarray:
    """Metin (yesil) ve figur (kirmizi) bloklarini gorsel olarak isaretler."""
    vis = bgr.copy()
    for b in result.text_blocks:
        cv2.rectangle(vis, (b.x, b.y), (b.x + b.w, b.y + b.h), (0, 170, 0), 2)
    for b in result.figure_blocks:
        cv2.rectangle(vis, (b.x, b.y), (b.x + b.w, b.y + b.h), (0, 0, 220), 3)
    return vis
