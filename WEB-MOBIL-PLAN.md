# MedVisual — Web + Mobil Geliştirme Planı

> **Not:** Onay sonrası bu plan `C:\Users\ogito\Desktop\3 proje\WEB-MOBIL-PLAN.md` olarak proje klasörüne kaydedilecek (implementasyon başka bir modelde yapılacak).

## Context

MedVisual 3 ders için geliştirilen bir ekosistem: tıp öğrencileri PDF yükler, görüntü işleme motoru (DIP) figürleri ayıklar, bilgi kartı + quiz üretilir, kullanıcı kartlara görsel adaylarını doğrulayarak ekler ve Aralıklı Tekrar (SM-2) ile çalışır.

- **Ders A (TAMAM):** Sayısal Görüntü İşleme — `medvisual-dip` Flask motoru hazır ve tek başına teslim edildi. **Dokunulmayacak**, FastAPI tarafından `http://localhost:5000` üzerinden iç mikroservis olarak çağrılacak.
- **Ders B (YAPILACAK):** Web Programlama — React frontend + **FastAPI merkezi RESTful API**.
- **Ders C (YAPILACAK):** Fonksiyonel Programlama — **Flutter** mobil uygulama (immutability, pure functions, BLoC).

**Kesinleşen kararlar (kullanıcı onaylı):** Flutter (Dart) · Supabase (ücretsiz, PostgreSQL+Auth+Storage = Single Source of Truth) · FastAPI.

**Ücretsizlik disiplini:**
- PDF'ler Supabase'e **yüklenmez** (250MB'lık dosyalar 1GB kotayı bitirir) → PDF'ler DIP motorunun lokal `work/` dizininde kalır, DB'de sadece metadata + `dip_doc_id` tutulur.
- Görsel adayları **geçicidir** (oluşturma oturumunda DIP'ten proxy ile gösterilir); yalnızca kullanıcının **seçtiği** final görsel (küçük PNG) Supabase Storage'a yüklenir.
- Asenkron kuyruk için Redis/Celery yok → FastAPI `BackgroundTasks` + DB'de status alanı + istemci polling.
- Backend + DIP motoru kullanıcının Windows makinesinde lokal çalışır; telefon aynı Wi-Fi'dan LAN IP ile erişir. Supabase bulutta olduğu için veri cihazlar arası senkron kalır.

## Mimari

```
                 ┌─────────────────────────────┐
                 │   Supabase (bulut, ücretsiz) │
                 │ PostgreSQL + Auth + Storage  │
                 └─────────────┬───────────────┘
                               │ (service_role / JWT doğrulama)
                 ┌─────────────┴───────────────┐
                 │  medvisual-api  (FastAPI)    │  ← Merkezi RESTful API, :8000
                 └───┬───────────────┬──────────┘
                     │ HTTP          │ HTTP (iç mikroservis)
        ┌────────────┴───┐   ┌───────┴──────────────┐
        │ İstemciler      │   │ medvisual-dip (Flask)│  ← Ders A, dokunma, :5000
        │ Web (React)     │   │ OCR/Segmentasyon/    │
        │ Mobil (Flutter) │   │ Gemini kart üretimi  │
        └─────────────────┘   └──────────────────────┘
```

İstemciler **auth için** Supabase'e doğrudan bağlanır (supabase-js / supabase_flutter, ücretsiz JWT yönetimi + auto-refresh); **tüm veri işlemleri** FastAPI üzerinden geçer (Web dersinin "RESTful API katmanı" gereksinimi + SSOT tutarlılığı). FastAPI her istekte Supabase JWT'sini doğrular.

## Klasör Yapısı (monorepo: `C:\Users\ogito\Desktop\3 proje\`)

```
3 proje/
├── medvisual-dip/        # MEVCUT — dokunulmayacak
├── medvisual-api/        # YENİ — FastAPI (Ders B backend)
├── medvisual-web/        # YENİ — React + Vite (Ders B frontend)
├── medvisual-mobile/     # YENİ — Flutter (Ders C)
└── WEB-MOBIL-PLAN.md     # bu plan
```

---

## Faz 0 — Supabase Kurulumu (yarı manuel)

1. Kullanıcı supabase.com'da ücretsiz proje açar; `SUPABASE_URL`, `anon key`, `service_role key`, `JWT secret` alınır (Settings → API).
2. Migration SQL'i repo'da tutulur: `medvisual-api/supabase/migration.sql` — kullanıcı SQL Editor'e yapıştırır.
3. Storage'da `card-images` bucket'ı (public read) oluşturulur.

### Şema (migration.sql özü)

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz default now()
);

create table documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  dip_doc_id text,                      -- DIP motorundaki work/ kimliği
  filename text not null,
  page_count int,
  has_text boolean,
  status text not null default 'processing'
    check (status in ('processing','ready','failed','expired')),
  error text,
  created_at timestamptz default now()
);

