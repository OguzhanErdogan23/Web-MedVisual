"""Gemini zenginlestirme — MODEL FALLBACK ZINCIRI (backend tarafinda).

DIP motoruna DOKUNULMADAN, DIP'in urettigi offline kart/quiz'leri Gemini ile
klinik Turkce kalitesine yukseltir. Birden fazla model sirayla denenir; biri
kota (429) veya hata verirse otomatik bir sonrakine gecilir.

Model zinciri GEMINI_MODELS env'inden (virgulle) okunur; bos ise varsayilan
kullanilir. GOOGLE_API_KEY gerekir (DIP ile ayni anahtar kullanilabilir).
"""
import json
import os
from typing import List, Optional, Tuple

DEFAULT_MODELS = [
    "gemini-3-flash-preview",
    "gemini-2.5-flash",
    "gemini-2.5-flash-lite",
    "gemini-flash-lite-latest",
    "gemini-2.0-flash-lite",
    "gemini-2.0-flash",
]


def model_chain() -> List[str]:
    raw = os.environ.get("GEMINI_MODELS", "").strip()
    if raw:
        return [m.strip() for m in raw.split(",") if m.strip()]
    return DEFAULT_MODELS


def is_available() -> bool:
    if not os.environ.get("GOOGLE_API_KEY"):
        return False
    try:
        import google.genai  # noqa: F401
        return True
    except ImportError:
        return False


def _client():
    from google import genai
    return genai.Client(api_key=os.environ["GOOGLE_API_KEY"])


def _is_quota(err: Exception) -> bool:
    s = str(err).lower()
    return "429" in s or "resource_exhausted" in s or "quota" in s


def _generate(prompt: str, system: str, max_tokens: int = 2048) -> Tuple[Optional[str], Optional[str]]:
    """Model zincirini sirayla dener. -> (yanit_metni, kullanilan_model).
    Kota/hata olan modeli atlar; hicbiri olmazsa (None, None)."""
    from google.genai import types

    config = types.GenerateContentConfig(
        temperature=0.4,
        max_output_tokens=max_tokens,
        response_mime_type="application/json",
        system_instruction=system,
    )
    try:
        client = _client()
    except Exception:
        return None, None

    for model in model_chain():
        try:
            resp = client.models.generate_content(model=model, contents=prompt, config=config)
            if resp.text and resp.text.strip():
                return resp.text, model
        except Exception as e:
            if _is_quota(e):
                continue  # kota dolu -> sonraki modeli dene
            continue      # gecersiz model adi / gecici hata -> sonraki
    return None, None


def _parse_list(raw: str) -> Optional[list]:
    try:
        data = json.loads(raw)
        return data if isinstance(data, list) else None
    except (json.JSONDecodeError, ValueError):
        return None


# --------------------------------------------------------------------------- #
# KARTLAR
# --------------------------------------------------------------------------- #
_CARD_SYSTEM = (
    "Sen deneyimli bir Turk tip egitimcisisin. Ogrencilere anatomi ve klinik "
    "bilgileri pekistirten, ANATOMICARDS kalitesinde Turkce bilgi kartlari "
    "hazirliyorsun. Soru ve cevap %100 birbiriyle tutarli olmali."
)

_CARD_PROMPT = """Asagida bir tip dokumanindan cikarilmis ham bilgi kartlari var
(soru-cevap kalitesi dusuk, bazilari tekrar veya eksik). Bunlari kullanarak
EN FAZLA {n} adet YUKSEK KALITELI Turkce bilgi karti uret.

Kurallar:
- Her kart net bir soru (front) ve net, dogru, oz bir cevap (back) icermeli.
- Soru-cevap birebir eslesmeli; alakasiz/uzun metin yapistirma.
- Ayni terimi tekrar eden kartlari BIRLESTIR, mukerrer uretme.
- Latince/anatomik terimi koru ("term" alani).
- Cevaplar Turkce olsun; Latince terimler parantez icinde kalabilir.
- Mumkunse klinik baglam ekle (komplikasyon, islev, iliski).
- Cikti SADECE JSON listesi: [{{"front":"...","back":"...","term":"...","page":N}}]

Ham kartlar (JSON):
{cards}
"""


