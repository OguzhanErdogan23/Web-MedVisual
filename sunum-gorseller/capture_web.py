# -*- coding: utf-8 -*-
"""MedVisual web ekran goruntusu yakalama. Playwright ile login + sayfa screenshots."""
import os
import sys
import time

from playwright.sync_api import sync_playwright

BASE = "http://localhost:5173"
EMAIL = "ogitogi@outlook.com.tr"
PASSWORD = "Ogitogi.55"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "web")
os.makedirs(OUT, exist_ok=True)

results = {}


def log(msg):
    print(f"[capture] {msg}", flush=True)


def shot(page, name, full_page=False):
    path = os.path.join(OUT, name)
    page.screenshot(path=path, full_page=full_page)
    results[name] = True
    log(f"OK -> {name}")


def safe(name, fn):
    try:
        fn()
    except Exception as e:  # noqa: BLE001
        results.setdefault(name, False)
        log(f"FAIL {name}: {type(e).__name__}: {e}")


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        ctx = browser.new_context(
            viewport={"width": 1440, "height": 900},
            device_scale_factor=2,
        )
        page = ctx.new_page()
        page.set_default_timeout(20000)

        # Onboarding turunu kapat (localStorage)
        page.goto(BASE, wait_until="domcontentloaded")
        try:
            page.evaluate("() => localStorage.setItem('medvisual_tour_done','1')")
        except Exception:
            pass

        # --- LOGIN ---
        login_ok = False
        try:
            page.goto(f"{BASE}/login", wait_until="networkidle")
            page.evaluate("() => localStorage.setItem('medvisual_tour_done','1')")
            page.fill("#email", EMAIL)
            page.fill("#password", PASSWORD)
            page.click("button[type=submit]")
            # dashboard: Panel basligi / nav bekle
            page.wait_for_url(f"{BASE}/", timeout=20000)
            page.wait_for_load_state("networkidle")
            time.sleep(2.5)
            login_ok = True
            log("LOGIN OK")
        except Exception as e:  # noqa: BLE001
            log(f"LOGIN FAIL: {type(e).__name__}: {e}")
            # yine de login sayfasinin ss'ini al
            safe("00-login.png", lambda: shot(page, "00-login.png"))

        results["__login__"] = login_ok
        if not login_ok:
            browser.close()
            return

        def goto(path, wait=2.5):
            page.goto(f"{BASE}{path}", wait_until="networkidle")
            time.sleep(wait)

        # 01 - Panel / Dashboard
        def cap_panel():
            goto("/", 3.0)
            shot(page, "01-panel.png")
        safe("01-panel.png", cap_panel)

        # 02 - Uretim sihirbazi: bir dokuman detayina git (Kart Uret)
        def cap_uretim():
            goto("/", 3.0)
            link = page.locator("a:has-text('Kart Üret')").first
            if link.count() > 0:
                link.click()
            else:
                # ilk dokuman linkine tikla
                page.locator("a[href*='/documents/']").first.click()
            page.wait_for_load_state("networkidle")
            time.sleep(3.0)
            shot(page, "02-uretim.png")
        safe("02-uretim.png", cap_uretim)

        # 03 - Gorselli deste detayi (gorsel kucuk resimleri OLAN, HAZIR deste)
        def open_set_and_check_images():
            """Acilan deste sayfasinda <img> (kart gorseli) var mi?"""
            page.wait_for_load_state("networkidle")
            time.sleep(3.0)
            # kart gorselleri: main icindeki img elemanlari (avatar/icon haric buyuk)
            imgs = page.locator("main img")
            return imgs.count() > 0

        def cap_deste():
            goto("/sets", 3.0)
            # Tum deste linklerini al; gorselli + cardCount>0 olani sec
            links = page.locator("a[href*='/sets/']")
            n = links.count()
            # Once basliginda 'gorselli' gecen ve '0 kart' OLMAYAN desteleri dene
            candidates_priority = []
            candidates_other = []
            for i in range(n):
                el = links.nth(i)
                try:
                    txt = (el.inner_text() or "").lower()
                except Exception:
                    txt = ""
                href = el.get_attribute("href") or ""
                has_gorselli = "gorselli" in txt or "görselli" in txt
                zero_cards = "0 kart" in txt
                generating = "üretiliyor" in txt or "uretiliyor" in txt
                if zero_cards or generating:
                    continue
                if has_gorselli:
                    candidates_priority.append(href)
                else:
                    candidates_other.append(href)
            tried = candidates_priority + candidates_other
            captured = False
            for href in tried:
                try:
                    page.goto(f"{BASE}{href}", wait_until="networkidle")
                    if open_set_and_check_images():
                        shot(page, "03-deste.png")
                        captured = True
                        break
                except Exception:
                    continue
            if not captured:
                # gorsel bulunamadi: yine de ilk gorselli/hazir desteyi goster
                if tried:
                    page.goto(f"{BASE}{tried[0]}", wait_until="networkidle")
                    time.sleep(3.0)
                    shot(page, "03-deste.png")
                else:
                    raise RuntimeError("uygun deste bulunamadi")
        safe("03-deste.png", cap_deste)

        # 04 - Calisma sayfasi (flashcard, cevirip notlari goster)
        def cap_calisma():
            goto("/study", 3.5)
            # bir kart varsa cevir
            try:
                card = page.locator("button:has-text('Cevabı Göster'), button:has-text('Göster'), [class*='cursor-pointer']").first
                if card.count() > 0:
                    card.click()
                    time.sleep(1.0)
            except Exception:
                pass
            # not butonlari gorunene kadar bekle (Tekrar/Zor/Iyi/Kolay)
            try:
                page.locator("button:has-text('Kolay'), button:has-text('İyi')").first.wait_for(timeout=6000)
            except Exception:
                pass
            time.sleep(1.5)
            shot(page, "04-calisma.png")
        safe("04-calisma.png", cap_calisma)

        # 05 - Quiz oynatici
        def cap_quiz():
            goto("/quizzes", 3.0)
            q = page.locator("a[href*='/quizzes/']").first
            if q.count() == 0:
                q = page.locator("button:has-text('Başla'), a:has-text('Başla')").first
            q.click()
            page.wait_for_load_state("networkidle")
            time.sleep(3.0)
            shot(page, "05-quiz.png")
        safe("05-quiz.png", cap_quiz)

        # 06 - Ayarlar
        def cap_ayarlar():
            goto("/ayarlar", 3.0)
            shot(page, "06-ayarlar.png")
        safe("06-ayarlar.png", cap_ayarlar)

        # 07 - Karanlik mod (dashboard)
        def cap_karanlik():
            goto("/", 3.0)
            page.locator("[aria-label='Tema değiştir']").first.click()
            time.sleep(1.5)
            shot(page, "07-karanlik.png")
        safe("07-karanlik.png", cap_karanlik)

        browser.close()


if __name__ == "__main__":
    main()
    print("\n=== SONUC ===", flush=True)
    for k, v in results.items():
        print(f"  {k}: {'OK' if v else 'FAIL'}", flush=True)
    ok = sum(1 for k, v in results.items() if v and not k.startswith('__'))
    print(f"Toplam basarili web ss: {ok}", flush=True)
