"""Gercek kitapla (Prometheus) tam akis testi: kutuphane -> Gemini'li kart
uretimi -> gercek figur eslestirme -> gorsel secimi -> calisma.

Calistirma: .venv\\Scripts\\python.exe tests\\e2e_realbook.py
"""
import sys
import time

import httpx

API = "http://localhost:8000"
SUPABASE_URL = "https://dwihzurpusgljdjnnquu.supabase.co"
PUBLISHABLE_KEY = "sb_publishable_Ge6Nq5wgcE54JVA0VN2ClQ_RhePrmNp"
EMAIL = "medvisual.e2e@example.com"
PASSWORD = "E2eTest!12345"
CARD_RANGE = "40-52"   # icerik yogun anatomi sayfalari (taranmis PDF -> OCR, dar tut)
N_CARDS = 12

ok = 0


def check(label, cond, detail=""):
    global ok
    print(f"[{'PASS' if cond else 'FAIL'}] {label}" + (f" — {detail}" if detail else ""))
    if not cond:
        sys.exit(1)
    ok += 1


def token():
    with httpx.Client(timeout=30) as c:
        r = c.post(
            f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
            headers={"apikey": PUBLISHABLE_KEY},
            json={"email": EMAIL, "password": PASSWORD},
        )
        return r.json()["access_token"]


def poll(client, url, target, busy, timeout_s=600):
    t0 = time.time()
    while time.time() - t0 < timeout_s:
        d = client.get(url).json()
        if d.get("status") == target:
            return d
        if d.get("status") != busy:
            print("Beklenmedik durum:", d.get("status"), "-", d.get("error"))
            sys.exit(1)
        time.sleep(3)
    print("Zaman asimi:", url)
    sys.exit(1)


def main():
    client = httpx.Client(
        base_url=API,
        headers={"Authorization": f"Bearer {token()}"},
        timeout=httpx.Timeout(300, connect=10),
    )

    books = client.get("/books").json()["books"]
    check("Kutuphane listesi", len(books) > 0, ", ".join(b["name"] for b in books))
    book = next((b for b in books if "Prometheus" in b["name"]), books[0])

    r = client.post("/books/load", json={"name": book["name"]})
    check("Kitap yukleme istegi (202)", r.status_code == 202, book["name"])
    doc = poll(client, f"/documents/{r.json()['id']}", "ready", "processing")
    check("Kitap hazir", True, f"{doc['page_count']} sayfa, has_text={doc['has_text']}")

    # --- Gemini'li kart uretimi (gercek icerik kalite testi) ---
    t0 = time.time()
    r = client.post(
        f"/documents/{doc['id']}/generate/cards",
        json={"range": CARD_RANGE, "max_cards": N_CARDS, "enhance": True,
              "source": "auto", "set_title": f"Prometheus {CARD_RANGE} (Gemini)"},
    )
    check("Kart uretim istegi (Gemini enhance=True)", r.status_code == 202)
    set_row = poll(client, f"/sets/{r.json()['id']}", "ready", "generating")
    cards = set_row["cards"]
    dt = time.time() - t0
    check("Kartlar uretildi", len(cards) > 0,
          f"{len(cards)} kart, {dt:.0f} sn — {set_row.get('description')}")
    print("\n--- Ornek kartlar ---")
    for c in cards[:4]:
        print(f"  S: {c['front']}")
        print(f"  C: {c['back']}  (terim: {c.get('term')}, sayfa: {c.get('page')})\n")

    # --- Gercek figur eslestirme: sayfasi bilinen, terimli bir kart sec ---
    card = next((c for c in cards if c.get("term") and c.get("page")), cards[0])
    page = card.get("page") or 50
    rng = f"{max(1, page - 8)}-{min(doc['page_count'], page + 8)}"
    t0 = time.time()
    r = client.post(f"/cards/{card['id']}/match", json={"range": rng})
    m = r.json()
    check("Gercek sayfalarda figur taramasi", r.status_code == 200,
          f"aralik {rng}, matched={m.get('matched')}, benzerlik={m.get('similarity')}, "
          f"{len(m.get('candidates', []))} aday, {time.time()-t0:.0f} sn")
    if m.get("candidates"):
        c0 = m["candidates"][0]
        img = client.get(c0["url"])
        check("Aday gorsel proxy", img.status_code == 200,
              f"{c0['label']} (sayfa {c0['page']}), {len(img.content)//1024} KB")
        r = client.post(f"/cards/{card['id']}/select-image",
                        json={"dip_doc_id": c0["dip_doc_id"], "path": c0["path"]})
        check("Gorsel kartta kalici (Storage)", bool(r.json().get("image_url")),
              r.json().get("image_url", "")[:80])
    else:
        print("[WARN] Bu aralikta aday bulunamadi (figursuz sayfalar olabilir).")

    # --- Quiz (Gemini) ---
    r = client.post(
        f"/documents/{doc['id']}/generate/quiz",
        json={"range": CARD_RANGE, "n_questions": 5, "enhance": True, "source": "auto"},
    )
    quiz = poll(client, f"/quizzes/{r.json()['id']}", "ready", "generating")
    check("Gemini quiz uretildi", len(quiz["questions"]) > 0,
          f"{len(quiz['questions'])} soru")
    q0 = quiz["questions"][0]
    print(f"\n--- Ornek soru ---\n  {q0['question']}")
    for i, o in enumerate(q0["options"]):
        mark = "*" if i == q0["answer_index"] else " "
        print(f"   {mark} {chr(65+i)}) {o}")

    r = client.get(f"/study/due?set_id={set_row['id']}")
    check("Calisma kuyrugu", r.json()["total_due"] == len(cards),
          f"{r.json()['total_due']} kart vadede")

    print(f"\n=== GERCEK KITAP TESTI TAMAM: {ok} kontrol gecti ===")


if __name__ == "__main__":
    main()
