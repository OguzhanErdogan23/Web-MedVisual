# MedVisual DIP — Kurtarma Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Flashcard uygulamasını çalışır hale getir: kritik bug'ları düzelt, sessiz hataları görünür yap, sözlüğü genişlet, Claude API ile isteğe bağlı LLM kart zenginleştirme ekle.

**Architecture:** Üç katman — (1) bug fix: multi-word eşleşme + diagnostics + UI feedback, (2) sözlük genişletme + MCQ fix, (3) `dip/llm_enhance.py` adlı yeni modül: extractive kartları Claude Haiku ile öğrenci dostu hale getiriyor; API anahtarı yoksa fallback çalışıyor. Flask endpoint'leri `?enhance=1` parametresi ile LLM'i aktive ediyor.

**Tech Stack:** Python/Flask (mevcut), `anthropic` SDK (`claude-haiku-4-5-20251001`), pdftotext/Tesseract (mevcut altyapı)

---

## Dosya Haritası

| Durum | Dosya | Değişiklik |
|-------|-------|------------|
| Modify | `dip/ocr.py` | `detect_dictionary_terms` multi-word term fix; `_find_surface` multi-word span |
| Modify | `dip/cards.py` | `_find_surface` multi-word fix; MCQ min threshold kaldır; scoring iyileştir |
| Modify | `app.py` | `/api/health` endpoint ekle; `/api/generate/cards` ve `/api/generate/quiz`'e `enhance` param |
| Create | `dip/llm_enhance.py` | Claude Haiku ile kart/quiz zenginleştirme; offline fallback |
| Modify | `data/latin_terms.txt` | ~400 ek tıp terimi |
| Modify | `templates/index.html` | "AI Zenginleştir" toggle UI |
| Modify | `static/app.js` | 0 kart mesajı; enhance toggle gönderimi |
| Create | `requirements.txt` | `anthropic>=0.40.0` satırı ekle |
| Create | `tests/test_rescue.py` | Tüm bug fix'lerin testleri |

---

## AŞAMA 1 — Kritik Bug Fix'ler

---

### Task 1: Multi-Word Term Matching Bug'ı Düzelt

**Problem:** `_clean("sulcus cerebri")` → `"sulcuscerebri"`. Herhangi bir tek OCR kelimesiyle similarity < 0.72 → multi-word terimler ASLA eşleşmiyor.

**Files:**
- Modify: `dip/ocr.py` (match_term, detect_dictionary_terms)
- Modify: `dip/cards.py` (_find_surface, _make_cloze)
- Test: `tests/test_rescue.py`

- [ ] **Step 1: Failing testi yaz**

`tests/test_rescue.py` dosyasını oluştur:

```python
"""MedVisual kurtarma planı testleri."""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from dip.ocr import Word, match_term, detect_dictionary_terms
from dip.cards import _find_surface, _make_cloze, split_sentences

# ---------------------------------------------------------------------------
# Task 1: Multi-word term matching
# ---------------------------------------------------------------------------

def _make_words(texts):
    """Test için basit Word listesi üretici."""
    words = []
    x = 0
    for t in texts:
        words.append(Word(text=t, x=x, y=100, w=60, h=20, conf=95.0))
        x += 70
    return words

def test_multiword_term_match_single_page():
    """'sulcus cerebri' iki kelime olarak sayfada varsa eşleşmeli."""
    words = _make_words(["The", "sulcus", "cerebri", "is", "a", "groove"])
    matches = detect_dictionary_terms(words, ["sulcus cerebri"], threshold=0.82)
    assert len(matches) > 0, "Multi-word terim eşleşmedi!"
    assert matches[0].query.lower() == "sulcus cerebri"

def test_multiword_term_find_surface():
    """_find_surface multi-word terimi cümlede bulabilmeli."""
    sentence = "The sulcus cerebri is a groove on the cortex surface."
    result = _find_surface(sentence, "sulcus cerebri")
    assert result is not None, "_find_surface multi-word terimi bulamadı!"
    tok, start, end = result
    assert "sulcus" in tok.lower() or "cerebri" in tok.lower()

def test_multiword_cloze():
    """Multi-word terimle cloze kart üretilebilmeli."""
    sentence = "The sulcus cerebri is a groove on the cortex surface."
    cloze = _make_cloze(sentence, "sulcus cerebri")
    assert cloze is not None
    assert "_____" in cloze
    assert "sulcus" not in cloze.lower() or "cerebri" not in cloze.lower()
```

