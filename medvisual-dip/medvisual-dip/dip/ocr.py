"""
ocr.py
------
Metin Analizi & OCR + Bulanik Eslesme (Fuzzy Matching).

  * Tesseract OCR (pytesseract.image_to_data) ile kelime duzeyinde
    metin + konum (bounding box) + guven (confidence) cikarilir.
  * Latince tip terimleri, ek almis (declension: -us, -i, -um, -ae, -is ...)
    veya OCR hatasi ile yanlis yazilmis hallerinde dahi yakalanabilmesi icin
    BULANIK ESLESME kullanilir.
  * Bulanik eslesme, harici kutuphane yerine elle yazilmis Levenshtein
    (duzenleme uzakligi) algoritmasi ile yapilir -> normalize benzerlik skoru.

PRD geregi kullanici hem serbest bir hedef terim arayabilir ("femur", "kemik"),
hem de sistem gomulu sozlukten otomatik terim tespiti yapabilir.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional

import cv2
import numpy as np
import pytesseract


@dataclass
class Word:
    text: str
    x: int
    y: int
    w: int
    h: int
    conf: float

    @property
    def cx(self) -> float:
        return self.x + self.w / 2.0

    @property
    def cy(self) -> float:
        return self.y + self.h / 2.0


@dataclass
class TermMatch:
    query: str          # aranan terim
    found_text: str     # sayfada bulunan (ham) kelime
    similarity: float   # 0..1 normalize benzerlik
    word: Word          # konum bilgisi


# --------------------------------------------------------------------------- #
# Levenshtein (duzenleme uzakligi) - elle implementasyon
# --------------------------------------------------------------------------- #
def levenshtein(a: str, b: str) -> int:
    """Iki string arasindaki minimum ekleme/silme/degistirme sayisi."""
    a, b = a.lower(), b.lower()
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)

    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        cur = [i]
        for j, cb in enumerate(b, start=1):
            cost = 0 if ca == cb else 1
            cur.append(min(
                prev[j] + 1,        # silme
                cur[j - 1] + 1,     # ekleme
                prev[j - 1] + cost  # degistirme
            ))
        prev = cur
    return prev[-1]


def similarity(a: str, b: str) -> float:
    """Levenshtein tabanli normalize benzerlik (1.0 = ayni)."""
    if not a and not b:
        return 1.0
    dist = levenshtein(a, b)
    return 1.0 - dist / max(len(a), len(b))


# Latince yaygin cekim ekleri (declension). Govdeyi yakalamak icin soyulur.
_LATIN_SUFFIXES = (
    "ibus", "arum", "orum", "ium", "is", "es", "um", "us", "ae", "am",
    "as", "os", "i", "a", "e", "o",
)


def latin_stem(word: str) -> str:
    """Kelimenin sonundaki en uzun Latince ekini soyup govdeyi dondurur."""
    w = word.lower().strip()
    for suf in _LATIN_SUFFIXES:  # en uzundan kisaya
        if len(w) > len(suf) + 2 and w.endswith(suf):
            return w[: -len(suf)]
    return w


def _clean(token: str) -> str:
    return "".join(ch for ch in token if ch.isalpha()).lower()


# --------------------------------------------------------------------------- #
# OCR
# --------------------------------------------------------------------------- #
def ocr_words(bgr: np.ndarray, lang: str = "eng", min_conf: float = 30.0) -> List[Word]:
    """
    Goruntudeki kelimeleri konumlariyla birlikte dondurur.
    lang: Tesseract dil modeli. Latince terimler Latin alfabesinde
          oldugu icin 'eng' modeli pratikte calisir; 'tur'/'lat'
          modelleri kuruluysa virgulle eklenebilir (orn. "eng+tur").
    """
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    # OCR icin hafif esikleme okuma dogrulugunu artirir
    _, thr = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    data = pytesseract.image_to_data(
        thr, lang=lang, output_type=pytesseract.Output.DICT
    )
    words: List[Word] = []
    n = len(data["text"])
    for i in range(n):
        txt = data["text"][i].strip()
        try:
            conf = float(data["conf"][i])
        except (ValueError, TypeError):
            conf = -1.0
        if txt and conf >= min_conf and _clean(txt):
            words.append(Word(
                text=txt,
                x=int(data["left"][i]), y=int(data["top"][i]),
                w=int(data["width"][i]), h=int(data["height"][i]),
                conf=conf,
            ))
    return words


# --------------------------------------------------------------------------- #
# Terim eslesme
# --------------------------------------------------------------------------- #
def match_term(
    words: List[Word],
    query: str,
    threshold: float = 0.72,
) -> List[TermMatch]:
    """
    Verilen hedef terimi sayfadaki kelimeler icinde bulanik olarak arar.
    Hem ham hem de Latince-govde uzerinden eslestirir (ek almis halleri yakalar).
    """
    q_raw = _clean(query)
    q_stem = latin_stem(q_raw)
    matches: List[TermMatch] = []
    for w in words:
        cw = _clean(w.text)
        if not cw:
            continue
        s_raw = similarity(q_raw, cw)
        s_stem = similarity(q_stem, latin_stem(cw))
        score = max(s_raw, s_stem)
        if score >= threshold:
            matches.append(TermMatch(query, w.text, round(score, 3), w))
    matches.sort(key=lambda m: m.similarity, reverse=True)
    return matches


def detect_dictionary_terms(
    words: List[Word],
    dictionary: List[str],
    threshold: float = 0.82,
) -> List[TermMatch]:
    """Gomulu sozlukteki terimleri sayfada otomatik tespit eder.
    Tek kelimelik ve cok kelimelik terimleri ayri isler.
    """
    found: List[TermMatch] = []
    seen = set()
    for term in dictionary:
        term_parts = term.lower().split()
        if len(term_parts) == 1:
            # Tek kelime: mevcut mantik
            for m in match_term(words, term, threshold=threshold):
                key = (term.lower(), m.word.x, m.word.y)
                if key in seen:
                    continue
                seen.add(key)
                found.append(m)
        else:
            # Cok kelime: her parcayi ayri ara, hepsi bulunursa eslestir
            part_matches = []
            all_found = True
            for part in term_parts:
                part_hits = match_term(words, part, threshold=threshold)
                if not part_hits:
                    all_found = False
                    break
                part_matches.append(part_hits[0])
            if not all_found:
                continue
            best = part_matches[0]
            key = (term.lower(), best.word.x, best.word.y)
            if key in seen:
                continue
            seen.add(key)
            avg_sim = sum(m.similarity for m in part_matches) / len(part_matches)
            found.append(TermMatch(
                query=term,
                found_text=" ".join(m.found_text for m in part_matches),
                similarity=round(avg_sim, 3),
                word=best.word,
            ))
    found.sort(key=lambda m: m.similarity, reverse=True)
    return found


def load_dictionary(path: str) -> List[str]:
    """Satir bazli terim sozlugunu yukler (# ile baslayan satirlar yorumdur)."""
    terms: List[str] = []
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    terms.append(line)
    except FileNotFoundError:
        pass
    return terms
