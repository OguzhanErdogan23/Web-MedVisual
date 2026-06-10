"""
cards.py
--------
Offline (LLM'siz) bilgi karti (flashcard) ve test/quiz uretimi.

Tasarim felsefesi: Bu modul bir gorsel isleme dersi projesidir; metin uretimi
de -tipki bulanik eslesmenin elle yazilmasi gibi- ACIKLANABILIR, deterministik
ve dis servise bagimsiz klasik DIP/NLP teknikleriyle yapilir:

  * Cumle bolutleme (kisaltma korumali nokta ayirma)
  * Anahtar terim tespiti (gomulu Latince sozluk + bulanik/govde eslesme)
  * "Tanim cumlesi" puanlama sezgisi (terim konumu, baglac/yuklem, uzunluk,
    figur-altyazi cezasi)
  * Cikarimsal (extractive) kart uretimi: terim->tanim ve cloze (bosluk doldurma)
  * Coktan secmeli soru (MCQ): dogru tanim + diger terimlerin tanimlarindan
    uretilen celdiriciler

Girdi olarak pipeline.iter_page_text ciktisindaki (sayfa, metin, kelimeler)
ucluleri kullanilir; boylece hem metin-katmanli hem de OCR'li sayfalar ayni
sekilde islenir.
"""

from __future__ import annotations

import random
import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Sequence, Tuple

from . import ocr

# Sonunda nokta bulunan ama cumle SONU olmayan yaygin kisaltmalar.
_ABBREV = {
    "fig", "figs", "ed", "eds", "p", "pp", "vol", "no", "etc", "st",
    "dr", "prof", "vs", "approx", "cf", "al", "inc", "co", "mr", "mrs",
    "ca", " par", "art", "lig", "m", "n", "a", "v",  # Latince kisaltmalar
}

_WORD_TOKEN = re.compile(r"[^\W\d_]+", re.UNICODE)  # harf dizileri (rakamsiz)

# Tanim cumlesini guclendiren baglac/yuklem ipuclari (TR + EN).
_DEFINITION_CUES = (
    " is ", " are ", " is a ", " are the ", " refers to ", " consists of ",
    " known as ", " defined as ", " bir ", " olan ", "dir.", "dır.", "tir.",
    "tır.", "dur.", "dür.", " olarak ", " ise ", " denir", " adi ",
)


@dataclass
class Flashcard:
    front: str
    back: str
    term: str = ""
    kind: str = "definition"      # "definition" | "cloze"
    page: int = 0
    source: str = ""              # kaynak cumle
    image_url: str = ""           # sonradan eklenen gorsel (varsa)
    image_label: str = ""

    def to_dict(self) -> dict:
        return {
            "front": self.front, "back": self.back, "term": self.term,
            "kind": self.kind, "page": self.page, "source": self.source,
            "image_url": self.image_url, "image_label": self.image_label,
        }


@dataclass
class QuizQuestion:
    question: str
    options: List[str]
    answer_index: int
    term: str = ""
    page: int = 0
    kind: str = "definition"      # "definition" | "cloze"

    def to_dict(self) -> dict:
        return {
            "question": self.question, "options": self.options,
            "answer_index": self.answer_index, "term": self.term,
            "page": self.page, "kind": self.kind,
        }


@dataclass
class TermHit:
    """Bir terimin bir sayfadaki en iyi (en 'tanim gibi') cumlesi."""
    term: str
    page: int
    sentence: str
    score: float


