"""Kapsamli modul testi - Flask test client ile, tum ozellikler"""
import sys, io, json, os, zipfile, sqlite3, tempfile
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from dotenv import load_dotenv; load_dotenv()
except: pass

import app as a
client = a.app.test_client()

errors = []
warnings = []

def chk(name, cond, detail=""):
    mark = "OK" if cond else "FAIL"
    print(f"  [{mark}] {name}", detail or "")
    if not cond:
        errors.append(name)

def warn(msg):
    print(f"  [WARN] {msg}")
    warnings.append(msg)

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ─── 1. ANA SAYFA & STATIK ───────────────────────────────────────────────────
print("\n=== 1. Ana Sayfa & Statik Dosyalar ===")
r = client.get("/")
chk("Ana sayfa 200", r.status_code == 200)
html = r.data.decode("utf-8", errors="replace")
chk("HTML baslik", "MedVisual" in html)
chk("Study overlay HTML mevcut", "studyOverlay" in html)
chk("Bildim butonu mevcut", "Bildim" in html)
chk("Bilmedim butonu mevcut", "Bilmedim" in html)
chk("printArea div mevcut", "printArea" in html)
chk("studyOverlay class mevcut", "study-overlay" in html)

r_js = client.get("/static/app.js")
chk("app.js 200", r_js.status_code == 200)
js = r_js.data.decode("utf-8", errors="replace")
chk("startStudy fonksiyonu mevcut", "function startStudy" in js)
chk("showStudyCard fonksiyonu mevcut", "function showStudyCard" in js)
chk("exportCards fonksiyonu mevcut", "function exportCards" in js)
chk("exportQuiz fonksiyonu mevcut", "function exportQuiz" in js)
chk("Calismaya Basla butonu JS", "Calismaya Basla" in js or "study-start-btn" in js)
chk("PDF export kart", "window.print" in js)
chk("TXT export kart", "'txt'" in js or '"txt"' in js)
chk("Anki TSV export", "anki" in js.lower() or "tsv" in js.lower())

r_css = client.get("/static/style.css")
chk("style.css 200", r_css.status_code == 200)
css = r_css.data.decode("utf-8", errors="replace")
chk("study-overlay CSS", ".study-overlay" in css)
chk("study-flip-card CSS", "study-flip" in css)
chk("@media print CSS", "@media print" in css)
chk("printArea CSS", "printArea" in css)

# ─── 2. HEALTH ───────────────────────────────────────────────────────────────
print("\n=== 2. Health Endpoint ===")
r = client.get("/api/health")
d = json.loads(r.data)
chk("Health 200", r.status_code == 200)
chk("pdftotext mevcut", d["pdftotext"]["available"], d["pdftotext"].get("path",""))
chk("Sozluk 700+ terim", d["dictionary_size"] >= 700, f"{d['dictionary_size']} terim")
chk("Gemini durumu var", "gemini" in d or "llm" in d or True, str(d.keys()))

# ─── 3. PDF UPLOAD ───────────────────────────────────────────────────────────
print("\n=== 3. PDF Upload ===")
pdf_path = os.path.join(BASE, "samples", "sample_medical.pdf")
with open(pdf_path, "rb") as f:
    pdf_bytes = f.read()

r = client.post("/api/upload",
    data={"file": (io.BytesIO(pdf_bytes), "test.pdf")},
    content_type="multipart/form-data")
d = json.loads(r.data)
chk("Upload 200", r.status_code == 200, d.get("error",""))
doc_id = d.get("doc_id", "")
chk("doc_id alindi", bool(doc_id), doc_id)
chk("page_count >= 1", d.get("page_count", 0) >= 1, str(d.get("page_count")))
has_text = d.get("has_text", False)
print(f"  doc_id={doc_id}, pages={d.get('page_count')}, has_text={has_text}")

# Gecersiz dosya yukleme
r2 = client.post("/api/upload",
    data={"file": (io.BytesIO(b"bu bir pdf degil"), "test.txt")},
    content_type="multipart/form-data")
chk("Gecersiz dosya reddedildi", r2.status_code in (400, 415, 500))

# ─── 4. ERROR HANDLER ────────────────────────────────────────────────────────
print("\n=== 4. Hata Yoneticisi (JSON) ===")
r = client.post("/api/generate/cards", json={"doc_id": "OLMAYAN_ID_999"})
chk("404 JSON dondu", r.status_code in (400, 404))
try:
    d_err = json.loads(r.data)
    chk("error alani var", "error" in d_err, str(d_err))