- [ ] **Step 2: Testi çalıştır — FAIL bekleniyor**

```bash
cd "C:\Users\ogito\Desktop\3 proje\medvisual-dip\medvisual-dip"
venv\Scripts\python -m pytest tests/test_rescue.py::test_multiword_term_match_single_page -v
```

Beklenen: `FAILED — AssertionError: Multi-word terim eşleşmedi!`

- [ ] **Step 3: `dip/ocr.py` içinde `detect_dictionary_terms` fonksiyonunu değiştir**

`dip/ocr.py`'daki mevcut `detect_dictionary_terms` fonksiyonunu bul (satır 172-188) ve şununla değiştir:

```python
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
```

- [ ] **Step 4: `dip/cards.py` içinde `_find_surface` fonksiyonunu güncelle**

`dip/cards.py`'daki mevcut `_find_surface` fonksiyonunu (satır 171-185) bul ve şununla değiştir:

```python
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
```

- [ ] **Step 5: Testi tekrar çalıştır — PASS bekleniyor**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py -v
```

Beklenen: `3 passed`

- [ ] **Step 6: Commit**

```bash
git add dip/ocr.py dip/cards.py tests/test_rescue.py
git commit -m "fix: multi-word dictionary terms now match correctly in OCR and card surface detection"
```

---

### Task 2: Diagnostics (Health Check) Endpoint Ekle

**Problem:** Tesseract / pdftotext PATH'te yoksa uygulama sessizce bozuk çalışıyor. Kullanıcı nedenini göremez.

**Files:**
- Modify: `app.py`
- Test: `tests/test_rescue.py`

- [ ] **Step 1: Failing testi ekle** (`tests/test_rescue.py` sonuna):

```python
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
    # dictionary_size pozitif olmalı (dosya yüklendiyse)
    assert isinstance(data["dictionary_size"], int)
```

- [ ] **Step 2: Testi çalıştır — FAIL bekleniyor**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py::test_health_endpoint_returns_status -v
```

Beklenen: `FAILED — 404`

- [ ] **Step 3: `app.py`'a `/api/health` endpoint ekle**

`app.py`'da `@app.route("/api/terms")` route'unun hemen üstüne şunu ekle:

```python
@app.route("/api/health")
def health():
    """Ortam diagnostigi: Tesseract, pdftotext, sozluk durumu."""
    import shutil

    def _check_exe(name):
        path = shutil.which(name)
        return {"available": path is not None, "path": path or "NOT FOUND"}

    tesseract = _check_exe("tesseract")
    pdftotext = _check_exe("pdftotext")

    # Tesseract versiyon kontrolu
    if tesseract["available"]:
        try:
            import subprocess
            ver = subprocess.run(
                ["tesseract", "--version"],
                capture_output=True, text=True, timeout=5
            ).stdout.splitlines()[0]
            tesseract["version"] = ver
        except Exception:
            tesseract["version"] = "unknown"

    return jsonify({
        "status": "ok",
        "tesseract": tesseract,
        "pdftotext": pdftotext,
        "dictionary_size": len(DICTIONARY),
        "dictionary_path": DICT_PATH,
        "dictionary_loaded": len(DICTIONARY) > 0,
        "work_dir": WORK_DIR,
    })
```

- [ ] **Step 4: Testi çalıştır — PASS bekleniyor**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py::test_health_endpoint_returns_status -v
```

- [ ] **Step 5: Commit**

```bash
git add app.py tests/test_rescue.py
git commit -m "feat: add /api/health diagnostics endpoint for environment checks"
```

---

### Task 3: Sıfır Kart Üretildiğinde Kullanıcıya Anlamlı Mesaj Ver

**Problem:** 0 kart geldiğinde UI sadece boş ekran gösteriyor. Kullanıcı neden göremez.

**Files:**
- Modify: `static/app.js`
- Modify: `app.py` (generate_cards endpoint'ine `reason` alanı ekle)

- [ ] **Step 1: `app.py`'da `generate_cards` fonksiyonuna reason alanı ekle**

`app.py`'daki `generate_cards` fonksiyonunda `return jsonify(...)` bloğunu bul ve şununla değiştir:

```python
    reason = None
    if len(cards) == 0:
        if not DICTIONARY:
            reason = "Terim sözlüğü yüklenemedi. data/latin_terms.txt dosyasını kontrol et."
        else:
            reason = (
                f"Seçilen {len(pages)} sayfada sözlükteki {len(DICTIONARY)} terimden hiçbiri bulunamadı. "
                "Daha geniş bir sayfa aralığı dene veya terimi elle gir."
            )

    return jsonify({
        "doc_id": doc_id,
        "pages": pages, "truncated": truncated, "source": used,
        "count": len(cards),
        "cards": [c.to_dict() for c in cards],
        "reason": reason,
    })
