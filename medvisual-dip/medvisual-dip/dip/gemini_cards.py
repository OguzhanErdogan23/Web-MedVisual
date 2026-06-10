"""
gemini_cards.py
---------------
Google Gemini ile birincil kart/quiz uretimi — NotebookLM yaklasimi.
Anatomicards stilinde cesitli, klinik odakli sorular uretir.
429 hatalari icin exponential backoff uygulanir.
"""
from __future__ import annotations

import json
import os
import time
from typing import List, Optional, Sequence, Tuple

from .cards import Flashcard, QuizQuestion

MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")

_CARD_SYSTEM = """Sen deneyimli bir Turk tip egitimcisisin. Ogrencilerin anatomi ve klinik bilgilerini pekistirmeleri icin ANATOMICARDS kalitesinde Turkce bilgi kartlari uretiyorsun.

SORU CESITLILIGI - asagidaki tipler arasindan sec:
1. Klinik komplikasyon: "X kiriginda hangi sinir/damar zedelenir?"
2. Anatomik origo/insertiyo: "X kasinin origo noktasi neresidir?"
3. Klinik durum adi: "X yaralanmasi sonucu hangi deformite olusur?"
4. Mekanizma: "X hastaligi nasil gelisir?" / "X nasil olusur?"
5. Karsilastirma: "X ile Y arasindaki temel fark nedir?"
6. Siralama/liste: "X'den gecen yapilari sirala"
7. Bosluk doldurma: "X kiriginda _____ siniri yaralanir."
8. Klinik test: "X testi hangi yapinin butunlugunu degerlendirir?"

KURALLAR:
- Soru VE cevap AYNI konuyu islemeli (Q&A mismatch KABUL EDILMEZ)
- "X nedir?" veya "X neresidir?" gibi jenerik sorular YAZMA
- Her soru spesifik, klinik veya anatomik bir noktayi test etmeli
- Cevap: kisa, net, 1-2 cumle maximum
- Tamamen Turkce; teknik terim ilk kullanimda parantez ici Ingilizce
- Ayni tip soruyu arka arkaya tekrarlama (cesitlilik zorunlu)"""

_CARD_PROMPT = """Asagidaki tip metni {page}. sayfadan alinmistir.

METIN:
{text}

Bu metinden TAM OLARAK {n_cards} adet bilgi karti uret.
Oncelikli terimler: {terms_hint}

Her soru FARKLI bir soru tipinde olmali (komplikasyon, origo, deformite adi, mekanizma vb.)
Ayni tip soruyu arka arkaya TEKRARLAMA.
Soru ile cevap %100 eslesmeli.

SADECE JSON listesi dondur:
[
  {{"term": "terim_adi", "front": "Spesifik klinik/anatomik soru?", "back": "Kisa dogru cevap.", "page": {page}}},
  ...
]"""

_QUIZ_SYSTEM = """Sen tip egitiminde MCQ (coktan secmeli) uzmanisın. Anatomicards kalitesinde klinik sorular ve gercekci celdiriciler uretiyorsun."""

_QUIZ_PROMPT = """Asagidaki tip metni {page}. sayfadan:

METIN:
{text}

Bu metinden {n_questions} adet MCQ soru uret. Her soru farkli tipte olsun (komplikasyon, anatomi, klinik test vb.)

SADECE JSON listesi dondur:
[
  {{
    "term": "terim",
    "question": "Spesifik klinik soru?",
    "options": ["Secenek 1", "Secenek 2", "Secenek 3", "Secenek 4"],
    "answer_index": 2,
    "page": {page}
  }}
]"""

_MAX_RETRIES = 3
_BASE_WAIT = 2.0


def is_available() -> bool:
    try:
        from google import genai
        return bool(os.environ.get("GOOGLE_API_KEY"))
    except ImportError:
        return False


def _make_client():
    if not is_available():
        return None
    try:
        from google import genai
        return genai.Client(api_key=os.environ["GOOGLE_API_KEY"])
    except Exception:
        return None