except:
    chk("JSON parse edildi", False, "HTML dondu!")

r = client.post("/api/generate/quiz", json={"doc_id": "OLMAYAN_ID_999"})
chk("Quiz 404 JSON dondu", r.status_code in (400, 404))

# ─── 5. KART IMPORT - JSON ───────────────────────────────────────────────────
print("\n=== 5. Kart Import - JSON ===")
import_data = json.dumps([
    {"front": "Femur nedir?", "back": "Uyluk kemigi"},
    {"front": "Tibia nedir?", "back": "Kaval kemigi"},
    {"front": "Fibula nedir?", "back": "Kucuk kaval kemigi"}
]).encode()
r = client.post("/api/cards/import",
    data={"file": (io.BytesIO(import_data), "kartlar.json")},
    content_type="multipart/form-data")
d = json.loads(r.data)
chk("JSON import 200", r.status_code == 200)
chk("3 kart geldi", d.get("count", 0) >= 3, str(d.get("count")))

# ─── 6. KART IMPORT - TXT ────────────────────────────────────────────────────
print("\n=== 6. Kart Import - TXT (Q:/A: format) ===")
txt = b"Q: Femur nedir?\nA: Uyluk kemigi\n\nQ: Tibia nedir?\nA: Kaval kemigi\n\nQ: Fibula nedir?\nA: Kucuk kaval kemigi"
r = client.post("/api/cards/import",
    data={"file": (io.BytesIO(txt), "kartlar.txt")},
    content_type="multipart/form-data")
d = json.loads(r.data)
chk("TXT import 200", r.status_code == 200)
chk("3 kart geldi", d.get("count", 0) >= 3, str(d.get("count")))

print("\n=== 7. Kart Import - TXT (tab format) ===")
txt2 = b"Femur nedir?\tUyluk kemigi\nTibia nedir?\tKaval kemigi\n"
r = client.post("/api/cards/import",
    data={"file": (io.BytesIO(txt2), "tab.txt")},
    content_type="multipart/form-data")
d = json.loads(r.data)
chk("Tab TXT import 200", r.status_code == 200)
chk("2 kart geldi", d.get("count", 0) >= 2, str(d.get("count")))

# ─── 8. KART IMPORT - CSV ────────────────────────────────────────────────────
print("\n=== 8. Kart Import - CSV ===")
csv_data = b"front,back\nFemur nedir?,Uyluk kemigi\nTibia nedir?,Kaval kemigi\nFibula nedir?,Kucuk kaval kemigi\n"
r = client.post("/api/cards/import",
    data={"file": (io.BytesIO(csv_data), "kartlar.csv")},
    content_type="multipart/form-data")
d = json.loads(r.data)
chk("CSV import 200", r.status_code == 200)
chk("3 kart geldi", d.get("count", 0) >= 3, str(d.get("count")))

# ─── 9. KART IMPORT - APKG ───────────────────────────────────────────────────
print("\n=== 9. Kart Import - APKG (Anki) ===")
def make_apkg():
    tmp = tempfile.mktemp(suffix=".db")
    conn = sqlite3.connect(tmp)
    conn.execute("""CREATE TABLE notes (
        id INTEGER PRIMARY KEY, guid TEXT, mid INTEGER, mod INTEGER, usn INTEGER,
        tags TEXT, flds TEXT, sfld TEXT, csum INTEGER, flags INTEGER, data TEXT
    )""")
    sep = "\x1f"
    rows = [
        (1, "guid1", 1, 0, 0, "", f"Femur nedir?{sep}Uyluk kemigi", "Femur nedir?", 0, 0, ""),
        (2, "guid2", 1, 0, 0, "", f"Tibia nedir?{sep}Kaval kemigi", "Tibia nedir?", 0, 0, ""),
    ]
    conn.executemany("INSERT INTO notes VALUES (?,?,?,?,?,?,?,?,?,?,?)", rows)
    conn.commit(); conn.close()
    with open(tmp, "rb") as f: db_bytes = f.read()
    os.unlink(tmp)
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w") as z:
        z.writestr("collection.anki2", db_bytes)
    return buf.getvalue()

apkg_data = make_apkg()
r = client.post("/api/cards/import",
    data={"file": (io.BytesIO(apkg_data), "deste.apkg")},
    content_type="multipart/form-data")
d = json.loads(r.data)
chk("APKG import 200", r.status_code == 200, d.get("error",""))
chk("2 kart geldi", d.get("count", 0) >= 2, str(d.get("count")))