# --------------------------------------------------------------------------- #
# Cumle bolutleme
# --------------------------------------------------------------------------- #
def split_sentences(text: str) -> List[str]:
    """
    Metni cumlelere ayirir. Nokta/soru/unlem + bosluk + buyuk harf sinirindan
    boler; ondalik sayilar ve bilinen kisaltmalar (Fig., ed., p. ...) korunur.
    """
    if not text:
        return []
    # Fazla bosluklari sadelestir
    text = re.sub(r"\s+", " ", text).strip()

    out: List[str] = []
    buf: List[str] = []
    tokens = text.split(" ")
    for i, tok in enumerate(tokens):
        buf.append(tok)
        if tok and tok[-1] in ".!?":
            core = tok[:-1].lower().strip(".")
            # Kisaltma veya tek harf -> cumle sonu sayma
            if core in _ABBREV or len(core) <= 1:
                continue
            # Ondalik (sayi.) -> cumle sonu sayma
            if core.isdigit():
                continue
            # Sonraki kelime kucuk harfle basliyorsa muhtemelen cumle bitmedi
            nxt = tokens[i + 1] if i + 1 < len(tokens) else ""
            if nxt and nxt[:1].islower():
                continue
            out.append(" ".join(buf).strip())
            buf = []
    if buf:
        out.append(" ".join(buf).strip())
    return [s for s in out if s]


def _alpha_ratio(s: str) -> float:
    if not s:
        return 0.0
    letters = sum(ch.isalpha() or ch.isspace() for ch in s)
    return letters / len(s)


def _digit_ratio(s: str) -> float:
    if not s:
        return 1.0
    return sum(ch.isdigit() for ch in s) / len(s)


def is_good_sentence(s: str) -> bool:
    """Karta/quize uygun, gurultusuz bir cumle mi?"""
    n = len(s)
    if n < 40 or n > 320:
        return False
    words = s.split()
    if len(words) < 6:
        return False
    if _alpha_ratio(s) < 0.62 or _digit_ratio(s) > 0.22:
        return False
    if not s[:1].isalpha():
        return False
    # Tamamen BUYUK HARF basliklari ele
    letters = [ch for ch in s if ch.isalpha()]
    if letters and sum(ch.isupper() for ch in letters) / len(letters) > 0.6:
        return False
    # Figur/tablo altyazilari ve kaynakca satirlari ele
    low = s.lower()
    if low.startswith(("fig", "figure", "table", "tablo", "şekil", "sekil",
                       "see ", "bkz", "source", "credit")):
        return False
    return True


# --------------------------------------------------------------------------- #
# Terim - cumle eslestirme
# --------------------------------------------------------------------------- #
def _find_surface(sentence: str, term: str, threshold: float = 0.82
                  ) -> Optional[Tuple[str, int, int]]:
    """
    Cumle icinde verilen terimin yuzey bicimini bulur.
    Tek veya cok kelimelik terimleri destekler.
    Donus: (kelime/kelimeler, baslangic_idx, bitis_idx) ya da None.
    """
    term_parts = term.lower().split()
    s_words = list(_WORD_TOKEN.finditer(sentence))

    if len(term_parts) == 1:
        q_raw = "".join(ch for ch in term.lower() if ch.isalpha())
        q_stem = ocr.latin_stem(q_raw)
        for m in s_words:
            tok = m.group(0)
            cw = tok.lower()
            if max(ocr.similarity(q_raw, cw),
                   ocr.similarity(q_stem, ocr.latin_stem(cw))) >= threshold:
                return tok, m.start(), m.end()
        return None

    # Cok kelimelik: arka arkaya gelen kelime dizisini bul
    for i in range(len(s_words) - len(term_parts) + 1):
        chunk = s_words[i:i + len(term_parts)]
        all_match = True
        for tw, cm in zip(term_parts, chunk):
            cw = cm.group(0).lower()
            q_raw = "".join(ch for ch in tw if ch.isalpha())
            q_stem = ocr.latin_stem(q_raw)
            if max(ocr.similarity(q_raw, cw),
                   ocr.similarity(q_stem, ocr.latin_stem(cw))) < threshold:
                all_match = False
                break
        if all_match:
            tok = sentence[chunk[0].start():chunk[-1].end()]
            return tok, chunk[0].start(), chunk[-1].end()
    return None


