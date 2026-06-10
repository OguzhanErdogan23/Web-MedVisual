"""
flashcard_io.py
---------------
Mevcut bilgi kartlarini ICE/DISA aktarma + kart icin arama terimi secimi.

Desteklenen ice aktarma bicimleri:
  * JSON  : [{"front": "...", "back": "..."}, ...]
  * CSV   : virgul/noktali virgul ayraci
  * TSV   : sekme ayraci (Anki disa aktarim)
  * TXT   : Q:/A: bloklar, sekme ayrac, tire/iki nokta ayrac
  * APKG  : Anki paketi (.apkg) — zip icindeki SQLite
"""

from __future__ import annotations

import csv
import io
import json
import os
import re
import sqlite3
import tempfile
import zipfile
from typing import List, Optional, Sequence

from .cards import Flashcard
from . import ocr

_FRONT_KEYS = ("front", "question", "q", "term", "soru", "on", "ön", "kelime")
_BACK_KEYS = ("back", "answer", "a", "definition", "cevap", "arka", "tanim", "tanım")

_HTML_TAG = re.compile(r"<[^>]+>")
_HTML_ENT = {"&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": '"', "&nbsp;": " ", "&#39;": "'"}


def _strip_html(text: str) -> str:
    text = _HTML_TAG.sub("", text)
    for ent, ch in _HTML_ENT.items():
        text = text.replace(ent, ch)
    return text.strip()


def _pick(d: dict, keys) -> str:
    for k in d:
        if str(k).strip().lower() in keys:
            v = d[k]
            if v is not None and str(v).strip():
                return str(v).strip()
    return ""


def import_cards(content: bytes, filename: str = "") -> List[Flashcard]:
    """Bayt iceriginden kartlari ayristirir. Bicim, uzantidan ve icerikten sezilir."""
    name = (filename or "").lower()

    # APKG: Anki paketi (binary zip)
    if name.endswith(".apkg") or (len(content) > 4 and content[:4] == b"PK\x03\x04"):
        try:
            return _from_apkg(content)
        except Exception:
            pass

    text = content.decode("utf-8-sig", errors="replace") if isinstance(content, bytes) else content

    # JSON
    if name.endswith(".json") or text.lstrip()[:1] in "[{":
        try:
            return _from_json(text)
        except (json.JSONDecodeError, ValueError):
            pass

    # TXT: Q:/A: veya diger metin bicimleri
    if name.endswith(".txt"):
        result = _from_txt(text)
        if result:
            return result

    # CSV / TSV
    return _from_delimited(text)


# --------------------------------------------------------------------------- #
# Ayristiricilar
# --------------------------------------------------------------------------- #

def _from_json(text: str) -> List[Flashcard]:
    data = json.loads(text)
    if isinstance(data, dict):
        for key in ("cards", "flashcards", "data", "items"):
            if key in data and isinstance(data[key], list):
                data = data[key]
                break
        else:
            data = [data]
    cards: List[Flashcard] = []
    for row in data:
        if not isinstance(row, dict):
            continue
        front = _pick(row, _FRONT_KEYS)
        back = _pick(row, _BACK_KEYS)
        if front or back:
            cards.append(Flashcard(
                front=front, back=back,
                term=_pick(row, ("term", "kelime")) or front,
                image_url=_pick(row, ("image_url", "image", "gorsel_url")) or "",
                image_label=_pick(row, ("image_label", "gorsel_etiket")) or "",
            ))
    return cards


def _from_txt(text: str) -> List[Flashcard]:
    """
    TXT formatlarini destekler:
    1) Q: soru\nA: cevap  (bloklar)
    2) soru\tcevap         (sekme ayraci)
    3) soru - cevap        (tire ayraci)
    4) soru: cevap         (iki nokta, satirda baska iki nokta yoksa)
    """
    cards: List[Flashcard] = []

    # Yontem 1: Q:/A: bloklar
    if re.search(r"(?:^|\n)\s*[QqSs]\s*:", text):
        q_pat = re.compile(r"[QqSs]\s*:\s*(.+?)(?=\n\s*[AaCc]\s*:|$)", re.DOTALL)
        a_pat = re.compile(r"[AaCc]\s*:\s*(.+?)(?=\n\s*[QqSs]\s*:|$)", re.DOTALL)
        qs = [m.group(1).strip() for m in q_pat.finditer(text)]
        as_ = [m.group(1).strip() for m in a_pat.finditer(text)]
        for q, a in zip(qs, as_):
            if q and a:
                cards.append(Flashcard(front=q, back=a, term=q))
        if cards:
            return cards

    # Yontem 2: sekme ayraci
    lines = text.splitlines()
    if any("\t" in l for l in lines[:5]):
        for line in lines:
            parts = line.split("\t", 1)
            if len(parts) == 2 and parts[0].strip() and parts[1].strip():
                cards.append(Flashcard(front=parts[0].strip(), back=parts[1].strip(), term=parts[0].strip()))
        if cards:
            return cards

    # Yontem 3: "---" veya bos satir ile ayrilan bloklar
    blocks = re.split(r"\n(?:---+|\s*)\n", text.strip())
    if len(blocks) >= 2:
        for block in blocks:
            block_lines = [l.strip() for l in block.splitlines() if l.strip()]
            if len(block_lines) >= 2:
                cards.append(Flashcard(front=block_lines[0], back=" ".join(block_lines[1:]), term=block_lines[0]))
        if cards:
            return cards

    return cards


