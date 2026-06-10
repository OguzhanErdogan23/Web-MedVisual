"""
llm_enhance.py
--------------
Google Gemini (google-genai SDK) ile istege bagli kart/quiz zenginlestirme.
NotebookLM kalitesinde Turkce tip egitim icerigi uretir.

GOOGLE_API_KEY ortam degiskeni yoksa ya da hata olusursa
orijinal kart/soru sessizce doner (offline fallback).
"""
from __future__ import annotations

import json
import os
import random
from typing import List, Optional

from .cards import Flashcard, QuizQuestion

MODEL = os.environ.get("GEMINI_MODEL", "gemini-2.0-flash")

_CARD_SYSTEM = (
    "Sen deneyimli bir Turk tip egitimcisisin. "
    "PDF'den cikarilan ham tibbi metinleri, tip ogrencileri icin "
    "etkili, kaynak-sadik Turkce flashcard'lara donusturuyorsun. "
    "NotebookLM kalitesinde: net, ogretici, klinik baglamli."
)

_CARD_PROMPT = """\
Terim: {term}
Kaynak metin (PDF'den ham cumle): {source}

Asagidaki JSON formatinda bir flashcard uret:
{{
  "front": "Ogrenciyi dusunduren, spesifik Turkce soru — 'X nedir?' YAPMA, daha ozgun ol (orn: klinik onemi, mekanizmasi, nasil calisir)",
  "back": "Net, ogretici Turkce tanim — 1-3 cumle. Su sirada: (1) kisa tanim, (2) varsa klinik/pratik onem. Teknik terim ilk kullanimda parantez ici Ingilizce."
}}

Kurallar:
- Tamamen Turkce yaz
- Arka yuz: kaynak metni aynen KOPYALAMA, anlayarak yeniden yaz
- Klinik senaryo/baglanti varsa mutlaka ekle
- Maksimum 120 kelime arka yuzde
"""

_MCQ_SYSTEM = (
    "Sen tip egitiminde MCQ uzmanisın. "
    "Klinik senaryolu, dusundurucU sorular ve gercekci celdiriciler uretiyorsun. "
    "Celdiriciler ayni anatomik/fizyolojik kategoride, acikca yanlis olmali."
)

_MCQ_PROMPT = """\
Terim: {term}
Dogru bilgi: {correct}
Diger mevcut terimler (celdirici fikri icin): {others}

Asagidaki JSON formatinda MCQ uret:
{{
  "question": "Klinik baglamli Turkce soru — mumkunse kisa bir vaka senaryosu ekle",
  "correct": "Dogru cevap metni (kisa, net)",
  "distractors": ["yanlis 1 (ayni kategori, dusundurucU)", "yanlis 2", "yanlis 3"]
}}

Kurallar:
- Tamamen Turkce
- Soru: 'Hangisi dogrudur?' YAPMA, daha spesifik ol
- Celdiriciler: gercek tip terimleri, ayni kategoride, plausible ama yanlis
- Dogru cevap celdiriciyle karistirilabilir olmali (zor soru)
"""

_BATCH_PROMPT = """\
Asagidaki {n} adet tip terimi icin toplu flashcard uret.
Terimler birbiriyle iliskili olabilir — bu baglamlari kullan.

Terimler ve kaynak metinler:
{terms_json}

SADECE bir JSON listesi dondur, baska hicbir sey yazma:
[
  {{
    "term": "terim_adi",
    "front": "Spesifik Turkce soru",
    "back": "Net, klinik Turkce tanim (1-3 cumle)"
  }}
]

Her terim icin ayri bir kart uret. Tamamen Turkce.
"""


def is_llm_available() -> bool:
    """GOOGLE_API_KEY tanimli mi ve google.genai paketi kurulu mu?"""
    try:
        from google import genai  # noqa: F401
        return bool(os.environ.get("GOOGLE_API_KEY"))
    except ImportError:
        return False


def _make_client():
    """google.genai.Client ornegi dondurur; kullanilamiyorsa None."""
    if not is_llm_available():
        return None
    try:
        from google import genai
        return genai.Client(api_key=os.environ["GOOGLE_API_KEY"])
    except Exception:
        return None


_MAX_RETRIES = 3
_BASE_WAIT = 2.0


def _generate(client, prompt: str, system: str = "") -> Optional[str]:
    """Gemini cagrisi yapar; 429 icin exponential backoff uygular."""
    try:
        from google.genai import types
        import time

        config = types.GenerateContentConfig(
            temperature=0.4,
            max_output_tokens=1024,
            response_mime_type="application/json",
            system_instruction=system if system else None,
        )

        for attempt in range(_MAX_RETRIES):
            try:
                response = client.models.generate_content(
                    model=MODEL,
                    contents=prompt,
                    config=config,
                )
                return response.text
            except Exception as e:
                err_str = str(e).lower()
                if "429" in err_str or "resource_exhausted" in err_str or "quota" in err_str:
                    if attempt < _MAX_RETRIES - 1:
                        wait = _BASE_WAIT * (2 ** attempt)
                        time.sleep(wait)
                        continue
                if attempt < _MAX_RETRIES - 1:
                    time.sleep(1.0)
                    continue
        return None
    except Exception:
        return None