def _definition_score(sentence: str, term: str, pos: int) -> float:
    """Bir cumlenin verilen terim icin 'tanim gibi' olma puani."""
    low = sentence.lower()
    score = 0.0
    # Terim cumlenin basina yakinsa daha iyi (tanimlar genelde "X, ...dir")
    rel = pos / max(1, len(sentence))
    if rel > 0.55:
        score -= 0.35   # terim cumlenin sonunda geciyorsa — ozne degil, yan anlam
    else:
        score += max(0.0, 0.5 - rel)
    # Terim ilk kelimeyse ek bonus (en guvenilir tanim ozne=terim cumleleridir)
    if pos <= len(term) + 3:
        score += 0.25
    # Tanim baglaci/yuklemi — terim erken geliyorsa daha guvenilir
    if any(cue in low for cue in _DEFINITION_CUES):
        score += 0.4 if rel < 0.45 else 0.1
    # Orta uzunluk en iyi (ne cok kisa ne cok uzun)
    n = len(sentence)
    score += 0.3 * (1.0 - abs(n - 150) / 200.0)
    return score


def extract_term_hits(
    pages_data: Sequence[Tuple[int, str, list]],
    dictionary: Sequence[str],
    detect_threshold: float = 0.84,
) -> List[TermHit]:
    """
    Sayfa verilerinden, sozlukteki her terim icin en iyi tanim cumlesini bulur.
    Terim basina (tum aralikta) tek en iyi cumle tutulur.
    """
    best: Dict[str, TermHit] = {}

    for page, text, words in pages_data:
        if not text:
            continue
        # Bu sayfada gercekten gecen sozluk terimleri (bulanik/govde ile)
        present: List[str] = []
        if words:
            matches = ocr.detect_dictionary_terms(
                words, list(dictionary), threshold=detect_threshold
            )
            seen = set()
            for m in matches:
                t = m.query.lower()
                if t not in seen:
                    seen.add(t)
                    present.append(m.query)
        else:
            low = text.lower()
            present = [t for t in dictionary if t.lower() in low]

        if not present:
            continue

        sentences = [s for s in split_sentences(text) if is_good_sentence(s)]
        if not sentences:
            continue

        for term in present:
            best_sent, best_sc = None, -1.0
            for s in sentences:
                surf = _find_surface(s, term)
                if not surf:
                    continue
                sc = _definition_score(s, term, surf[1])
                if sc > best_sc:
                    best_sc, best_sent = sc, s
            if best_sent is None:
                continue
            prev = best.get(term.lower())
            if prev is None or best_sc > prev.score:
                best[term.lower()] = TermHit(term.lower(), page, best_sent, best_sc)

    hits = list(best.values())
    hits.sort(key=lambda h: h.score, reverse=True)
    return hits


# --------------------------------------------------------------------------- #
# Bilgi karti uretimi
# --------------------------------------------------------------------------- #
def _make_cloze(sentence: str, term: str) -> Optional[str]:
    """Cumlede terimi '_____' ile gizleyerek cloze on yuzu uretir."""
    surf = _find_surface(sentence, term)
    if not surf:
        return None
    _, a, b = surf
    return sentence[:a] + "_____" + sentence[b:]


_DEFAULT_PATTERNS = [
    "«{t}» nedir?",
    "«{t}» nasil tanimlanir?",
    "«{t}» ne anlama gelir?",
    "«{t}»nin temel tanimi nedir?",
    "«{t}» hakkinda ne bilinir?",
]

# Cumle icerigine gore dinamik soru secimi — soru, cevap cumlesini dogal olarak karsilayacak sekilde belirlenir.
def _choose_question_pattern(sentence: str, term: str) -> str:
    s = sentence.lower()
    # Konum / lokasyon
    if any(p in s for p in ["located", "found in", "lies in", "situated", "is in the", "at the", "within the", "runs through"]):
        return "«{t}» nerede bulunur?"
    # Islevselli / rol
    if any(p in s for p in ["provides", "supplies", "innervates", "produces", "secretes", "allows", "enables", "function", "responsible for", "plays a role"]):
        return "«{t}»nin islevi ya da rolu nedir?"
    # Yapi / bilesen
    if any(p in s for p in ["consists of", "composed of", "contains", "made of", "formed by", "divided into", "branches"]):
        return "«{t}» nelerden olusur?"
    # Ust + ozellik (en uzun, en buyuk...)
    if any(p in s for p in ["longest", "largest", "smallest", "strongest", "most", "only", "unique", "major", "primary"]):
        return "«{t}» ile ilgili onemli ozellik nedir?"
    # Klinik
    if any(p in s for p in ["disease", "injury", "fracture", "damage", "disorder", "syndrome", "condition", "lesion", "rupture"]):
        return "«{t}» ile iliskili klinik durum nedir?"
    # Iliski / baglanti
    if any(p in s for p in ["attached to", "related to", "adjacent", "connects", "joins", "articulates"]):
        return "«{t}» hangi yapiyla iliskilidir?"
    # Varsayilan: terme gore karma kaliplardan sec
    return _DEFAULT_PATTERNS[abs(hash(term)) % len(_DEFAULT_PATTERNS)]