create table flashcard_sets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id uuid references documents(id) on delete set null,
  title text not null,
  description text,
  status text not null default 'ready'
    check (status in ('generating','ready','failed')),  -- kart üretimi arka planda
  created_at timestamptz default now()
);

create table flashcards (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references flashcard_sets(id) on delete cascade,
  user_id uuid not null,
  front text not null,
  back text not null,
  term text, kind text, page int,
  image_url text,                       -- seçilen görsel (Storage public URL)
  position int default 0,
  created_at timestamptz default now()
);

create table quizzes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  document_id uuid references documents(id) on delete set null,
  title text,
  status text not null default 'ready'
    check (status in ('generating','ready','failed')),
  created_at timestamptz default now()
);

create table quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references quizzes(id) on delete cascade,
  question text not null,
  options jsonb not null,               -- 4 şık
  answer_index int not null,
  position int default 0
);

-- SM-2 aralıklı tekrar durumu (kart başına tek satır)
create table card_reviews (
  card_id uuid primary key references flashcards(id) on delete cascade,
  user_id uuid not null,
  ease_factor real not null default 2.5,
  interval_days real not null default 0,
  repetitions int not null default 0,
  due_at timestamptz not null default now(),
  last_grade int,
  updated_at timestamptz default now()
);
```

Tüm tablolarda RLS aktif + `user_id = auth.uid()` policy'leri (backend service_role ile çalıştığı için RLS'i bypass eder ama savunma katmanı + ders puanı olarak kalır). Backend zaten her sorguda JWT'den gelen `user_id` ile filtreler (sahiplik kontrolü).

---

## Faz 1 — FastAPI Backend (`medvisual-api/`)

### Yapı

```
medvisual-api/
├── app/
│   ├── main.py          # FastAPI app, CORS, router kayıtları
│   ├── config.py        # env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
│   │                    #      SUPABASE_JWT_SECRET, DIP_ENGINE_URL=http://localhost:5000
│   ├── deps.py          # get_current_user: Bearer token → PyJWT (HS256, aud="authenticated")
│   ├── db.py            # supabase-py client (service_role)
│   ├── dip_client.py    # httpx ile DIP motoru sarmalayıcı (upload, generate, match, work-image fetch)
│   ├── sm2.py           # saf SM-2 fonksiyonu (aşağıda imza)
│   ├── schemas/         # pydantic request/response modelleri
│   └── routers/
│       ├── documents.py  ├── books.py    ├── sets.py
│       ├── cards.py      ├── quizzes.py  ├── study.py
│       └── proxy.py
├── supabase/migration.sql
├── requirements.txt     # fastapi, uvicorn, httpx, supabase, pyjwt, python-dotenv, python-multipart
├── .env.example
└── run_api.bat          # venv aktive + uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**DB erişimi kararı:** `supabase-py` (PostgREST) + service_role key. Gerekçe: tek bağımlılıkla DB + Storage; SQLAlchemy/asyncpg'nin getireceği bağlantı yönetimi yükü bu ölçekte gereksiz. Sahiplik her sorguda `eq("user_id", user.id)` ile zorlanır.

### Endpoint'ler (hepsi `Authorization: Bearer <supabase access token>` ister, /health hariç)

| Endpoint | Açıklama |
|---|---|
| `GET /health` | API + DIP motoru (`/api/health` proxy) + Supabase erişim durumu |
| `POST /documents` (multipart pdf) | DB'ye `processing` satırı yaz → **BackgroundTask:** DIP `/api/upload`'a ilet → `dip_doc_id, page_count, has_text, status=ready` güncelle |
| `GET /documents` · `GET /documents/{id}` | Liste / tekil (istemci status polling burada) |
| `DELETE /documents/{id}` | Satır sil (DIP work/ dosyası lokalde kalabilir) |
| `GET /books` · `POST /books/load` | DIP'in hazır kitap kütüphanesi proxy'si; load → documents satırı oluşturur |
| `POST /documents/{id}/generate/cards` | Body: `{range, max_cards, enhance, source, set_title}` → `flashcard_sets(status=generating)` oluştur, **BackgroundTask:** DIP `/api/generate/cards` → kartları `flashcards`'a yaz → `status=ready` |
| `POST /documents/{id}/generate/quiz` | Aynı desen, `quizzes` + `quiz_questions` |
| `POST /cards/import` (multipart) | DIP `/api/cards/import` proxy → yeni set + kartlar DB'ye |
| `POST /cards/{id}/match` | Body: `{range}` → kartın dokümanının `dip_doc_id`'siyle DIP `/api/cards/match` → adaylar **proxy URL'leriyle** döner |
| `GET /dip-images/{dip_doc_id}/{path}` | DIP `/work/...` görselini stream eder (sahiplik kontrolü: dip_doc_id kullanıcının bir documents satırına ait mi) |
| `POST /cards/{id}/select-image` | Body: `{candidate_path}` → PNG'yi DIP'ten indir → Storage `card-images/{user_id}/{card_id}.png`'e yükle → `flashcards.image_url` set et |
| `GET/POST/PATCH/DELETE /sets`, `/sets/{id}` · `GET/POST /sets/{id}/cards` · `PATCH/DELETE /cards/{id}` | Standart CRUD |
| `GET /quizzes` · `GET /quizzes/{id}` (sorularıyla) · `DELETE /quizzes/{id}` | Quiz CRUD |
| `GET /study/due?set_id=` | `card_reviews.due_at <= now()` olan + hiç review'i olmayan kartlar |
| `POST /study/reviews` | Body: `{card_id, grade}` (0–3: again/hard/good/easy) → **sunucu** SM-2 uygular, yeni review durumunu döner |
| `GET /stats` | Dashboard sayaçları (doküman/set/kart/bugün due) |

