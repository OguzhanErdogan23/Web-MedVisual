"""Gercek kitap testinin devami: hazir 'Prometheus 40-52 (Gemini)' seti
uzerinden kart kalitesi, figur eslestirme, gorsel secimi ve quiz."""
import sys
import time

import httpx

API = "http://localhost:8000"
SUPABASE_URL = "https://dwihzurpusgljdjnnquu.supabase.co"
PUBLISHABLE_KEY = "sb_publishable_Ge6Nq5wgcE54JVA0VN2ClQ_RhePrmNp"
EMAIL = "medvisual.e2e@example.com"
PASSWORD = "E2eTest!12345"

ok = 0


def check(label, cond, detail=""):
    global ok
    print(f"[{'PASS' if cond else 'FAIL'}] {label}" + (f" — {detail}" if detail else ""), flush=True)
    if not cond:
        sys.exit(1)
    ok += 1


def main():
    r = httpx.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": PUBLISHABLE_KEY},
        json={"email": EMAIL, "password": PASSWORD},
        timeout=30,
    )
    client = httpx.Client(
        base_url=API,
        headers={"Authorization": f"Bearer {r.json()['access_token']}"},
        timeout=httpx.Timeout(1800, connect=10),
    )

    sets = client.get("/sets").json()["sets"]
    set_row = next(s for s in sets if s["title"] == "Prometheus 40-52 (Gemini)")
    detail = client.get(f"/sets/{set_row['id']}").json()
    cards = detail["cards"]
    check("Gemini seti hazir", detail["status"] == "ready", f"{len(cards)} kart")

    print("\n--- Ornek kartlar (Gemini, taranmis kitap OCR'i) ---", flush=True)
    for c in cards[:4]:
        print(f"  S: {c['front']}")
        print(f"  C: {c['back']}  (terim: {c.get('term')}, sayfa: {c.get('page')})\n", flush=True)

    # eski basarisiz 40-70 denemesini temizle
    stale = next((s for s in sets if s["status"] == "failed"), None)
    if stale:
        client.delete(f"/sets/{stale['id']}")
        print(f"[temizlik] Basarisiz set silindi: {stale['title']}", flush=True)

    doc = client.get(f"/documents/{detail['document_id']}").json()

    # --- Figur eslestirme (dar aralik: OCR'li tarama sayfa basina ~30-60 sn) ---
    card = next((c for c in cards if c.get("term") and c.get("page")), cards[0])
    page = card.get("page") or 45
    rng = f"{max(1, page - 3)}-{min(doc['page_count'], page + 3)}"
    print(f"Figur taramasi: '{card.get('term')}' icin sayfa {rng} (kart sayfasi {page})", flush=True)
    t0 = time.time()
    r = client.post(f"/cards/{card['id']}/match", json={"range": rng})
    m = r.json()
    check("Gercek figur taramasi", r.status_code == 200,
          f"matched={m.get('matched')}, benzerlik={m.get('similarity')}, "
          f"{len(m.get('candidates', []))} aday, {time.time()-t0:.0f} sn")

    if m.get("candidates"):
        c0 = m["candidates"][0]
        img = client.get(c0["url"])
        check("Aday gorsel proxy", img.status_code == 200,
              f"{c0['label']} (sayfa {c0['page']}), {len(img.content)//1024} KB")
        r = client.post(f"/cards/{card['id']}/select-image",
                        json={"dip_doc_id": c0["dip_doc_id"], "path": c0["path"]})
        check("Gorsel kalici (Storage)", bool(r.json().get("image_url")),
              r.json().get("image_url", "")[:80])
    else:
        print("[WARN] Aday yok — bu aralikta figur bulunamadi.", flush=True)

    # --- Gemini quiz (dar aralik) ---
    qrng = f"{page}-{min(doc['page_count'], page + 3)}"
    r = client.post(
        f"/documents/{doc['id']}/generate/quiz",
        json={"range": qrng, "n_questions": 5, "enhance": True, "source": "auto"},
    )
    check("Quiz istegi (202)", r.status_code == 202, f"aralik {qrng}")
    qid = r.json()["id"]
    t0 = time.time()
    while time.time() - t0 < 1500:
        q = client.get(f"/quizzes/{qid}").json()
        if q["status"] != "generating":
            break
        time.sleep(5)
    check("Gemini quiz uretildi", q["status"] == "ready" and q["questions"],
          f"{len(q['questions'])} soru, {time.time()-t0:.0f} sn")
    q0 = q["questions"][0]
    print(f"\n--- Ornek soru ---\n  {q0['question']}", flush=True)
    for i, o in enumerate(q0["options"]):
        print(f"   {'*' if i == q0['answer_index'] else ' '} {chr(65+i)}) {o}", flush=True)

    r = client.get(f"/study/due?set_id={set_row['id']}")
    check("Calisma kuyrugu", r.json()["total_due"] == len(cards),
          f"{r.json()['total_due']} kart vadede")

    print(f"\n=== GERCEK KITAP TESTI TAMAM: {ok} kontrol gecti ===", flush=True)


if __name__ == "__main__":
    main()