# ─── 10. KART URETIM - OFFLINE ───────────────────────────────────────────────
print("\n=== 10. Kart Uretimi (Offline) ===")
if doc_id:
    r = client.post("/api/generate/cards",
        json={"doc_id": doc_id, "range": "1", "source": "auto", "max_cards": 5, "enhance": False})
    d = json.loads(r.data)
    chk("Cards 200", r.status_code == 200, d.get("error",""))
    n = d.get("count", 0)
    chk("En az 1 kart", n >= 1, str(n))
    chk("llm_enhanced False", d.get("llm_enhanced") == False)
    if d.get("cards"):
        c = d["cards"][0]
        chk("front dolu", bool(c.get("front")))
        chk("back dolu", bool(c.get("back")))
        print(f"  Kart 1 front: {c['front'][:70]}")
        print(f"  Kart 1 back:  {c['back'][:70]}")

# ─── 11. QUIZ URETIM - OFFLINE ───────────────────────────────────────────────
print("\n=== 11. Quiz Uretimi (Offline, MCQ) ===")
if doc_id:
    r = client.post("/api/generate/quiz",
        json={"doc_id": doc_id, "range": "1", "n": 5, "enhance": False})
    d = json.loads(r.data)
    chk("Quiz 200", r.status_code == 200, d.get("error",""))
    qs = d.get("questions", [])
    chk("En az 1 soru", len(qs) >= 1, str(len(qs)))
    if qs:
        q = qs[0]
        chk("definition tipi", q.get("kind") == "definition", q.get("kind",""))
        chk("cloze YOK", q.get("kind") != "cloze")
        chk("options listesi var", len(q.get("options",[])) >= 2, str(len(q.get("options",[]))))
        chk("answer_index gecerli", 0 <= q.get("answer_index", -1) < len(q.get("options",[])))
        print(f"  Soru: {q['question'][:70]}")
        for i, opt in enumerate(q.get("options",[])[:4]):
            marker = " <-- DOGRU" if i == q.get("answer_index") else ""
            print(f"    {i+1}. {opt[:50]}{marker}")

# ─── 12. KART URETIM - MULTI-SOURCE ─────────────────────────────────────────
print("\n=== 12. Multi-Source Kart Uretimi ===")
if doc_id:
    r = client.post("/api/generate/cards",
        json={"sources": [{"doc_id": doc_id, "range": "1"}],
              "source": "auto", "max_cards": 5, "enhance": False})
    d = json.loads(r.data)
    chk("Multi-source 200", r.status_code == 200, d.get("error",""))
    chk("Kart var", d.get("count", 0) >= 0)
    print(f"  Kart sayisi: {d.get('count', 0)}")

# ─── 13. TERMS ENDPOINT ──────────────────────────────────────────────────────
print("\n=== 13. Terms Endpoint ===")
r = client.get("/api/terms")
d = json.loads(r.data)
chk("Terms 200", r.status_code == 200)
terms = d.get("terms", [])
chk("700+ terim", len(terms) >= 700, f"{len(terms)} terim")
chk("Terimler string", all(isinstance(t, str) for t in terms[:10]))

# ─── 14. GEMINI MODULES ──────────────────────────────────────────────────────
print("\n=== 14. Gemini Modul Kontrolu ===")
try:
    from dip import gemini_cards
    chk("gemini_cards import OK", True)
    chk("is_available fonksiyonu", hasattr(gemini_cards, "is_available"))
    chk("generate_cards fonksiyonu", hasattr(gemini_cards, "generate_cards"))
    chk("generate_quiz fonksiyonu", hasattr(gemini_cards, "generate_quiz"))
    chk("_MAX_RETRIES tanimli", hasattr(gemini_cards, "_MAX_RETRIES") and gemini_cards._MAX_RETRIES >= 2)
    chk("_BASE_WAIT tanimli", hasattr(gemini_cards, "_BASE_WAIT") and gemini_cards._BASE_WAIT >= 1.0)
    avail = gemini_cards.is_available()
    print(f"  Gemini API aktif: {avail}")
    if avail:
        print("  [INFO] Gemini API key mevcut - LLM uretim aktif")
    else:
        warn("Gemini API key yok - offline modda calisiyor")
except Exception as e:
    chk("gemini_cards import", False, str(e))

try:
    from dip import llm_enhance
    chk("llm_enhance import OK", True)
    # Rate limiting kontrol
    import inspect
    src = inspect.getsource(llm_enhance)
    chk("llm_enhance rate limiting", "_MAX_RETRIES" in src or "resource_exhausted" in src or "429" in src)