def _call(client, prompt: str, system: str, max_tokens: int = 2048) -> Optional[str]:
    """Gemini cagrisi yapar; 429 icin exponential backoff uygular."""
    from google.genai import types

    config = types.GenerateContentConfig(
        temperature=0.35,
        max_output_tokens=max_tokens,
        response_mime_type="application/json",
        system_instruction=system,
    )

    last_error = None
    for attempt in range(_MAX_RETRIES):
        try:
            response = client.models.generate_content(
                model=MODEL, contents=prompt, config=config,
            )
            return response.text
        except Exception as e:
            last_error = e
            err_str = str(e).lower()
            if "429" in err_str or "resource_exhausted" in err_str or "quota" in err_str:
                wait = _BASE_WAIT * (2 ** attempt)
                time.sleep(wait)
                continue
            # Diger hatalar icin bekle ve tekrar dene
            if attempt < _MAX_RETRIES - 1:
                time.sleep(1.0)
            continue

    return None


def generate_cards(
    pages_data: Sequence[Tuple[int, str, list]],
    dictionary: Sequence[str],
    max_cards: int = 40,
) -> Optional[List[Flashcard]]:
    """Gemini ile birincil kart uretimi. Hata olursa None doner."""
    client = _make_client()
    if not client:
        return None

    usable = [(pg, txt, wds) for pg, txt, wds in pages_data if txt and len(txt.strip()) > 100]
    if not usable:
        return None

    n_pages = len(usable)
    per_page = max(2, min(6, max_cards // max(n_pages, 1)))

    all_cards: List[Flashcard] = []

    for page, text, _ in usable:
        if len(all_cards) >= max_cards:
            break

        words_in_text = set(w.lower() for w in text.split() if len(w) > 3)
        hints = [t for t in dictionary if t.lower() in words_in_text or
                 any(t.lower() in w for w in words_in_text)][:8]
        terms_hint = ", ".join(hints) if hints else "yok"
        text_chunk = text[:3500] if len(text) > 3500 else text

        prompt = _CARD_PROMPT.format(
            page=page,
            text=text_chunk,
            n_cards=per_page,
            terms_hint=terms_hint,
        )

        raw = _call(client, prompt, _CARD_SYSTEM, max_tokens=1200)
        if not raw:
            continue

        try:
            items = json.loads(raw)
            if not isinstance(items, list):
                continue
            for item in items:
                if not isinstance(item, dict):
                    continue
                front = str(item.get("front", "")).strip()
                back = str(item.get("back", "")).strip()
                term = str(item.get("term", "")).strip().lower()
                if not front or not back:
                    continue
                all_cards.append(Flashcard(
                    front=front,
                    back=back,
                    term=term or front[:30].lower(),
                    kind="definition",
                    page=int(item.get("page", page)),
                    source=text_chunk[:200],
                ))
        except (json.JSONDecodeError, ValueError):
            continue

    return all_cards if all_cards else None


def generate_quiz(
    pages_data: Sequence[Tuple[int, str, list]],
    dictionary: Sequence[str],
    n_questions: int = 10,
) -> Optional[List[QuizQuestion]]:
    """Gemini ile MCQ uretimi. Hata olursa None doner."""
    client = _make_client()
    if not client:
        return None

    usable = [(pg, txt, wds) for pg, txt, wds in pages_data if txt and len(txt.strip()) > 100]
    if not usable:
        return None

    n_pages = len(usable)
    per_page = max(2, min(5, n_questions // max(n_pages, 1)))
    all_questions: List[QuizQuestion] = []

    for page, text, _ in usable:
        if len(all_questions) >= n_questions:
            break

        text_chunk = text[:3500] if len(text) > 3500 else text
        prompt = _QUIZ_PROMPT.format(
            page=page,
            text=text_chunk,
            n_questions=per_page,
        )

        raw = _call(client, prompt, _QUIZ_SYSTEM, max_tokens=1800)
        if not raw:
            continue

        try:
            items = json.loads(raw)
            if not isinstance(items, list):
                continue
            for item in items:
                if not isinstance(item, dict):
                    continue
                question = str(item.get("question", "")).strip()
                options = item.get("options", [])
                answer_index = int(item.get("answer_index", 0))
                term = str(item.get("term", "")).strip().lower()

                if not question or not options or len(options) < 2:
                    continue
                if answer_index < 0 or answer_index >= len(options):
                    answer_index = 0

                all_questions.append(QuizQuestion(
                    question=question,
                    options=options,
                    answer_index=answer_index,
                    term=term,
                    page=int(item.get("page", page)),
                    kind="definition",
                ))
        except (json.JSONDecodeError, ValueError, TypeError):
            continue

    return all_questions if all_questions else None