```

- [ ] **Step 2: `static/app.js`'te kart render fonksiyonunu bul ve 0 kart durumunu işle**

`static/app.js` dosyasında kart listesini render eden koda `count === 0` kontrolü ekle. Mevcut kart render döngüsünü bul (genellikle `data.cards.forEach` veya benzeri bir pattern). Döngüden önce şunu ekle:

```javascript
if (data.count === 0) {
    const msg = data.reason || "Bu aralıkta kart üretilemedi.";
    container.innerHTML = `
        <div style="padding:20px;background:#fff3cd;border:1px solid #ffc107;border-radius:8px;margin:10px 0;">
            <strong>⚠ Kart üretilemedi</strong><br>${msg}
            <br><br>
            <small>İpucu: <a href="/api/health" target="_blank">/api/health</a> adresinden ortam durumunu kontrol et.</small>
        </div>`;
    return;
}
```

> Not: `container` değişkeni projenin mevcut JS kodunda kart listesini tutan DOM elemanıdır. `static/app.js` içinde kart listesini dolduran işlevi bul ve yukardaki bloğu uygun yere yerleştir.

- [ ] **Step 3: Commit**

```bash
git add app.py static/app.js
git commit -m "fix: show meaningful error message when 0 cards are generated"
```

---

### Task 4: MCQ'da Minimum 4 Terim Şartını Kaldır

**Problem:** `generate_quiz()` < 4 terim bulursa `[]` döndürüyor. Uyarı yok.

**Files:**
- Modify: `dip/cards.py`
- Test: `tests/test_rescue.py`

- [ ] **Step 1: Failing testi ekle** (`tests/test_rescue.py` sonuna):

```python
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
```

- [ ] **Step 2: Testi çalıştır — FAIL bekleniyor**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py::test_quiz_works_with_two_terms -v
```

Beklenen: `FAILED — AssertionError: 2 terimle quiz üretilemedi`

- [ ] **Step 3: `dip/cards.py`'da `generate_quiz` fonksiyonunu düzelt**

`generate_quiz` fonksiyonunda şu satırı bul:

```python
    if len(hits) < 4:
        return []
```

Bu satırları şununla değiştir:

```python
    if len(hits) < 2:
        return []
    # Sadece 2-3 terim varsa yalnizca cloze tipi sorular uret (distractors icin terim yeterli)
    min_distractors = min(3, len(hits) - 1)
```

Sonra aynı fonksiyon içinde `distract = [term_snip[t] for t in others[:3]]` ve `if len(distract) < 3` satırlarını bul, her ikisini de `min_distractors` kullanacak şekilde güncelle:

```python
        # definition tipi
        distract = [term_snip[t] for t in others[:min_distractors]]
        if len(distract) < min_distractors:
            continue
        ...
        # cloze tipi
        distract = [t.capitalize() for t in others[:min_distractors]]
        if len(distract) < min_distractors:
            continue
```