def enhance_flashcard(card: Flashcard) -> Flashcard:
    """
    Bir definition kartinin on/arka yuzunu Gemini ile ogrenci dostu Turkce tanima donusturur.
    Basarisiz olursa orijinal karti dondurur.
    """
    if card.kind != "definition":
        return card
    client = _make_client()
    if not client:
        return card

    prompt = _CARD_PROMPT.format(
        term=card.term,
        source=card.source or card.back,
    )
    text = _generate(client, prompt, system=_CARD_SYSTEM)
    if not text:
        return card

    try:
        data = json.loads(text)
        new_front = str(data.get("front", "")).strip()
        new_back = str(data.get("back", "")).strip()
        if not new_front or not new_back:
            return card
        return Flashcard(
            front=new_front,
            back=new_back,
            term=card.term,
            kind=card.kind,
            page=card.page,
            source=card.source,
            image_url=card.image_url,
            image_label=card.image_label,
        )
    except Exception:
        return card


def enhance_cards_batch(
    cards: List[Flashcard],
    max_enhance: int = 20,
) -> List[Flashcard]:
    """
    Kart listesini toplu zenginlestirir.
    Definition kartlari Gemini ile islenir; cloze kartlar aynen kalir.
    Toplu islem: iliskili kartlari birlikte gondererek baglamsal kalite arttirilir.
    """
    client = _make_client()
    if not client:
        return cards

    def_cards = [(i, c) for i, c in enumerate(cards)
                 if c.kind == "definition"][:max_enhance]
    if not def_cards:
        return cards

    BATCH_SIZE = 8
    result = list(cards)

    for batch_start in range(0, len(def_cards), BATCH_SIZE):
        batch = def_cards[batch_start:batch_start + BATCH_SIZE]
        terms_data = [
            {"term": c.term, "source": c.source or c.back}
            for _, c in batch
        ]

        prompt = _BATCH_PROMPT.format(
            n=len(batch),
            terms_json=json.dumps(terms_data, ensure_ascii=False, indent=2),
        )
        text = _generate(client, prompt, system=_CARD_SYSTEM)

        if text:
            try:
                enhanced_list = json.loads(text)
                if not isinstance(enhanced_list, list):
                    raise ValueError("liste beklendi")
                enhanced_map = {
                    str(item.get("term", "")).lower(): item
                    for item in enhanced_list
                    if isinstance(item, dict)
                }
                for orig_idx, orig_card in batch:
                    item = enhanced_map.get(orig_card.term.lower())
                    if not item:
                        continue
                    new_front = str(item.get("front", "")).strip()
                    new_back = str(item.get("back", "")).strip()
                    if new_front and new_back:
                        result[orig_idx] = Flashcard(
                            front=new_front,
                            back=new_back,
                            term=orig_card.term,
                            kind=orig_card.kind,
                            page=orig_card.page,
                            source=orig_card.source,
                            image_url=orig_card.image_url,
                            image_label=orig_card.image_label,
                        )
                continue
            except Exception:
                pass

        # Toplu islem basarisiz: tek tek dene
        for orig_idx, orig_card in batch:
            result[orig_idx] = enhance_flashcard(orig_card)

    return result


def enhance_quiz_question(q: QuizQuestion, all_terms: Optional[List[str]] = None) -> QuizQuestion:
    """
    Bir MCQ sorusunu Gemini ile iyilestirir: klinik senaryo + daha iyi celdiriciler.
    Basarisiz olursa orijinal soruyu dondurur.
    """
    client = _make_client()
    if not client:
        return q

    others_preview = ", ".join((all_terms or [])[:6])
    correct_text = q.options[q.answer_index] if q.options else ""
    prompt = _MCQ_PROMPT.format(
        term=q.term,
        correct=correct_text,
        others=others_preview or "yok",
    )
    text = _generate(client, prompt, system=_MCQ_SYSTEM)
    if not text:
        return q

    try:
        data = json.loads(text)
        distractors = data.get("distractors", [])
        new_question = str(data.get("question", "")).strip()
        new_correct = str(data.get("correct", "")).strip()

        if not new_question or not new_correct or len(distractors) < 2:
            return q

        options = distractors[:3] + [new_correct]
        rng = random.Random(hash(q.term))
        rng.shuffle(options)

        return QuizQuestion(
            question=new_question,
            options=options,
            answer_index=options.index(new_correct),
            term=q.term,
            page=q.page,
            kind=q.kind,
        )
    except Exception:
        return q


def enhance_quiz_batch(
    questions: List[QuizQuestion],
    max_enhance: int = 10,
) -> List[QuizQuestion]:
    """Quiz sorularini toplu zenginlestirir."""
    all_terms = [q.term for q in questions]
    result = []
    enhanced = 0
    for q in questions:
        if enhanced < max_enhance and is_llm_available():
            result.append(enhance_quiz_question(q, all_terms=all_terms))
            enhanced += 1
        else:
            result.append(q)
    return result