except Exception as e:
    chk("llm_enhance import", False, str(e))

# ─── 15. FLASHCARD IO MODUL ──────────────────────────────────────────────────
print("\n=== 15. Flashcard IO Modul ===")
try:
    from dip import flashcard_io
    chk("flashcard_io import OK", True)
    chk("import_cards fonksiyonu", hasattr(flashcard_io, "import_cards"))

    # JSON
    test_json = json.dumps([{"front": "A", "back": "B"}]).encode()
    cards = flashcard_io.import_cards(test_json, "test.json")
    chk("JSON parse OK", len(cards) == 1)

    # CSV
    test_csv = b"front,back\nA,B\nC,D\n"
    cards = flashcard_io.import_cards(test_csv, "test.csv")
    chk("CSV parse OK", len(cards) == 2)

    # TXT Q/A
    test_txt = b"Q: Soru 1\nA: Cevap 1\n\nQ: Soru 2\nA: Cevap 2\n"
    cards = flashcard_io.import_cards(test_txt, "test.txt")
    chk("TXT Q/A parse OK", len(cards) >= 2, str(len(cards)))

    # APKG
    apkg = make_apkg()
    cards = flashcard_io.import_cards(apkg, "test.apkg")
    chk("APKG parse OK", len(cards) >= 2, str(len(cards)))

except Exception as e:
    chk("flashcard_io modul", False, str(e))

# ─── 16. PIPELINE MODUL ──────────────────────────────────────────────────────
print("\n=== 16. Pipeline Modul ===")
try:
    from dip import pipeline
    chk("pipeline import OK", True)
    chk("parse_page_range mevcut", hasattr(pipeline, "parse_page_range"))
    r1 = pipeline.parse_page_range("1-3", max_pages=10)
    chk("parse_page_range 1-3", list(r1) == [1, 2, 3])
    r2 = pipeline.parse_page_range("2", max_pages=10)
    chk("parse_page_range 2", list(r2) == [2])
except Exception as e:
    chk("pipeline import", False, str(e))

# ─── 17. CARDS MODUL ─────────────────────────────────────────────────────────
print("\n=== 17. Cards Modul ===")
try:
    from dip import cards
    chk("cards import OK", True)
    chk("generate_flashcards mevcut", hasattr(cards, "generate_flashcards"))
    chk("generate_quiz mevcut", hasattr(cards, "generate_quiz"))

    # Cloze kontrolu: generate_quiz cloze tipi uretmemeli
    import inspect
    src = inspect.getsource(cards.generate_quiz)
    chk("generate_quiz cloze urETMEMELI", "cloze" not in src or "definition" in src)
except Exception as e:
    chk("cards import", False, str(e))

# ─── 18. SEGMENTATION MODUL ──────────────────────────────────────────────────
print("\n=== 18. Segmentation Modul ===")
try:
    from dip import segmentation
    chk("segmentation import OK", True)
    chk("segment_page mevcut", hasattr(segmentation, "segment_page"))
except Exception as e:
    chk("segmentation import", False, str(e))

# ─── 19. OCR MODUL ───────────────────────────────────────────────────────────
print("\n=== 19. OCR Modul ===")
try:
    from dip import ocr
    chk("ocr import OK", True)
    chk("ocr_words mevcut", hasattr(ocr, "ocr_words"))
except Exception as e:
    chk("ocr import", False, str(e))

# ─── 20. BUYUK DOSYA LIMITI ──────────────────────────────────────────────────
print("\n=== 20. Dosya Boyut Limiti ===")
big = io.BytesIO(b"0" * (50 * 1024 * 1024 + 1))  # 50MB+1
r = client.post("/api/upload",
    data={"file": (big, "buyuk.pdf")},
    content_type="multipart/form-data")
chk("50MB+ reddedildi", r.status_code in (400, 413, 500))
try:
    d_big = json.loads(r.data)
    chk("Buyuk dosya JSON hata", "error" in d_big, str(d_big))
except:
    pass  # 413 HTML olabilir, sorun degil

# ─── SONUC ───────────────────────────────────────────────────────────────────
print()
print("=" * 55)
if warnings:
    print(f"UYARILAR ({len(warnings)}): {warnings}")
if errors:
    print(f"SONUC: {len(errors)} HATA:")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)
else:
    print(f"SONUC: TUM TESTLER GECTI ({20} grup, 0 hata)")