Ayrıca `options = distract + [correct]` için MCQ'nun 2-4 seçenek destekleyeceğini UI'a iletmek gerekir (UI'ı 4 seçenek sabit varsayıyorsa düzelt — bkz. `templates/index.html`).

- [ ] **Step 4: Testi çalıştır — PASS bekleniyor**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py -v
```

Beklenen: `4 passed`

- [ ] **Step 5: Commit**

```bash
git add dip/cards.py tests/test_rescue.py
git commit -m "fix: quiz generation works with as few as 2 terms, not just 4+"
```

---

## AŞAMA 2 — Sözlük Genişletme

---

### Task 5: Tıp Terimi Sözlüğünü Genişlet (144 → 500+)

**Problem:** Yalnızca 144 anatomik terim var. Farmakoloji, patoloji, fizyoloji PDF'lerinde 0 kart üretiliyor.

**Files:**
- Modify: `data/latin_terms.txt`

- [ ] **Step 1: Sözlüğe ek kategoriler ekle**

`data/latin_terms.txt` dosyasının sonuna şunu ekle:

```text
# Patoloji / hastalık terimleri
necrosis
apoptosis
inflammation
fibrosis
edema
ischemia
infarction
thrombosis
embolism
hemorrhage
hyperplasia
hypertrophy
atrophy
metaplasia
dysplasia
neoplasm
carcinoma
sarcoma
adenoma
lymphoma
leukemia
melanoma
glioma
hepatoma
# Fizyoloji / fonksiyon
homeostasis
metabolism
catabolism
anabolism
osmosis
diffusion
filtration
secretion
absorption
reabsorption
depolarization
repolarization
action potential
receptor
ligand
enzyme
substrate
catalyst
inhibition
activation
feedback
regulation
# Farmakoloji
pharmacokinetics
pharmacodynamics
bioavailability
half-life
clearance
distribution
elimination
agonist
antagonist
receptor
efficacy
potency
toxicity
dosage
concentration
plasma
serum
# Biyokimya
glucose
glycogen
glycolysis
gluconeogenesis
insulin
glucagon
lipid
cholesterol
triglyceride
phospholipid
fatty acid
amino acid
protein
peptide
polypeptide
enzyme
coenzyme
cofactor
nucleotide
DNA
RNA
transcription
translation
mutation
# Histoloji ek
endocrine
exocrine
sebaceous
mucous
serous
goblet cell
mast cell
macrophage
neutrophil
eosinophil
basophil
plasma cell
connective tissue
# Kardiyovaskuler ek
myocardium
pericardium
endocardium
sinoatrial
atrioventricular
bundle of His
Purkinje
diastole
systole
cardiac output
stroke volume
heart rate
blood pressure
hypertension
hypotension
arrhythmia
tachycardia
bradycardia
# Solunum sistemi
alveolus
bronchus
bronchiole
trachea
larynx
pharynx
diaphragm
pleura
surfactant
compliance
resistance
spirometry
tidal volume
vital capacity
# Boşaltım / böbrek
nephron
glomerulus
tubulus
Bowman capsule
loop of Henle
collecting duct
renal cortex
renal medulla
ureter
urethra
creatinine
urea
electrolyte
sodium
potassium
chloride
bicarbonate
# Endokrin sistem
hormone
pituitary
hypothalamus
thyroid
parathyroid
adrenal
cortisol
aldosterone
epinephrine
norepinephrine
testosterone
estrogen
progesterone
prolactin
oxytocin
vasopressin
# Üreme / gelişim
fertilization
implantation
embryo
fetus
placenta
umbilical cord
amnion
chorion
gonad
gamete
sperm
ovum
meiosis
mitosis
chromosome
```

- [ ] **Step 2: Sözlük boyutunu doğrula**

```bash
venv\Scripts\python -c "from dip.ocr import load_dictionary; d = load_dictionary('data/latin_terms.txt'); print(f'Sozluk boyutu: {len(d)} terim')"
```

Beklenen: `Sozluk boyutu: 500+ terim`

- [ ] **Step 3: Commit**

```bash
git add data/latin_terms.txt
git commit -m "feat: expand medical term dictionary from 144 to 500+ terms covering pathology, pharmacology, physiology"
```

---

## AŞAMA 3 — LLM Zenginleştirme (Claude Haiku)

---

### Task 6: `dip/llm_enhance.py` Modülünü Oluştur

**Goal:** Claude Haiku'yu kullanarak ham extractive kartları öğrenci dostu hale getir. API anahtarı yoksa sessizce mevcut karta dön.

**Files:**
- Create: `dip/llm_enhance.py`
- Modify: `requirements.txt`
- Test: `tests/test_rescue.py`

- [ ] **Step 1: `anthropic` paketini requirements.txt'e ekle**

`requirements.txt` dosyasını aç ve sonuna şunu ekle:

```
anthropic>=0.40.0
```

- [ ] **Step 2: Paketi yükle**

```bash
venv\Scripts\pip install anthropic
```

- [ ] **Step 3: Failing testi ekle** (`tests/test_rescue.py` sonuna):

```python
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
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    card = Flashcard(
        front="«Femur» nedir / neresidir?",
        back="The femur is the longest bone in the human body.",
        term="femur", kind="definition", page=1,
    )
    result = enhance_flashcard(card)
    # Fallback: aynı kart döner
    assert result.term == card.term
    assert result.back == card.back
```

- [ ] **Step 4: Testi çalıştır — FAIL bekleniyor**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py::test_llm_available_returns_bool -v
```

Beklenen: `FAILED — ModuleNotFoundError: No module named 'dip.llm_enhance'`

- [ ] **Step 5: `dip/llm_enhance.py` dosyasını oluştur**

```python
"""
llm_enhance.py
--------------
Claude Haiku ile isteğe bağlı kart/quiz zenginleştirme.

ANTHROPIC_API_KEY ortam değişkeni yoksa ya da hata oluşursa
orijinal kart/soru sessizce döner (offline fallback).
"""
from __future__ import annotations

import json
import os
from typing import List, Optional

from .cards import Flashcard, QuizQuestion


def is_llm_available() -> bool:
    """ANTHROPIC_API_KEY tanımlı mı ve anthropic paketi kurulu mu?"""
    try:
        import anthropic  # noqa: F401
        return bool(os.environ.get("ANTHROPIC_API_KEY"))
    except ImportError:
        return False


def _client():
    """anthropic.Anthropic istemcisi döndürür; kullanılamıyorsa None."""
    if not is_llm_available():
        return None
    try:
        import anthropic
        return anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    except Exception:
        return None


def enhance_flashcard(card: Flashcard) -> Flashcard:
    """
    Bir definition kartının arka yüzünü Claude Haiku ile öğrenci dostu tanıma dönüştürür.
    Başarısız olursa orijinal kartı döndürür.
    """
    client = _client()
    if not client or card.kind != "definition":
        return card

    prompt = (
        f"Sen bir tıp eğitim uzmanısın. Aşağıdaki bilgiyi kullanarak "
        f"tıp öğrencisi için net ve anlaşılır bir flashcard arka yüzü yaz.\n\n"
        f"Terim: {card.term}\n"
        f"Kaynak cümle (PDF'den): {card.back}\n\n"
        f"Görevin:\n"
        f"1. Terimin kısa, net, öğrenci dostu Türkçe tanımını yaz (1-2 cümle).\n"
        f"2. Varsa klinik önemi 1 cümlede ekle.\n\n"
        f"Sadece tanım metnini döndür, başlık veya açıklama ekleme."
    )

    try:
        import anthropic
        response = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}],
        )
        enhanced_back = response.content[0].text.strip()
        if not enhanced_back:
            return card
        return Flashcard(
            front=card.front,
            back=enhanced_back,
            term=card.term,
            kind=card.kind,
            page=card.page,
            source=card.source,  # orijinal cümle kaynak olarak korunur
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
    Kart listesini toplu zenginleştirir.
    Yalnızca definition kartları işlenir; cloze kartlar aynen kalır.
    max_enhance: API maliyetini sınırlamak için zenginleştirilecek max kart sayısı.
    """
    result = []
    enhanced = 0
    for card in cards:
        if card.kind == "definition" and enhanced < max_enhance:
            result.append(enhance_flashcard(card))
            enhanced += 1
        else:
            result.append(card)
    return result


def enhance_quiz_question(q: QuizQuestion, context: str = "") -> QuizQuestion:
    """
    Bir MCQ sorusunu LLM ile iyileştirir: daha net soru + daha iyi çeldiriciler.
    Başarısız olursa orijinal soruyu döndürür.
    """
    client = _client()
    if not client:
        return q

    prompt = (
        f"Aşağıdaki tıp sorusunu iyileştir. Soru ve 4 seçenek döndür.\n\n"
        f"Terim: {q.term}\n"
        f"Mevcut soru: {q.question}\n"
        f"Mevcut seçenekler: {json.dumps(q.options, ensure_ascii=False)}\n"
        f"Doğru indeks: {q.answer_index}\n\n"
        f"Kurallar:\n"
        f"- Tam olarak 4 seçenek döndür\n"
        f"- Doğru cevap aynı answer_index konumunda kalmalı\n"
        f"- Çeldiriciler gerçekçi ama yanlış olmalı\n"
        f"- JSON döndür: {{\"question\": \"...\", \"options\": [...]}}\n"
    )

    try:
        import anthropic
        response = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=400,
            messages=[{"role": "user", "content": prompt}],
        )
        data = json.loads(response.content[0].text.strip())
        new_options = data.get("options", q.options)
        if len(new_options) != 4:
            return q
        return QuizQuestion(
            question=data.get("question", q.question),
            options=new_options,
            answer_index=q.answer_index,
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
    """Quiz sorularını toplu zenginleştirir."""
    result = []
    enhanced = 0
    for q in questions:
        if enhanced < max_enhance:
            result.append(enhance_quiz_question(q))
            enhanced += 1
        else:
            result.append(q)
    return result
```

- [ ] **Step 6: Testi çalıştır — PASS bekleniyor**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py -v
```

Beklenen: `6 passed`

- [ ] **Step 7: Commit**

```bash
git add dip/llm_enhance.py requirements.txt tests/test_rescue.py
git commit -m "feat: add optional LLM enhancement module using Claude Haiku with offline fallback"
```

---

### Task 7: Kart Üretim Endpoint'ine LLM Zenginleştirme Bağla

**Files:**
- Modify: `app.py`
- Modify: `templates/index.html`
- Modify: `static/app.js`

- [ ] **Step 1: `app.py`'a `llm_enhance` importunu ekle**

`app.py`'nın başındaki import bloğunda `from dip import (...)` satırını bul ve `llm_enhance` ekle:

```python
from dip import (
    pdf_loader, segmentation, pipeline, ocr, textextract,
    cards as cards_mod, flashcard_io, llm_enhance,
)
```

- [ ] **Step 2: `generate_cards` fonksiyonuna `enhance` parametresi ekle**

`app.py`'daki `generate_cards` fonksiyonunda şu satırı bul:

```python
    max_cards = int(data.get("max_cards", 40))
```

Hemen altına ekle:

```python
    do_enhance = bool(data.get("enhance", False)) and llm_enhance.is_llm_available()
```

Sonra `cards_mod.generate_flashcards(...)` satırından sonra şunu ekle:

```python
    if do_enhance and cards:
        cards = llm_enhance.enhance_cards_batch(cards, max_enhance=min(20, len(cards)))
```

`return jsonify(...)` içine `"llm_enhanced"` alanını ekle:

```python
    return jsonify({
        "doc_id": doc_id,
        "pages": pages, "truncated": truncated, "source": used,
        "count": len(cards),
        "cards": [c.to_dict() for c in cards],
        "reason": reason,
        "llm_enhanced": do_enhance,
        "llm_available": llm_enhance.is_llm_available(),
    })
```

- [ ] **Step 3: `generate_quiz` fonksiyonuna da `enhance` ekle**

Aynı pattern'i `generate_quiz` için de uygula. `cards_mod.generate_quiz(...)` satırından sonra:

```python
    if bool(data.get("enhance", False)) and llm_enhance.is_llm_available() and quiz:
        quiz = llm_enhance.enhance_quiz_batch(quiz, max_enhance=min(10, len(quiz)))
```

- [ ] **Step 4: `templates/index.html`'e "AI Zenginleştir" toggle ekle**

`index.html` içinde kart üretim formunu bul (run/çalıştır butonu yakınında). Form içine şu checkbox'ı ekle:

```html
<div class="form-group" id="enhance-group" style="margin-top:10px;">
    <label>
        <input type="checkbox" id="enhance-toggle">
        <strong>🤖 AI ile Zenginleştir</strong>
        <small style="color:#666;">(Claude Haiku — API anahtarı gerekir)</small>
    </label>
    <div id="llm-status" style="font-size:0.85em;color:#888;margin-top:4px;"></div>
</div>
```

- [ ] **Step 5: `static/app.js`'te LLM durumunu göster ve enhance parametresini gönder**

`static/app.js`'in başına ya da başlatma koduna şunu ekle (fetch('/api/health') ile LLM durumunu göster):

```javascript
// LLM durum göstergesi
fetch('/api/health')
    .then(r => r.json())
    .then(h => {
        const el = document.getElementById('llm-status');
        if (!el) return;
        if (h && h.dictionary_loaded) {
            el.textContent = `Sözlük: ${h.dictionary_size} terim yüklü`;
        }
    })
    .catch(() => {});
```

Kart üretim isteğini gönderen fonksiyonu bul (genellikle `fetch('/api/generate/cards', ...)` çağrısı). İstek body'sine şunu ekle:

```javascript
const enhance = document.getElementById('enhance-toggle')?.checked || false;
// ... mevcut body objesine:
body.enhance = enhance;
```

Kart listesi render edildiğinde `data.llm_enhanced` true ise badge ekle:

```javascript
if (data.llm_enhanced) {
    const badge = document.createElement('div');
    badge.innerHTML = '<span style="background:#4CAF50;color:white;padding:3px 8px;border-radius:4px;font-size:0.8em;">🤖 AI Zenginleştirildi</span>';
    container.prepend(badge);
}
```

- [ ] **Step 6: Manuel test — API anahtarı olmadan**

```bash
venv\Scripts\python app.py
```

Tarayıcıda http://localhost:5000 aç, bir PDF yükle, "AI Zenginleştir" checkbox'ını işaretle, kart üret. API anahtarı yoksa normal kartlar gelmeli (hata yok).

- [ ] **Step 7: Manuel test — API anahtarıyla**

```bash
$env:ANTHROPIC_API_KEY = "sk-ant-..."
venv\Scripts\python app.py
```

Aynı adımları tekrarla. Kartlarda "🤖 AI Zenginleştirildi" badge görünmeli, arka yüzler daha anlaşılır Türkçe tanımlar içermeli.

- [ ] **Step 8: Commit**

```bash
git add app.py templates/index.html static/app.js
git commit -m "feat: wire Claude Haiku LLM enhancement into card and quiz endpoints with UI toggle"
```

---

### Task 8: `.env` Desteği ve Kurulum Talimatı

**Files:**
- Create: `.env.example`
- Modify: `app.py` (dotenv yükleme)
- Modify: `requirements.txt`

- [ ] **Step 1: `requirements.txt`'e python-dotenv ekle**

```
python-dotenv>=1.0.0
```

- [ ] **Step 2: `.env.example` dosyası oluştur**

```
# MedVisual DIP — Ortam Değişkenleri
# Bu dosyayı .env olarak kopyala ve doldur:
#   cp .env.example .env

# Claude API (isteğe bağlı — yoksa AI zenginleştirme devre dışı)
ANTHROPIC_API_KEY=sk-ant-buraya-yaz

# Poppler PATH (Windows'ta pdftotext.exe dizini)
# POPPLER_PATH=C:\Users\...\poppler\bin
```

- [ ] **Step 3: `app.py`'a dotenv yükleme ekle**

`app.py`'nın en başına (import'lardan önce) şunu ekle:

```python
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass
```

- [ ] **Step 4: Paketleri yükle**

```bash
venv\Scripts\pip install python-dotenv
```

- [ ] **Step 5: Commit**

```bash
git add .env.example requirements.txt app.py
git commit -m "feat: add .env support for ANTHROPIC_API_KEY configuration"
```

---

## Doğrulama — Tüm Testleri Çalıştır

- [ ] **Tüm testler geçmeli**

```bash
venv\Scripts\python -m pytest tests/test_rescue.py -v
```

Beklenen çıktı:
```
test_multiword_term_match_single_page PASSED
test_multiword_term_find_surface PASSED
test_multiword_cloze PASSED
test_health_endpoint_returns_status PASSED
test_quiz_works_with_two_terms PASSED
test_llm_available_returns_bool PASSED
test_enhance_flashcard_fallback_without_api_key PASSED
7 passed
```

- [ ] **Uygulamayı çalıştır ve tarayıcıda dene**

```bash
venv\Scripts\python app.py
```

Kontrol listesi:
- [ ] `/api/health` endpoint tesseract ve pdftotext durumunu gösteriyor mu?
- [ ] Gerçek bir tıp PDF'i yükle, 20-50 sayfa aralığı seç → kart üretildi mi?
- [ ] 0 kart geldiğinde anlamlı Türkçe mesaj görünüyor mu?
- [ ] Quiz en az 2 terimle çalışıyor mu?
- [ ] `ANTHROPIC_API_KEY` olmadan "AI Zenginleştir" seçili → hata yok, normal kart geliyor mu?

---

## Özet — Ne Düzeltildi

| Bug / Eksiklik | Çözüm | Task |
|----------------|-------|------|
| Multi-word terimler eşleşmiyordu | `detect_dictionary_terms` + `_find_surface` çok kelime desteği | 1 |
| Sessiz hatalar — kullanıcı neden göremez | `/api/health` endpoint + `reason` alanı | 2, 3 |
| MCQ < 4 terimde boş dönüyordu | `min_distractors = min(3, n-1)` | 4 |
| 144 terimle çoğu PDF işlenemez | 500+ terim | 5 |
| Ham cümleler tanım değil | Claude Haiku zenginleştirme | 6, 7 |
| API anahtarı konfigürasyonu | `.env` + dotenv | 8 |
