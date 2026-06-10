"""Uctan uca duman testi: auth -> upload -> kart uretimi -> gorsel -> SM-2.

Calistirma: .venv\\Scripts\\python.exe tests\\e2e_smoke.py
On kosullar: API (:8000) ve DIP motoru (:5000) calisiyor, migration uygulanmis,
e-posta onayi kapali.
"""
import sys
import time

import httpx

API = "http://localhost:8000"
SUPABASE_URL = "https://dwihzurpusgljdjnnquu.supabase.co"
PUBLISHABLE_KEY = "sb_publishable_Ge6Nq5wgcE54JVA0VN2ClQ_RhePrmNp"
EMAIL = "medvisual.e2e@example.com"
PASSWORD = "E2eTest!12345"
SAMPLE_PDF = (
    r"C:\Users\ogito\Desktop\3 proje\medvisual-dip\medvisual-dip"
    r"\samples\sample_medical.pdf"
)

ok_count = 0


def check(label: str, cond: bool, detail: str = ""):
    global ok_count
    mark = "PASS" if cond else "FAIL"
    print(f"[{mark}] {label}" + (f" — {detail}" if detail else ""))
    if cond:
        ok_count += 1
    else:
        sys.exit(1)


def get_token() -> str:
    headers = {"apikey": PUBLISHABLE_KEY}
    with httpx.Client(timeout=30) as c:
        r = c.post(
            f"{SUPABASE_URL}/auth/v1/signup",
            headers=headers,
            json={"email": EMAIL, "password": PASSWORD},
        )
        if r.status_code == 200 and r.json().get("access_token"):
            return r.json()["access_token"]
        # kullanici zaten varsa parola ile giris
        r = c.post(
            f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
            headers=headers,
            json={"email": EMAIL, "password": PASSWORD},
        )
        if r.status_code != 200:
            print("Auth hatasi:", r.status_code, r.text)
            sys.exit(1)
        return r.json()["access_token"]


def poll(client: httpx.Client, url: str, field: str, target: str, busy: str,
         timeout_s: int = 300) -> dict:
    t0 = time.time()
    while time.time() - t0 < timeout_s:
        data = client.get(url).json()
        if data.get(field) == target:
            return data
        if data.get(field) not in (busy,):
            print(f"Beklenmeyen durum: {data.get(field)} — {data.get('error')}")
            sys.exit(1)
        time.sleep(2)
    print("Zaman asimi:", url)
    sys.exit(1)


def main():
    token = get_token()
    check("Supabase auth (signup/signin)", bool(token))

    client = httpx.Client(
        base_url=API,
        headers={"Authorization": f"Bearer {token}"},
        timeout=httpx.Timeout(300, connect=10),
    )

    r = client.get("/study/stats")
    check("JWT dogrulama + DB erisimi (/study/stats)", r.status_code == 200, str(r.json()))

    # --- Dokuman yukleme ---
    with open(SAMPLE_PDF, "rb") as f:
        r = client.post("/documents", files={"file": ("sample_medical.pdf", f, "application/pdf")})
    check("PDF upload kabul (202)", r.status_code == 202, r.text[:120])
    doc_id = r.json()["id"]

    doc = poll(client, f"/documents/{doc_id}", "status", "ready", "processing")
    check(
        "Dokuman isleme (DIP upload)",
        doc["status"] == "ready" and doc["dip_doc_id"],
        f"{doc['page_count']} sayfa, has_text={doc['has_text']}",
    )
    pages = f"1-{doc['page_count']}"

    # --- Kart uretimi (offline, hizli) ---
    r = client.post(
        f"/documents/{doc_id}/generate/cards",
        json={"range": pages, "max_cards": 10, "enhance": False, "source": "auto"},
    )
    check("Kart uretimi istegi (202)", r.status_code == 202, r.text[:120])
    set_id = r.json()["id"]
    set_row = poll(client, f"/sets/{set_id}", "status", "ready", "generating")
    cards = set_row["cards"]
    check("Kartlar uretildi ve DB'ye yazildi", len(cards) > 0, f"{len(cards)} kart")

    # --- Quiz uretimi ---
    r = client.post(
        f"/documents/{doc_id}/generate/quiz",
        json={"range": pages, "n_questions": 3, "enhance": False, "source": "auto"},
    )
    check("Quiz uretimi istegi (202)", r.status_code == 202)
    quiz_id = r.json()["id"]
    quiz = poll(client, f"/quizzes/{quiz_id}", "status", "ready", "generating")
    check("Quiz sorulari uretildi", len(quiz["questions"]) > 0, f"{len(quiz['questions'])} soru")

    # --- Gorsel aday eslestirme + secim (Storage) ---
    card = cards[0]
    r = client.post(f"/cards/{card['id']}/match", json={"range": pages})
    check("Gorsel aday taramasi (/cards/match)", r.status_code == 200, f"matched={r.json().get('matched')}")
    cands = r.json().get("candidates", [])
    if cands:
        c0 = cands[0]
        img = client.get(c0["url"])
        check("Aday gorsel proxy (/dip-images)", img.status_code == 200,
              f"{len(img.content)} bayt, {img.headers.get('content-type')}")
        r = client.post(
            f"/cards/{card['id']}/select-image",
            json={"dip_doc_id": c0["dip_doc_id"], "path": c0["path"]},
        )
        check(
            "Gorsel secimi -> Supabase Storage",
            r.status_code == 200 and r.json().get("image_url"),
            r.json().get("image_url", "")[:90],
        )
        pub = httpx.get(r.json()["image_url"], timeout=30)
        check("Storage public URL erisilebilir", pub.status_code == 200, f"{len(pub.content)} bayt")
    else:
        print("[WARN] Bu PDF'te aday gorsel bulunamadi, gorsel adimi atlandi.")

    # --- SM-2 calisma akisi ---
    r = client.get(f"/study/due?set_id={set_id}")
    due = r.json()
    check("Vadesi gelen kartlar (/study/due)", due["total_due"] >= len(cards), f"{due['total_due']} kart")
    r = client.post("/study/reviews", json={"card_id": card["id"], "grade": 2})
    rev = r.json()
    check(
        "SM-2 review (grade=2 -> 1 gun)",
        r.status_code == 200 and rev["repetitions"] == 1 and rev["interval_days"] == 1.0,
        f"due_at={rev['due_at']}",
    )
    r = client.get(f"/study/due?set_id={set_id}")
    check("Calisilan kart kuyruktan dustu", r.json()["total_due"] == due["total_due"] - 1)

    print(f"\n=== E2E TAMAM: {ok_count} kontrol gecti ===")


if __name__ == "__main__":
    main()