### SM-2 kararı (SSOT)

**API otoritedir:** `app/sm2.py` saf fonksiyon `apply_sm2(state, grade, now) -> state` sunucuda çalışır ve DB'ye yazar. Flutter tarafında **aynı algoritma** Dart saf fonksiyonu olarak da yazılır (Ders C'nin pure-function vitrini + optimistic UI; deterministik olduğu için sunucu sonucuyla birebir aynı çıkar). Çakışma riski yok çünkü yazma tek yerden (API) yapılır.

```python
@dataclass(frozen=True)
class ReviewState:
    ease_factor: float; interval_days: float; repetitions: int; due_at: datetime

def apply_sm2(state: ReviewState, grade: int, now: datetime) -> ReviewState: ...
# grade<2 → repetitions=0, interval=0 (10 dk sonra tekrar); grade>=2 → klasik SM-2 (1, 6, sonra interval*EF)
```

**CORS:** `allow_origins=["http://localhost:5173", "http://<LAN-IP>:5173"]` (mobil native istekler CORS'a takılmaz).

---

## Faz 2 — Web (`medvisual-web/`)

**Stack:** Vite + React 18 + TypeScript + Tailwind CSS + TanStack Query + react-router + supabase-js (sadece auth). Next.js bilinçli olarak alınmadı: lokal demo, SSR katkısız, Vite kurulumu/sunumu daha basit.

### Sayfalar / akışlar

```
src/
├── lib/supabase.ts      # createClient (anon key) — yalnızca auth
├── lib/api.ts           # fetch sarmalayıcı: session.access_token'ı Bearer ekler
├── hooks/               # useDocuments, useSets, useStudy... (TanStack Query)
├── pages/
│   ├── Login.tsx / Register.tsx     # supabase.auth.signInWithPassword / signUp
│   ├── Dashboard.tsx                # doküman listesi + durum rozetleri (processing→polling),
│   │                                # sürükle-bırak PDF upload, hazır kitap kütüphanesi
│   ├── DocumentDetail.tsx           # üretim sihirbazı: kart/quiz seçimi, sayfa aralığı,
│   │                                # max kart, Gemini enhance toggle → üretim başlat → set'e yönlendir
│   ├── Sets.tsx / SetDetail.tsx     # kart listesi (flip önizleme), düzenle/sil,
│   │                                # kart başına "🔎 Görsel bul" → CandidateModal
│   ├── StudyPage.tsx                # SRS: due kartlar, flip animasyonu,
│   │                                # Again/Hard/Good/Easy butonları → POST /study/reviews
│   └── QuizPage.tsx                 # soru/şık, cevap reveal, skor özeti
└── components/
    ├── UploadDropzone, DocumentCard, StatusBadge
    ├── CandidateModal               # /cards/{id}/match adayları carousel; seçim → select-image
    ├── FlashcardFlip, GradeButtons, QuizQuestion
```

**Polling deseni:** TanStack Query `refetchInterval: (q) => q.state.data?.status === 'processing' ? 2500 : false` — hem documents hem set/quiz `generating` durumları için.

---

## Faz 3 — Mobil (`medvisual-mobile/`, Flutter)

**Paketler:** `flutter_bloc`, `freezed` + `json_serializable` (immutable modeller), `supabase_flutter` (auth), `dio` (API + multipart upload), `go_router`, `file_picker`, `flutter_card_swiper`.

### Yapı (feature-first, FP vitrini)

```
lib/
├── core/
│   ├── api_client.dart        # dio + Supabase token interceptor
│   └── config.dart            # API_BASE_URL: --dart-define ile
│                              # (emülatör: http://10.0.2.2:8000, gerçek cihaz: http://<LAN-IP>:8000)
├── features/
│   ├── auth/        (bloc, login/register ekranları — supabase_flutter)
│   ├── documents/   (upload + polling bloc, doküman listesi, üretim sihirbazı)
│   ├── sets/        (set/kart listesi, kart düzenleme, görsel aday seçimi)
│   ├── study/
│   │   ├── domain/
│   │   │   ├── review_state.dart   # freezed immutable model
│   │   │   └── sm2.dart            # SAF FONKSİYON: ReviewState applySm2(ReviewState, Grade, DateTime)
│   │   │                           # — yan etkisiz, unit testli (Ders C'nin ana vitrini)
│   │   └── presentation/           # swipe tabanlı çalışma ekranı (CardSwiper), flip, grade
│   └── quiz/        (quiz player bloc + ekran)
└── test/sm2_test.dart              # saf fonksiyon unit testleri (derste gösterilecek)
```

**FP ilkeleri sunum noktaları:** tüm state'ler freezed (immutable, `copyWith`), BLoC event→state dönüşümleri saf, SM-2 + due-filtreleme + istatistik hesapları `domain/` altında yan etkisiz fonksiyonlar, UI tamamen deklaratif.

**Feature parity:** PDF yükleme (file_picker → dio multipart), durum polling, kart/quiz üretimi, görsel aday doğrulama, çalışma + quiz — webdekiyle birebir aynı API.

---

## Uygulama Sırası (milestone'lar)

| # | Milestone | Teslimat |
|---|---|---|
| 0 | Plan dosyasını proje klasörüne kaydet (`WEB-MOBIL-PLAN.md`) | dosya |
| 1 | Supabase projesi + `migration.sql` + bucket | çalışan şema |
| 2 | FastAPI iskelet: auth deps, /health, documents upload→DIP→ready akışı | Swagger `/docs` + curl ile doğrulanmış pipeline |
| 3 | Üretim uçları (cards/quiz/import) + match + select-image + CRUD + study/SM-2 | tam API yüzeyi |
| 4 | Web: auth + dashboard + upload/polling | giriş yapılıp PDF işlenebiliyor |
| 5 | Web: üretim sihirbazı + set/kart + görsel doğrulama + study + quiz | web feature-complete |
| 6 | Flutter: auth + dokümanlar + üretim | mobil çekirdek |
| 7 | Flutter: study (swipe/SM-2) + quiz + görsel doğrulama | feature parity |
| 8 | Uçtan uca test: gerçek 600 sayfalık dokümanla web'de set oluştur → mobilde çalış (senkron kanıtı) | demo senaryosu |

## Doğrulama

- **API:** her milestone'da Swagger `/docs` + curl; SM-2 için pytest (`apply_sm2` saf fonksiyon tabloları).
- **Web:** manuel E2E: kayıt → PDF yükle → status polling → kart üret (enhance açık/kapalı) → görsel aday seç → study'de grade ver → due_at değişimini kontrol et.
- **Mobil:** `flutter test` (sm2_test.dart + model testleri); gerçek cihazda LAN üzerinden aynı E2E; **senkron testi:** webde oluşturulan set mobilde anında görünmeli (SSOT kanıtı).
- **DIP entegrasyonu:** DIP motoru kapalıyken API'nin düzgün hata dönmesi (`/health` degraded, upload → status=failed + error mesajı).

## Riskler / Dikkat

- **DIP `work/` kalıcı değil:** motor yeniden başlasa da dosyalar durur ama klasör silinirse `dip_doc_id` ölür → match/analyze 404 dönerse API dokümanı `status=expired` yapar; UI "yeniden yükle" akışı sunar. Kartlar/görseller etkilenmez (Storage'da).
- **Supabase free tier:** 1 hafta inaktivitede proje uyur → demo öncesi dashboard'dan uyandır. 500MB DB + 1GB storage bu kullanım için bol.
- **Windows güvenlik duvarı:** telefonun erişimi için 8000 portuna inbound izin (`netsh advfirewall firewall add rule ... localport=8000`). DIP'in 5000 portu dışa açılmaz (sadece API erişir).
- **Uzun üretim süreleri:** Gemini'li kart üretimi dakikalar sürebilir → hep BackgroundTask + status polling; HTTP timeout'ları `httpx.Timeout(300)` ile geniş tutulur.
- **JWT süresi:** istemci SDK'ları auto-refresh yapar; API sadece doğrular, sorun yok.
- **Gemini 429:** DIP motoru zaten backoff'lu + offline fallback'li; API `llm_enhanced=false` bilgisini UI'da rozet olarak gösterir.
