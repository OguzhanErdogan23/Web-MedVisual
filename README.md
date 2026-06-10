# MedVisual — Görsel Destekli Tıbbi Öğrenme Ekosistemi

Tıp öğrencileri PDF ders kaynaklarını yükler; sistem görüntü işleme ile
figürleri ayıklar, bilgi kartları ve quizler üretir, kartlara uygun görsel
adayları önerir. Kullanıcı doğruladığı görselleri karta ekler ve Aralıklı
Tekrar (SM-2) ile çalışır. Web ve mobil istemciler **feature parity** ile
aynı merkezi API'yi kullanır; veri **Single Source of Truth** prensibiyle
Supabase'de yaşar (cihazlar arası tam senkronizasyon).

## Mimari

```
                 ┌─────────────────────────────┐
                 │   Supabase (bulut, ücretsiz) │
                 │ PostgreSQL + Auth + Storage  │
                 └─────────────┬───────────────┘
                               │
                 ┌─────────────┴───────────────┐
                 │  medvisual-api  (FastAPI)    │  :8000 — Merkezi RESTful API
                 └───┬───────────────┬──────────┘
                     │               │ iç mikroservis
        ┌────────────┴───┐   ┌───────┴──────────────┐
        │ medvisual-web  │   │ medvisual-dip (Flask)│  :5000 — Görüntü işleme
        │ medvisual-mobile│  │ OCR · Segmentasyon · │
        └─────────────────┘  │ Gemini kart üretimi  │
                             └──────────────────────┘
```

| Modül | Ders | Teknoloji |
|---|---|---|
| `medvisual-dip` | Sayısal Görüntü İşleme | Python, OpenCV, Tesseract, Flask |
| `medvisual-api` + `medvisual-web` | Web Programlama | FastAPI, React+Vite+TS, Tailwind, TanStack Query |
| `medvisual-mobile` | Fonksiyonel Programlama | Flutter, BLoC, freezed (immutability + saf fonksiyonlar) |

## Kurulum (bir defalık)

1. **Sistem bağımlılıkları:** Tesseract OCR ve Poppler kurulu olmalı
   (DIP motorunun `run_server.bat`'i PATH'i kendisi ayarlar).
2. **Supabase:** ücretsiz proje açın → SQL Editor'de
   `medvisual-api/supabase/migration.sql` dosyasını çalıştırın →
   Authentication → Email → "Confirm email" **kapatın**.
3. **API anahtarları:** `medvisual-api/.env.example` → `.env` kopyalayıp
   Supabase URL + secret key girin. Web için `medvisual-web/.env.example`
   → `.env` (publishable key). DIP için `medvisual-dip/medvisual-dip/.env`
   içine `GOOGLE_API_KEY` (Gemini, opsiyonel).

## Çalıştırma (3 terminal)

```bat
:: 1) Görüntü işleme motoru (:5000)
medvisual-dip\medvisual-dip\run_server.bat

:: 2) Merkezi API (:8000) — Swagger: http://localhost:8000/docs
medvisual-api\run_api.bat

:: 3) Web (:5173)
medvisual-web\run_web.bat
```

**Mobil:** `medvisual-mobile` klasöründe
`flutter run --dart-define=API_BASE_URL=http://<PC-LAN-IP>:8000`
(Android emülatöründe define gerekmez, varsayılan `10.0.2.2:8000`).

Telefonun PC'deki API'ye erişebilmesi için Windows güvenlik duvarında
8000 portunu açın (yönetici PowerShell):

```powershell
netsh advfirewall firewall add rule name="MedVisual API" dir=in action=allow protocol=TCP localport=8000
```

## Testler

```bat
:: SM-2 birim testleri (Python)
cd medvisual-api && .venv\Scripts\python -m pytest

:: Uçtan uca duman testi (DIP + API + Supabase ayakta olmalı)
cd medvisual-api && .venv\Scripts\python tests\e2e_smoke.py

:: Web build doğrulaması
cd medvisual-web && npm run build

:: Mobil analiz + SM-2 Dart testleri
cd medvisual-mobile && flutter analyze && flutter test
```

## Demo senaryosu (SSOT kanıtı)

1. Web'de kayıt ol, PDF yükle (veya Kütüphane'den hazır kitap),
   sayfa aralığı seçip kart üret.
2. Bir karta "Görsel Bul" ile aday tarat, görsel seç.
3. Mobilde aynı hesapla gir → set anında görünür → swipe ile çalış.
4. Web'i yenile → çalışma ilerlemesi (due tarihler) mobildekiyle aynı.

## Notlar

- PDF'ler buluta yüklenmez; DIP motorunun `work/` dizininde lokal kalır
  (ücretsiz kota disiplini). `work/` silinirse doküman "Süresi doldu"
  durumuna düşer ve yeniden yükleme istenir; kartlar ve seçilmiş
  görseller etkilenmez (Storage'dadır).
- Supabase ücretsiz projeleri ~1 hafta inaktivitede uyur; demo öncesi
  dashboard'dan uyandırın.
