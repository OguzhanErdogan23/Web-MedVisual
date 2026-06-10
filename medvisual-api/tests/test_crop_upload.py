"""upload-image ucu (istemcide kirpilmis gorsel) duman testi."""
import io
import sys

import httpx

API = "http://localhost:8000"
SUPABASE_URL = "https://dwihzurpusgljdjnnquu.supabase.co"
PUBLISHABLE_KEY = "sb_publishable_Ge6Nq5wgcE54JVA0VN2ClQ_RhePrmNp"
EMAIL = "medvisual.e2e@example.com"
PASSWORD = "E2eTest!12345"


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
        timeout=60,
    )
    # Herhangi bir kart bul
    sets = client.get("/sets").json()["sets"]
    set_id = next(s["id"] for s in sets if s.get("card_count", 0) > 0)
    card = client.get(f"/sets/{set_id}").json()["cards"][0]

    # Minimal gecerli PNG (1x1) — kirpilmis gorsel yerine
    png = bytes.fromhex(
        "89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4"
        "890000000d49444154789c6360000002000154a24f0d0000000049454e44ae42"
        "6082"
    )
    r = client.post(
        f"/cards/{card['id']}/upload-image",
        files={"file": ("crop.png", io.BytesIO(png), "image/png")},
    )
    assert r.status_code == 200, r.text
    url = r.json().get("image_url")
    assert url, "image_url bos"
    pub = httpx.get(url, timeout=30)
    assert pub.status_code == 200, f"public url erisilemedi: {pub.status_code}"
    print(f"[PASS] Kirpilmis gorsel yukleme -> Storage — {url[:80]}")
    print(f"[PASS] Public URL erisilebilir — {len(pub.content)} bayt")
    print("=== upload-image TAMAM ===")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as e:
        print("[FAIL]", e)
        sys.exit(1)
