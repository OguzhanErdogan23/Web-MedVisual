"""Gercek HTTP sunucusuyla uçtan uca test"""
import threading, time, urllib.request, io, json, os, sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)

try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(BASE_DIR, ".env"))
except Exception:
    pass

import app as flask_app

PORT = 5099

def run_server():
    flask_app.app.run(host="127.0.0.1", port=PORT, debug=False, use_reloader=False)

t = threading.Thread(target=run_server, daemon=True)
t.start()

for _ in range(20):
    try:
        urllib.request.urlopen(f"http://127.0.0.1:{PORT}/api/health", timeout=1)
        break
    except Exception:
        time.sleep(0.4)
else:
    print("HATA: Sunucu baslamadi!")
    sys.exit(1)

print("Sunucu hazir. Testler basliyor...")

def get(path):
    r = urllib.request.urlopen(f"http://127.0.0.1:{PORT}{path}", timeout=10)
    return r.status, json.loads(r.read())

def post_json(path, body):
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        f"http://127.0.0.1:{PORT}{path}", data=data,
        headers={"Content-Type": "application/json"}
    )
    try:
        r = urllib.request.urlopen(req, timeout=20)
        return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())

def post_multipart(path, field, filename, data, content_type="application/octet-stream"):
    boundary = "Boundary7MA4YWxkTrZu0gW"
    body = (
        f"--{boundary}\r\n"
        f"Content-Disposition: form-data; name=\"{field}\"; filename=\"{filename}\"\r\n"
        f"Content-Type: {content_type}\r\n\r\n"
    ).encode() + data + f"\r\n--{boundary}--\r\n".encode()
    req = urllib.request.Request(
        f"http://127.0.0.1:{PORT}{path}", data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"}
    )
    try:
        r = urllib.request.urlopen(req, timeout=20)
        return r.status, json.loads(r.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())

errors = []

def chk(name, ok, detail=""):
    mark = "OK" if ok else "FAIL"
    print(f"  [{mark}] {name}", detail or "")
    if not ok:
        errors.append(name)

# ---- TEST 1: HEALTH ----
print("\n=== 1. Health ===")
s, d = get("/api/health")
chk("200 OK", s == 200)
chk("pdftotext", d["pdftotext"]["available"], d["pdftotext"].get("path", ""))
chk("Sozluk", d["dictionary_size"] >= 700, f"{d['dictionary_size']} terim")

# ---- TEST 2: UPLOAD ----
print("\n=== 2. PDF Upload ===")
pdf_path = os.path.join(BASE_DIR, "samples", "sample_medical.pdf")
with open(pdf_path, "rb") as f:
    pdf_bytes = f.read()

s, d = post_multipart("/api/upload", "file", "sample.pdf", pdf_bytes, "application/pdf")
chk("Upload 200", s == 200, d.get("error", ""))
doc_id = d.get("doc_id", "")
chk("doc_id alindi", bool(doc_id))
chk("page_count", d.get("page_count", 0) >= 1, str(d.get("page_count")))
print(f"  doc_id: {doc_id}, pages: {d.get('page_count')}, has_text: {d.get('has_text')}")

# ---- TEST 3: ERROR HANDLER ----
print("\n=== 3. Error Handler (JSON) ===")
s, d = post_json("/api/generate/cards", {"doc_id": "OLMAYAN_BELGE", "range": "1"})
chk("404 status", s == 404)
chk("JSON error field", "error" in d, str(d))
print(f"  Donen: {d}")

# ---- TEST 4: GENERATE CARDS ----
print("\n=== 4. Generate Cards (offline) ===")
if doc_id:
    s, d = post_json("/api/generate/cards", {
        "doc_id": doc_id, "range": "1", "source": "auto", "max_cards": 5, "enhance": False
    })
    chk("200 OK", s == 200)
    chk("Yanit alindi", "count" in d)
    n = d.get("count", 0)
    print(f"  Uretilen kart: {n}")
    if d.get("cards"):
        c = d["cards"][0]
        chk("front dolu", bool(c.get("front")))
        chk("back dolu", bool(c.get("back")))
        print(f"  Kart 1: {c['front'][:65]}")
        print(f"  Cevap:  {c['back'][:65]}")
    if d.get("reason") and n == 0:
        print(f"  Sebep: {d['reason'][:80]}")

# ---- TEST 5: GENERATE QUIZ ----
print("\n=== 5. Generate Quiz (MCQ) ===")
if doc_id:
    s, d = post_json("/api/generate/quiz", {
        "doc_id": doc_id, "range": "1", "n": 3, "enhance": False
    })
    chk("200 OK", s == 200)
    qs = d.get("questions", [])
    print(f"  Uretilen soru: {len(qs)}")
    if qs:
        q = qs[0]
        chk("definition tipi", q.get("kind") == "definition", q.get("kind"))
        chk("cloze yok", q.get("kind") != "cloze")
        chk("4 secenek", len(q.get("options", [])) >= 2)
        print(f"  Soru: {q['question'][:70]}")
        for i, opt in enumerate(q.get("options", [])[:4]):
            marker = " <-- DOGRU" if i == q.get("answer_index") else ""
            print(f"    {i+1}. {opt[:50]}{marker}")

# ---- TEST 6: KART IMPORT ----
print("\n=== 6. Kart Import (JSON) ===")
jdata = json.dumps([{"front": "Femur nedir?", "back": "Bacagın en uzun kemiği"}]).encode()
s, d = post_multipart("/api/cards/import", "file", "kartlar.json", jdata, "application/json")
chk("200 OK", s == 200)
chk("Kart sayisi >= 1", d.get("count", 0) >= 1, str(d.get("count")))

print("\n=== 7. Kart Import (TXT) ===")
txt = b"Q: Femur nedir?\nA: Bacagin en uzun kemigi\nQ: Tibia nedir?\nA: Kaval kemigi"
s, d = post_multipart("/api/cards/import", "file", "kartlar.txt", txt, "text/plain")
chk("200 OK", s == 200)
chk("Kart sayisi >= 2", d.get("count", 0) >= 2, str(d.get("count")))

print("\n=== 8. Kart Import (CSV) ===")
csv_d = b"front,back\nFemur nedir?,Uyluk kemigi\nTibia nedir?,Kaval kemigi\n"
s, d = post_multipart("/api/cards/import", "file", "kartlar.csv", csv_d, "text/csv")
chk("200 OK", s == 200)
chk("Kart sayisi >= 2", d.get("count", 0) >= 2, str(d.get("count")))

# ---- TEST 7: MULTI-SOURCE ----
print("\n=== 9. Multi-source ===")
if doc_id:
    s, d = post_json("/api/generate/cards", {
        "sources": [{"doc_id": doc_id, "range": "1"}],
        "source": "auto", "max_cards": 3, "enhance": False
    })
    chk("200 OK", s == 200)
    print(f"  Kart: {d.get('count', 0)}")

# ---- SONUC ----
print()
print("=" * 45)
if errors:
    print(f"SONUC: {len(errors)} HATA: {errors}")
    sys.exit(1)
else:
    print("SONUC: TUM HTTP TESTLER GECTI")