def generate_flashcards(
    pages_data: Sequence[Tuple[int, str, list]],
    dictionary: Sequence[str],
    max_cards: int = 40,
    include_cloze: bool = True,
) -> List[Flashcard]:
    """
    Sayfa araligindan terim-tanim ve cloze bilgi kartlari uretir.

    Her terim icin: 1 tanim karti (on: "«terim» nedir?", arka: kaynak cumle)
    ve istege bagli 1 cloze karti (on: bosluklu cumle, arka: terim).
    """
    hits = extract_term_hits(pages_data, dictionary)
    cards: List[Flashcard] = []
    for h in hits:
        term_disp = h.term.capitalize()
        _pat = _choose_question_pattern(h.sentence, h.term)
        cards.append(Flashcard(
            front=_pat.format(t=term_disp),
            back=h.sentence,
            term=h.term, kind="definition", page=h.page, source=h.sentence,
        ))
        if include_cloze:
            cloze = _make_cloze(h.sentence, h.term)
            if cloze and cloze != h.sentence:
                cards.append(Flashcard(
                    front=cloze,
                    back=term_disp,
                    term=h.term, kind="cloze", page=h.page, source=h.sentence,
                ))
        if len(cards) >= max_cards:
            break
    return cards[:max_cards]


# --------------------------------------------------------------------------- #
# Quiz / test uretimi
# --------------------------------------------------------------------------- #
def _snippet(sentence: str, max_len: int = 140) -> str:
    """Tanim cumlesini secenek olarak kullanmak uzere kisaltir."""
    s = sentence.strip()
    if len(s) <= max_len:
        return s
    cut = s[:max_len].rsplit(" ", 1)[0]
    return cut + "…"


def generate_quiz(
    pages_data: Sequence[Tuple[int, str, list]],
    dictionary: Sequence[str],
    n_questions: int = 10,
    seed: int = 1234,
) -> List[QuizQuestion]:
    """
    Coktan secmeli test uretir. Iki soru tipi donusumlu kullanilir:
      * "definition": "«terim» asagidakilerden hangisidir?" -> dogru tanim
        cumlesi + diger terimlerin tanimlarindan 3 celdirici.
      * "cloze": bosluklu cumle -> dogru terim + 3 baska terim (celdirici).
    """
    rng = random.Random(seed)
    hits = extract_term_hits(pages_data, dictionary)
    if len(hits) < 2:
        return []
    # Sadece 2-3 terim varsa yalnizca cloze tipi sorular uret (distractors icin terim yeterli)
    min_distractors = min(3, len(hits) - 1)

    term_snip: Dict[str, str] = {h.term: _snippet(h.sentence) for h in hits}
    all_terms = [h.term for h in hits]

    questions: List[QuizQuestion] = []
    for h in hits:
        if len(questions) >= n_questions:
            break
        others = [t for t in all_terms if t != h.term]
        rng.shuffle(others)

        distract = [term_snip[t] for t in others[:min_distractors]]
        if len(distract) < min_distractors:
            continue
        correct = _snippet(h.sentence)
        options = distract + [correct]
        rng.shuffle(options)
        questions.append(QuizQuestion(
            question=f"«{h.term.capitalize()}» ile ilgili dogru aciklama hangisidir?",
            options=options,
            answer_index=options.index(correct),
            term=h.term, page=h.page, kind="definition",
        ))

    return questions[:n_questions]