def _from_apkg(content: bytes) -> List[Flashcard]:
    """Anki .apkg dosyasindan kartlari cikarir."""
    cards: List[Flashcard] = []
    with tempfile.TemporaryDirectory() as tmpdir:
        zip_path = os.path.join(tmpdir, "deck.apkg")
        with open(zip_path, "wb") as f:
            f.write(content)

        with zipfile.ZipFile(zip_path, "r") as z:
            names = z.namelist()
            db_name = None
            for candidate in ("collection.anki21", "collection.anki2"):
                if candidate in names:
                    db_name = candidate
                    break
            if not db_name:
                return []
            z.extract(db_name, tmpdir)

        db_path = os.path.join(tmpdir, db_name)
        conn = sqlite3.connect(db_path)
        try:
            cursor = conn.execute("SELECT flds FROM notes")
            for (flds,) in cursor:
                fields = flds.split("\x1f")
                if len(fields) >= 2:
                    front = _strip_html(fields[0])
                    back = _strip_html(fields[1])
                    if front or back:
                        cards.append(Flashcard(front=front, back=back, term=front))
        finally:
            conn.close()
    return cards


def _sniff_delim(text: str) -> str:
    head = text.splitlines()[0] if text.splitlines() else ""
    if "\t" in head:
        return "\t"
    if head.count(";") > head.count(","):
        return ";"
    return ","


def _from_delimited(text: str) -> List[Flashcard]:
    delim = _sniff_delim(text)
    reader = csv.reader(io.StringIO(text), delimiter=delim)
    rows = [r for r in reader if any(c.strip() for c in r)]
    if not rows:
        return []
    start = 0
    head = [c.strip().lower() for c in rows[0]]
    if any(h in _FRONT_KEYS for h in head) or any(h in _BACK_KEYS for h in head):
        start = 1
    cards: List[Flashcard] = []
    for r in rows[start:]:
        front = r[0].strip() if len(r) > 0 else ""
        back = r[1].strip() if len(r) > 1 else ""
        if front or back:
            cards.append(Flashcard(front=front, back=back, term=front))
    return cards


# --------------------------------------------------------------------------- #
# Disa aktarim
# --------------------------------------------------------------------------- #

def export_json(cards: Sequence[Flashcard]) -> str:
    return json.dumps([c.to_dict() for c in cards], ensure_ascii=False, indent=2)


def export_csv(cards: Sequence[Flashcard]) -> str:
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["front", "back", "term", "page", "image"])
    for c in cards:
        w.writerow([c.front, c.back, c.term, c.page, c.image_url])
    return buf.getvalue()


def export_anki_tsv(cards: Sequence[Flashcard]) -> str:
    lines = []
    for c in cards:
        back = c.back
        if c.image_url:
            back = f'{back}<br><img src="{c.image_url}">'
        lines.append(f"{c.front}\t{back}")
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Kart icin arama terimi secimi
# --------------------------------------------------------------------------- #

def term_for_card(
    card: Flashcard,
    dictionary: Sequence[str],
    threshold: float = 0.86,
) -> str:
    if card.term and any(card.term.lower() == t.lower() for t in dictionary):
        return card.term
    text = f"{card.front} {card.back}"
    tokens = [w for w in _alpha_tokens(text) if len(w) >= 3]
    best_term, best_score = "", 0.0
    for term in dictionary:
        q_raw = term.lower()
        q_stem = ocr.latin_stem(q_raw)
        for tok in tokens:
            sc = max(ocr.similarity(q_raw, tok.lower()),
                     ocr.similarity(q_stem, ocr.latin_stem(tok.lower())))
            if sc > best_score:
                best_score, best_term = sc, term
    if best_score >= threshold:
        return best_term
    long_tokens = sorted((t for t in tokens if len(t) >= 4), key=len, reverse=True)
    return long_tokens[0] if long_tokens else (card.term or card.front[:20])


def _alpha_tokens(text: str):
    return re.findall(r"[^\W\d_]+", text, flags=re.UNICODE)
