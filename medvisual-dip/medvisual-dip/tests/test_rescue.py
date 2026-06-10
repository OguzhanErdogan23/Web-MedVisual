"""MedVisual kurtarma plani testleri."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from dip.ocr import Word, match_term, detect_dictionary_terms
from dip.cards import _find_surface, _make_cloze, split_sentences

# ---------------------------------------------------------------------------
# Task 1: Multi-word term matching
# ---------------------------------------------------------------------------

def _make_words(texts):
    """Test icin basit Word listesi uretici."""
    words = []
    x = 0
    for t in texts:
        words.append(Word(text=t, x=x, y=100, w=60, h=20, conf=95.0))
        x += 70
    return words

def test_multiword_term_match_single_page():
    """'sulcus cerebri' iki kelime olarak sayfada varsa eslesmeli."""
    words = _make_words(["The", "sulcus", "cerebri", "is", "a", "groove"])
    matches = detect_dictionary_terms(words, ["sulcus cerebri"], threshold=0.82)
    assert len(matches) > 0, "Multi-word terim eslesmedi!"
    assert matches[0].query.lower() == "sulcus cerebri"

def test_multiword_term_find_surface():
    """_find_surface multi-word terimi cumlede bulabilmeli."""
    sentence = "The sulcus cerebri is a groove on the cortex surface."
    result = _find_surface(sentence, "sulcus cerebri")
    assert result is not None, "_find_surface multi-word terimi bulamadi!"
    tok, start, end = result
    assert "sulcus" in tok.lower() or "cerebri" in tok.lower()

def test_multiword_cloze():
    """Multi-word terimle cloze kart uretilebilmeli."""
    sentence = "The sulcus cerebri is a groove on the cortex surface."
    cloze = _make_cloze(sentence, "sulcus cerebri")
    assert cloze is not None
    assert "_____" in cloze
    assert "sulcus" not in cloze.lower() or "cerebri" not in cloze.lower()

# ---------------------------------------------------------------------------
# Task 4: MCQ az terimle çalışmalı
# ---------------------------------------------------------------------------
from dip.cards import generate_quiz

def test_quiz_works_with_two_terms():
    """2 terim varsa en az 1 soru üretilmeli (boş değil)."""
    pages_data = [
        (1,
         "The femur is the thigh bone, the longest bone in the body. "
         "The tibia is the main lower leg bone articulating with the femur.",
         [])
    ]
    questions = generate_quiz(pages_data, ["femur", "tibia"], n_questions=5)
    # 2 terimle en az 1 soru gelmeli (eski kod [] döndürüyordu)
    assert len(questions) >= 1, f"2 terimle quiz üretilemedi, dönen: {questions}"

# ---------------------------------------------------------------------------
# Task 2: Health check endpoint
# ---------------------------------------------------------------------------
import json

def _make_test_client():
    """Flask test istemcisi."""
    import sys
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
    import app as flask_app
    flask_app.app.config["TESTING"] = True
    return flask_app.app.test_client()

def test_health_endpoint_returns_status():
    """GET /api/health JSON dönmeli, tesseract/poppler durumu içermeli."""
    client = _make_test_client()
    resp = client.get("/api/health")
    assert resp.status_code == 200
    data = json.loads(resp.data)
    assert "tesseract" in data
    assert "pdftotext" in data
    assert "dictionary_size" in data
    assert isinstance(data["dictionary_size"], int)

# ---------------------------------------------------------------------------
# Task 6: LLM enhance modülü
# ---------------------------------------------------------------------------
from dip.llm_enhance import enhance_flashcard, is_llm_available
from dip.cards import Flashcard

def test_llm_available_returns_bool():
    """is_llm_available() bool dönmeli, exception vermemeli."""
    result = is_llm_available()
    assert isinstance(result, bool)

def test_enhance_flashcard_fallback_without_api_key(monkeypatch):
    """API anahtarı yoksa orijinal kart döndürülmeli (exception yok)."""
    monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
    card = Flashcard(
        front="«Femur» nedir / neresidir?",
        back="The femur is the longest bone in the human body.",
        term="femur", kind="definition", page=1,
    )
    result = enhance_flashcard(card)
    # Fallback: aynı kart döner
    assert result.term == card.term
    assert result.back == card.back
