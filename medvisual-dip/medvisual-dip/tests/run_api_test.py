"""Tam API testi - Flask test client ile"""
import sys, io, json, os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from dotenv import load_dotenv; load_dotenv()
except: pass

import app as a
client = a.app.test_client()

errors = []

def check(name, cond, detail=""):
    mark = "OK" if cond else "FAIL"
    print(f"  [{mark}] {name}", detail)
    if not cond:
        errors.append(name)

print("\n=== 1. ANA SAYFA ===")
r = client.get("/")
check("Ana sayfa yuklu", r.status_code == 200)
check("HTML icerik", b"MedVisual" in r.data)

print("\n=== 2. HEALTH ===")
r = client.get("/api/health")
d = json.loads(r.data)
check("Health endpoint", r.status_code == 200)
check("pdftotext mevcut", d["pdftotext"]["available"])
check("Sozluk yuklu", d["dictionary_size"] > 0, f"{d['dictionary_size']} terim")

print("\n=== 3. UPLOAD ===")
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pdf_path = os.path.join(BASE, "samples", "sample_medical.pdf")
with open(pdf_path, "rb") as f:
    pdf_bytes = f.read()
r = client.post("/api/upload", data={"file": (io.BytesIO(pdf_bytes), "test.pdf")},
                content_type="multipart/form-data")
d = json.loads(r.data)
check("Upload 200", r.status_code == 200)
check("doc_id var", bool(d.get("doc_id")))
check("page_count var", d.get("page_count", 0) > 0, str(d.get("page_count")))
doc_id = d.get("doc_id", "")

print("\n=== 4. ERROR HANDLER (HTML degil JSON donmeli) ===")
r2 = client.post("/api/generate/cards", json={"doc_id": "YANLIS_ID_OLMAYAN"})
check("Gecersiz doc_id 404 JSON", r2.status_code in (400, 404))
try:
    d2 = json.loads(r2.data)
    check("404 JSON formatinda", "error" in d2, str(d2))
except:
    check("404 JSON formatinda", False, "HTML dondu!")

print("\n=== 5. KART IMPORT (JSON) ===")
import_json = json.dumps([{"front": "Femur nedir?", "back": "Uyluk kemigi"}]).encode()
r3 = client.post("/api/cards/import",
    data={"file": (io.BytesIO(import_json), "test.json")}, content_type="multipart/form-data")
d3 = json.loads(r3.data)
check("JSON import 200", r3.status_code == 200)
check("1 kart geldi", d3.get("count", 0) >= 1, str(d3.get("count")))

print("\n=== 6. KART IMPORT (TXT) ===")
txt = b"Q: Femur nedir?\nA: Uyluk kemigi uzun kemik\nQ: Tibia nedir?\nA: Kaval kemigi"
r4 = client.post("/api/cards/import",
    data={"file": (io.BytesIO(txt), "test.txt")}, content_type="multipart/form-data")
d4 = json.loads(r4.data)
check("TXT import 200", r4.status_code == 200)
check("2 kart geldi", d4.get("count", 0) >= 2, str(d4.get("count")))

print("\n=== 7. KART IMPORT (CSV) ===")
csv_data = b"front,back\nFemur nedir?,Uyluk kemigi\nTibia nedir?,Kaval kemigi\n"
r_csv = client.post("/api/cards/import",
    data={"file": (io.BytesIO(csv_data), "test.csv")}, content_type="multipart/form-data")
d_csv = json.loads(r_csv.data)
check("CSV import 200", r_csv.status_code == 200)
check("CSV 2 kart", d_csv.get("count", 0) >= 2, str(d_csv.get("count")))

print("\n=== 8. GENERATE CARDS (offline) ===")
if doc_id:
    r5 = client.post("/api/generate/cards",
        json={"doc_id": doc_id, "range": "1", "source": "auto", "max_cards": 5, "enhance": False})
    d5 = json.loads(r5.data)
    check("Cards generate 200", r5.status_code == 200)
    print(f"    Kart sayisi: {d5.get('count', 0)}")
    if d5.get("cards"):
        for c in d5["cards"][:2]:
            print(f"    Q: {c['front'][:70]}")

print("\n=== 9. GENERATE QUIZ (offline, MCQ only) ===")
if doc_id:
    r6 = client.post("/api/generate/quiz",
        json={"doc_id": doc_id, "range": "1", "n": 3, "enhance": False})
    d6 = json.loads(r6.data)
    check("Quiz generate 200", r6.status_code == 200)
    check("Soru var", d6.get("count", 0) > 0 or "warning" in d6)
    for q in d6.get("questions", [])[:1]:
        check("Sadece definition tipi", q.get("kind") == "definition", q.get("kind"))
        check("Cloze yok", q.get("kind") != "cloze")
        print(f"    Q: {q['question'][:70]}")

print("\n=== 10. MULTI-SOURCE ===")
if doc_id:
    r7 = client.post("/api/generate/cards",
        json={"sources": [{"doc_id": doc_id, "range": "1"}, {"doc_id": doc_id, "range": "1"}],
              "source": "auto", "max_cards": 5, "enhance": False})
    d7 = json.loads(r7.data)
    check("Multi-source 200", r7.status_code == 200)
    print(f"    Kart: {d7.get('count', 0)}")

print("\n=== 11. TERMS ===")
r8 = client.get("/api/terms")
d8 = json.loads(r8.data)
check("Terms endpoint", r8.status_code == 200)
check("Terim listesi", len(d8.get("terms", [])) > 100, f"{len(d8.get('terms',[]))} terim")

print()
print("=" * 40)
if errors:
    print(f"SONUC: {len(errors)} HATA: {errors}")
    sys.exit(1)
else:
    print("SONUC: TUM TESTLER GECTI")