def enhance_cards(cards: List[dict], max_cards: int = 40) -> Tuple[Optional[List[dict]], Optional[str]]:
    """Offline kartlari Gemini ile iyilestirir. -> (kartlar, kullanilan_model)
    veya (None, None) hicbir model calismadiysa."""
    if not cards:
        return None, None
    raw_in = json.dumps(
        [{"front": c.get("front", ""), "back": c.get("back", ""),
          "term": c.get("term", ""), "page": c.get("page")} for c in cards],
        ensure_ascii=False,
    )
    prompt = _CARD_PROMPT.format(n=min(max_cards, len(cards)), cards=raw_in[:8000])
    raw, model = _generate(prompt, _CARD_SYSTEM, max_tokens=2600)
    if not raw:
        return None, None
    items = _parse_list(raw)
    if not items:
        return None, None
    out = []
    for it in items:
        if not isinstance(it, dict):
            continue
        front = str(it.get("front", "")).strip()
        back = str(it.get("back", "")).strip()
        if not front or not back:
            continue
        out.append({
            "front": front, "back": back,
            "term": str(it.get("term", "")).strip().lower() or None,
            "page": it.get("page"), "kind": "gemini",
        })
    return (out or None), (model if out else None)


# --------------------------------------------------------------------------- #
# QUIZ
# --------------------------------------------------------------------------- #
_QUIZ_SYSTEM = (
    "Sen deneyimli bir Turk tip egitimcisisin. Coktan secmeli sinav sorulari "
    "hazirliyorsun. Sorular net, celdiriciler (yanlis siklar) makul ama "
    "birbirinden FARKLI olmali; ASLA ayni metni iki sikta tekrar etme."
)

_QUIZ_PROMPT = """Asagida ham coktan secmeli sorular var (bazilarinda siklar
ayni veya celdiriciler zayif). Bunlari kullanarak EN FAZLA {n} adet YUKSEK
KALITELI Turkce MCQ uret.

Kurallar:
- Her soru net olsun; tam 4 sik olsun, hepsi BIRBIRINDEN FARKLI.
- Tek bir dogru sik olsun; "answer_index" 0-3 araliginda dogru siki gostersin.
- Celdiriciler konuyla alakali ama yanlis olsun (rastgele cumle yapistirma).
- Cevaplar Turkce; Latince terimler korunabilir.
- Cikti SADECE JSON: [{{"question":"...","options":["A","B","C","D"],"answer_index":N}}]

Ham sorular (JSON):
{questions}
"""


def enhance_quiz(questions: List[dict], n_questions: int = 10) -> Tuple[Optional[List[dict]], Optional[str]]:
    if not questions:
        return None, None
    raw_in = json.dumps(
        [{"question": q.get("question", ""), "options": q.get("options", []),
          "answer_index": q.get("answer_index", 0)} for q in questions],
        ensure_ascii=False,
    )
    prompt = _QUIZ_PROMPT.format(n=min(n_questions, len(questions)), questions=raw_in[:8000])
    raw, model = _generate(prompt, _QUIZ_SYSTEM, max_tokens=2600)
    if not raw:
        return None, None
    items = _parse_list(raw)
    if not items:
        return None, None
    out = []
    for it in items:
        if not isinstance(it, dict):
            continue
        q = str(it.get("question", "")).strip()
        opts = it.get("options", [])
        if not q or not isinstance(opts, list) or len(opts) < 2:
            continue
        opts = [str(o).strip() for o in opts][:4]
        if len(set(opts)) < len(opts):  # mukerrer sik -> bu soruyu at
            continue
        ai = int(it.get("answer_index", 0))
        ai = ai if 0 <= ai < len(opts) else 0
        out.append({"question": q, "options": opts, "answer_index": ai})
    return (out or None), (model if out else None)
