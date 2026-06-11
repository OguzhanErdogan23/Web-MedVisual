# MedVisual — Kapsamlı Denetim Raporu ve Uygulama Yol Haritası

> **Tarih:** 11 Haziran 2026 · **Hazırlayan:** Claude (Fable 5) — çok ajanlı denetim oturumu
> **Hedef:** Yarınki sunum öncesi web + mobil + API'nin hatasız ve eksiksiz hale getirilmesi.
> **Bu rapor, implementasyonu yapacak modele eksiksiz talimat verecek şekilde yazılmıştır.**
> **Makine okunur tam bulgu eki:** `DENETIM-BULGULARI.json` (aynı dizinde — her bulgunun tam kanıtı,
> doğrulayıcı açıklamaları ve 40 iyileştirme önerisinin tamamı oradadır).

---

## İÇİNDEKİLER

- **A.** Uygulayıcı model için zorunlu talimatlar (önce bunu oku)
- **B.** Mimari ve çalışma düzeni — bu oturumda öğrenilen her şey
- **C.** Denetim metodolojisi ve yönetici özeti
- **D.** YOL HARİTASI — fazlar, sıra, kabul kriterleri
- **E.** Doğrulanmış 50 bulgu (C1–C50) — dosya:satır + düzeltme talimatı
- **F.** Belirsiz 16 bulgu (U1–U16) — uygulayıcı kararı + tavsiyem
- **G.** Onaylanmış yeni özellik spesifikasyonları (kullanıcı seçti)
- **H.** İyileştirme önerileri (seçilmiş öncelikliler)
- **I.** Bekleyen görevler ve sunum günü kontrol listesi

---

# A. UYGULAYICI MODEL İÇİN ZORUNLU TALİMATLAR

## A.1 Ortam

- **OS:** Windows 10 Pro, kabuk **PowerShell 5.1** (`&&` çalışmaz; `;` veya `if ($?)` kullan).
- **Monorepo kökü:** `C:\Users\ogito\Desktop\3 proje`
- Bileşenler:
  - `medvisual-api/` — FastAPI backend (Python, venv: `medvisual-api\.venv`)
  - `medvisual-web/` — React 19 + Vite 8 + TypeScript 6 + Tailwind 4 + TanStack Query 5
  - `medvisual-mobile/` — Flutter (flutter_bloc, freezed, go_router, dio, supabase_flutter)
  - `medvisual-dip/` — Flask görüntü işleme motoru. **ASLA DOKUNMA** (ayrı ders teslimi, PRD şartı).
- PRD/plan: `WEB-MOBIL-PLAN.md` (kökte). Önceki özet: `proje özet.md`.

## A.2 Kesin kurallar

1. **`medvisual-dip/` klasörüne hiçbir değişiklik yapma.** API ona yalnızca HTTP ile bağlanır (`:5000`).
2. **SM-2 otoritesi sunucudur** (`medvisual-api/app/sm2.py`). Mobil kopya (`lib/features/study/domain/sm2.dart`)
   onunla **birebir aynı** kalmalı. Birinde formül değişirse diğerinde de değiştir + iki tarafın testlerini güncelle.
3. **API kontratı iki istemciyi birden bağlar.** Bir endpoint'in yanıt şeklini değiştirirsen hem
   `medvisual-web/src` hem `medvisual-mobile/lib` taraflarını aynı anda güncelle.
4. **UI metinleri tam Türkçe (diyakritikli: "Vazgeç", "Çalış")** olacak — bulgu C50 bunu şart koşuyor.
   Kod yorumları mevcut stile uyar (çoğunlukla ASCII Türkçe; olduğu gibi bırakabilirsin).
5. **Mobilde freezed:** `*.freezed.dart` / `*.g.dart` üretilmiş dosyalardır, elle düzenleme. Model/state
   sınıfı değiştirirsen şunu çalıştır:
   `Push-Location "C:\Users\ogito\Desktop\3 proje\medvisual-mobile"; dart run build_runner build --delete-conflicting-outputs; Pop-Location`
6. **Supabase şema değişikliği yarı manueldir:** migration SQL'ini `medvisual-api/supabase/` altına yeni
   dosya olarak ekle (örn. `migration_03.sql`) ve **kullanıcıya Supabase SQL Editor'de çalıştırmasını
   açıkça söyle**. Otomatik uygulanamaz (service-role ile DDL çalıştırılmıyor).
7. **Commit:** Küçük, konu başına commit'ler at (mevcut alışkanlık: Türkçe, kısa özet satırı). **Push etme**,
   kullanıcı istemedikçe.
8. Her fazdan sonra **A.3'teki doğrulama komutlarının tamamını** çalıştır; kırmızı varken sonraki faza geçme.

## A.3 Doğrulama komutları (baseline ŞU AN HEPSİ YEŞİL)

```powershell
# 1) API birim testleri (10/10 geçiyor)
Push-Location "C:\Users\ogito\Desktop\3 proje\medvisual-api"
& ".\.venv\Scripts\python.exe" -m pytest tests\test_sm2.py -q
Pop-Location
# NOT: tests/ altındaki e2e_*.py, drive_*, gen_*, seed_* dosyaları canlı sunucu + Supabase ister; CI'da KOŞMA.

# 2) Web tip kontrolü + build (temiz; tek uyarı: 570KB chunk — zararsız)
Push-Location "C:\Users\ogito\Desktop\3 proje\medvisual-web"; npm run build; Pop-Location

# 3) Mobil analiz + testler (analyze temiz, 11/11 test geçiyor)
Push-Location "C:\Users\ogito\Desktop\3 proje\medvisual-mobile"; flutter analyze; flutter test; Pop-Location
```

## A.4 Uygulamayı ayağa kaldırma ve telefon

- **`BASLAT.bat`** (kökte): DIP (:5000) → API (:8000) → Web (:5173) sırayla açar, `adb reverse` kurar,
  tarayıcıyı açar. Servis bat'leri: `medvisual-api/run_api.bat`, `medvisual-web/run_web.bat`.
- **Telefon:** Samsung **SM M336B** (Android 16) USB ile bağlı, cihaz ID `R6CT4009ZLD`.
  `TELEFON-BAGLA.bat` = `adb reverse tcp:8000 tcp:8000` (telefon 127.0.0.1:8000 → PC API).
- **Mobil derleme/kurulum (test için):**
  ```powershell
  Push-Location "C:\Users\ogito\Desktop\3 proje\medvisual-mobile"
  flutter build apk --release --dart-define=API_BASE_URL=http://127.0.0.1:8000
  adb -s R6CT4009ZLD install -r build\app\outputs\flutter-apk\app-release.apk
  adb reverse tcp:8000 tcp:8000
  Pop-Location
  ```
  (`lib/core/config.dart` varsayılanı `10.0.2.2` = emülatör; gerçek cihazda dart-define ŞART.)
- API env: `medvisual-api/.env` → `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`
  (yoksa JWKS), `DIP_ENGINE_URL`, `GOOGLE_API_KEY` (Gemini), `GEMINI_MODELS` (ops., virgüllü zincir).

---

# B. MİMARİ VE ÇALIŞMA DÜZENİ (öğrenilenler)

- **Akış:** İstemciler auth için doğrudan Supabase'e (JWT, otomatik yenileme), **tüm veri işlemleri**
  FastAPI (:8000) üzerinden. FastAPI her istekte JWT doğrular (`app/deps.py`: HS256 sır varsa o, yoksa
  JWKS ES256/RS256, `aud=authenticated`, 90 sn leeway) ve Supabase'e **service-role** ile yazar
  (RLS bypass — sahiplik her sorguda `eq("user_id", ...)` ile elle zorlanır, `helpers.get_owned_row`).
- **PDF'ler Supabase'e yüklenmez** (ücretsizlik disiplini) — DIP motorunun lokal `work/` dizininde yaşar;
  DB'de `dip_doc_id` + metadata. Görsel adayları geçici olarak `/dip-images/{dip_doc_id}/{path}` proxy'si
  ile sunulur (`?token=` query parametresi de kabul edilir çünkü `<img>` başlık gönderemez).
  Seçilen görsel Storage `card-images/{user_id}/{card_id}.png` yoluna upsert edilir (public URL).
- **Uzun işler:** FastAPI `BackgroundTasks` + DB'de `status` (processing/generating/ready/failed/expired)
  + istemci 2,5 sn polling. Kuyruk yok (Redis/Celery bilinçli alınmadı).
- **Gemini zenginleştirme:** `app/gemini.py` — model fallback zinciri (varsayılan:
  gemini-3-flash-preview → 2.5-flash → 2.5-flash-lite → flash-lite-latest → 2.0-flash-lite → 2.0-flash);
  429/hata → sonraki model; hiçbiri çalışmazsa DIP'in offline kartlarına düşülür.
- **SM-2:** grade 0–3 (again/hard/good/easy) → kalite 2/3/4/5; again=10 dk, ilk aralıklar 1 ve 6 gün,
  sonra `interval*EF` (2 ondalık); hard çarpanı 0.6 (min 1 gün); MIN_EASE 1.3. Web yerel hesap YAPMAZ
  (yalnız sunucu); mobil optimistic UI için saf Dart kopyası kullanır.
- **Dışa aktarma:** `app/exporters.py` — CSV/TSV(Anki)/JSON/PDF/APKG (genanki yoksa zip fallback).
- **Mobil mimari:** feature-first; freezed immutable state; BLoC'lar emitter kullanır (kapanışta güvenli),
  Cubit'ler doğrudan emit eder (kapanışta StateError riski — bulgu C8/C22). `guardApi` tüm repo hatalarını
  Türkçe mesajlı `ApiException`'a çevirir. Router: go_router, auth redirect'li.
- **Web mimarisi:** TanStack Query (polling: `refetchInterval` status'a bağlı), `lib/api.ts` fetch
  sarmalayıcı (timeout'lu AbortController, `detail` ayrıştırma), supabase-js yalnız auth.
- **Supabase projesi:** `https://dwihzurpusgljdjnnquu.supabase.co` (anahtar config.dart'ta publishable).
- **`review_events` tablosu migration_02 ile gelir** — yoksa `/study/history` `needs_migration:true` döner.
  Isı haritası özelliği bu tabloya bağımlı; sunum öncesi migration'ın uygulandığını DOĞRULA.

---

# C. DENETİM METODOLOJİSİ VE YÖNETİCİ ÖZETİ

## C.1 Nasıl çalışıldı

- **156 alt-ajan, ~5,6M token, 58 dakika** süren çok ajanlı workflow.
- **8 paralel denetim boyutu:** backend doğruluk · backend güvenlik · web doğruluk · web↔API kontrat ·
  mobil doğruluk · mobil↔API kontrat · SM-2 paritesi · UX/PRD paritesi. Her denetçi dosyaları satır satır okudu.
- **Her bulgu 2 bağımsız doğrulayıcıdan geçti:** biri bulguyu **çürütmeye** çalıştı (kodu kendisi okuyarak),
  diğeri **gerçek kullanıcı akışında oluşup oluşmayacağını** izledi. Bazı doğrulayıcılar iddiaları Python/Dart
  çalıştırarak sayısal olarak test etti (ör. yuvarlama sapması 200k simülasyonla kanıtlandı).
- Sonuç: **50 doğrulanmış bulgu**, 16 belirsiz (tek doğrulayıcı onayı), **8 yanlış pozitif çürütülüp elendi**
  (ör. "RLS bypass tek katman" iddiası PRD'de bilinçli karar olarak belgeli; "token=null" URL iddiası ölü kod yolu).
- Ayrıca üç projenin testleri/derlemeleri koşuldu (hepsi yeşil) ve çekirdek dosyalar elle okundu.

## C.2 Genel durum

Proje **sağlam temelli**: derleme/test yeşil, auth doğru (JWT imzası gerçekten doğrulanıyor), sahiplik
kontrolleri tutarlı, IDOR/SQL injection bulunamadı, kontratlar büyük ölçüde uyumlu. Sorunlar ağırlıkla
**dayanıklılık** (arka plan işi çökünce sonsuz 'generating', LLM çıktısı tek alanda bozuksa tüm işin
çökmesi), **hata görünürlüğü** (sonsuz spinner, yanıltıcı boş ekranlar), **yaşam döngüsü** (kapanmış
Cubit'e emit, route değişiminde sıfırlanmayan state) ve **istemciler arası tutarsızlık** sınıfında.

## C.3 Sunum için en kritik 10 (önce bunlar)

| # | Bulgu | Neden demo-kritik |
|---|---|---|
| C1 | Oto-görsel işi hatada seti sonsuz 'generating' bırakıyor | Demo sırasında set kilitlenir, kurtarma yolu yok |
| C2 | Tek bozuk LLM alanı TÜM quiz üretimini 'failed' yapıyor | Gemini'li quiz demosu çökebilir |
| C4 | Study hata durumu = sonsuz spinner | API tökezlerse ekran kilitli görünür |
| C8 | Mobil görsel arama sırasında sheet kapatılınca StateError | Canlı demoda crash görüntüsü |
| C11 | Mobil koyu temada beyaz üstüne beyaz yazı | Telefon koyu temadaysa çalışma ekranı okunmaz |
| C20/C27 | Web formu 121-200 kart kabul edip 422 ham JSON basıyor | Sunumda utandırıcı hata |
| C3 | PDF dışa aktarmada ğ/ş/ı/İ → '?' | Türkçe içerik demosunda görünür bozulma |
| C5 | Çıkışta React Query önbelleği temizlenmiyor | Hesap değiştirme demosunda eski verinin görünmesi |
| C6 | Görsel token'ı 1 saatte ölüyor | Uzun prova/sunum oturumunda görseller kırılır |
| C25 | Quiz yeniden adlandırınca soru sayısı 0 görünüyor | Küçük ama hemen göze çarpar |

---

# D. YOL HARİTASI (uygulama sırası — değiştirme)

> Her fazın sonunda **A.3 komutlarının üçü de yeşil** olmalı + fazın kendi kabul kriterleri sağlanmalı.
> Süreler tahminidir; sıra önceliği yansıtır: önce demo-kritik düzeltmeler, sonra onaylı özellikler,
> sonra sağlamlaştırma. Güvenlik fazı sunumdan sonraya bırakılabilir.

## Faz 0 — Hazırlık (10 dk)
1. `git status` temizliği umursamadan yeni dal AÇMA — kullanıcı main üzerinde çalışıyor; main'de kal.
2. A.3 baseline'ı koş, üçünün de yeşil olduğunu teyit et (şu an öyle).

## Faz 1 — Backend P0 düzeltmeleri (~1 saat)
**Bulgular:** C1, C2, C3, C7 (C28'in sunucu yarısı), C21, C40 + U3 (önerilir).
**Kabul:** pytest yeşil; `_auto_images_job` hatada `status='failed'` yazıyor; geçersiz `answer_index`
quiz işini düşürmüyor (offline'a düşüyor); PDF exportta "ğşıİ" doğru basılıyor (elle 1 export dene);
`PATCH /cards/{id}` `term:null`'u temizleme olarak işliyor; `/study/history` `total_reviews` pencereyle uyumlu;
`expose_headers=["Content-Disposition"]` eklendi.

## Faz 2 — Web P0 düzeltmeleri (~1,5 saat)
**Bulgular:** C4, C5, C6, C16, C17, C18, C19, C20, C28 (istemci yarısı), C38, C39, C49 + U7 (önerilir).
**Kabul:** `npm run build` yeşil; Study'de API hatası anlamlı mesaj + "Tekrar dene" gösteriyor;
çıkış → `queryClient.clear()`; görseller token yenilemeli/AuthImage'lı; form max'ları 120/40;
422 detail dizisi okunur Türkçe mesaja çevriliyor (`lib/api.ts`).

## Faz 3 — Mobil P0 düzeltmeleri (~2 saat)
**Bulgular:** C8, C22 (ortak `safeEmit` ile), C11, C23, C24, C25, C29, C30, C31, C32, C41, C42, C43,
C48, C50, C10.
**Kabul:** `flutter analyze` + `flutter test` yeşil; koyu temada çalışma kartı/aday kartı/istatistik
çipleri okunaklı (Theme yüzeyleri); görsel arama sırasında sheet kapatınca hata yok; doküman bağsız
destede görsel arama doküman seçtiriyor; tüm görünür metinler diyakritikli Türkçe.

## Faz 4 — Onaylı yeni özellikler (~2 saat) — spec: Bölüm G
1. **Serbest çalışma (cram) modu** — web + mobil (+ küçük backend parametresi).
2. **Çalışma serisi (streak) + ısı haritası** — web + mobil (C46 tz düzeltmesiyle birlikte yap).
**Kabul:** Cram oturumu `card_reviews`'u DEĞİŞTİRMİYOR (DB'den teyit); boş due listesinde "Serbest çalış"
önerisi çıkıyor; heatmap/streak iki istemcide de aynı sayıları gösteriyor; testler yeşil.

## Faz 5 — SM-2 ve senkron sağlamlaştırma (~1 saat)
**Bulgular:** C9 (en az: başarısız notları oturum sonunda yeniden dene + sunucu yanıtını kullan),
C26+U14 (yuvarlamayı hizala — iki tarafta da açık half-up; pytest+dart testlerini güncelle; H'deki
golden-vektör önerisini uygula), C45, C46 (Faz 4'te yapılmadıysa), C47 (again kartı kuyruk sonuna).
**Kabul:** Aynı (state, grade) girdileriyle Python ve Dart birebir aynı interval üretiyor (golden test);
'again' kartı aynı oturumda geri geliyor (iki istemcide de).

## Faz 6 — Güvenlik sağlamlaştırma (sunum SONRASINA ertelenebilir)
**Bulgular:** C12, C13, C14, C15, C37 + U5, U6. İyileştirmeler: RLS politikaları, oran sınırlama,
imzalı URL'ler (H bölümü). **Dikkat:** C15 (private bucket) mevcut public URL'leri kırar — migration
+ istemci değişikliği ister; sunumdan önce YAPMA.

## Faz 7 — Final doğrulama + telefon (~45 dk)
1. A.3'ün tamamı.
2. `BASLAT.bat` ile üç servisi kaldır; `curl http://localhost:8000/health` → `dip_engine.status: ok`.
3. Web'de hızlı E2E: giriş → doküman listesi → set aç → çalış (1 kart) → quiz aç → export (PDF'te Türkçe karakter kontrolü).
4. Telefon: A.4'teki derleme/kurulum; cihazda giriş → desteler → çalışma (koyu temada da) → quiz → serbest mod → heatmap.
5. `/study/history` yanıtında `needs_migration` YOKSA tamam; varsa kullanıcıya migration_02'yi uygulat.

---

# E. DOĞRULANMIŞ 50 BULGU — DÜZELTME TALİMATLARI

> Sıra: önem (high → low). Tam kanıt + doğrulayıcı analizleri: `DENETIM-BULGULARI.json`
> (`dogrulanmis_bulgular` dizisi, aynı sırada). Satır numaraları denetim anındaki koda göredir.

### YÜKSEK (high)

- **C1** `medvisual-api/app/routers/sets.py:129` — `_auto_images_job` gövdesinde try/except yok;
  Storage/DB hatası seti kalıcı 'generating' bırakır (istemciler sonsuz poll'lar, kurtarma yolu yok).
  **Düzeltme:** Gövdeyi `documents.py`deki `_generate_cards_job` kalıbıyla `try/except Exception` sar;
  hatada `flashcard_sets.status='failed'` + `error` yaz; kart başına hataları `continue` ile tolere et.

- **C2** `medvisual-api/app/gemini.py:198` — `int(it.get("answer_index", 0))`: LLM `null`/`"B"` dönerse
  TypeError/ValueError tüm quiz işini 'failed' yapar. **Düzeltme:** item döngüsünü
  `try/except (TypeError, ValueError): continue` ile koru; ayrıca `documents.py`de `enhance_*` çağrılarını
  ayrı try'a al → hata durumunda offline sonuçla devam et (tasarım sözleşmesi bu).

- **C3** `medvisual-api/app/exporters.py:240` — PDF export fpdf core font + latin-1 'replace':
  ğ/ş/ı/İ → '?'. **Düzeltme:** fpdf2'ye Unicode TTF ekle (örn. DejaVuSans.ttf'i `medvisual-api/assets/`
  içine koy, `pdf.add_font(...)` + `pdf.set_font('DejaVu')`), `_latin1` dönüşümünü kaldır.

- **C4** `medvisual-web/src/pages/Study.tsx:100` — hata durumu erişilemez → sonsuz spinner.
  **Düzeltme:** `if (dueQuery.isError) return <hata UI + Tekrar dene>` bloğunu spinner koşulunun ÜSTÜNE taşı.

- **C5** `medvisual-web/src/hooks/useAuth.tsx:38` — çıkışta `queryClient.clear()` yok; sonraki kullanıcı
  öncekinin cache'ini görür. **Düzeltme:** `onAuthStateChange` içinde `SIGNED_OUT` → `queryClient.clear()`.

- **C6** `medvisual-web/src/pages/Study.tsx:19` (+ SetDetail.tsx:34, CandidateModal.tsx:319/348/498) —
  JWT `?token=` ile `<img>` URL'sine gömülü, mount'ta bir kez alınıyor, ~1 saatte ölüyor.
  **Düzeltme (asgari):** token'ı state yerine her render'da `getAccessToken()`'dan al (Supabase otomatik
  yeniler) — ör. görsel URL'lerini token'ı parametre alan yardımcıdan üret ve `useEffect` ile periyodik tazele.
  **Tercih edilen:** Authorization header'lı `fetch` + `URL.createObjectURL` yapan ortak `<AuthImage>` bileşeni
  (unmount'ta revoke) — üç sayfadaki tekrar da kalkar.

- **C7** `medvisual-api/app/routers/cards.py:247` — `update_card` None'ları filtreliyor; `term:null`
  sessizce yutuluyor (web 'güncellendi' diyor ama silinmiyor). **Düzeltme:** Pydantic v2
  `req.model_dump(exclude_unset=True)` kullan; gönderilen `null` artık alanı temizlesin. Web tarafı C28.

- **C8** `medvisual-mobile/lib/features/sets/presentation/match_cubit.dart:44` (ve `select()` satır 62) —
  30-120 sn'lik arama sırasında sheet kapatılırsa kapalı cubit'e emit → StateError.
  **Düzeltme:** her `await`'ten sonra `if (isClosed) return;`.

- **C9** `medvisual-mobile/lib/features/study/presentation/study_bloc.dart:142` — notlar fire-and-forget;
  ağ hatasında kalıcı kayıp, sunucunun otoritatif ReviewState'i de atılıyor.
  **Düzeltme (asgari, Faz 5):** başarısız `(card_id, grade)` çiftlerini state'te tut, oturum sonunda
  otomatik yeniden dene; başarılı yanıtın ReviewState'ini kuyruktaki karta yaz. (Tam çözüm: kalıcı outbox
  — H bölümünde, sunum sonrası.)

- **C10** `medvisual-mobile/lib/features/sets/presentation/candidate_sheet.dart:74` — `documentId` null
  destelerde görsel arama API 400'üne takılıyor; web'deki doküman seçici mobilde yok.
  **Düzeltme:** `set_detail_screen._autoImages`'taki hazır-doküman seçtirme adımını candidate_sheet'e
  ekle; seçimi `matchCard(document_id: ...)` ile geçir.

- **C11** `medvisual-mobile/lib/features/study/presentation/study_screen.dart:270` (+ candidate_sheet:204,
  documents_screen:154, quiz_player_screen) — sabit `Colors.white` yüzeyler koyu temada metni okunmaz yapar.
  **Düzeltme:** `Theme.of(context).colorScheme.surface` / `cardColor`; sabit `Colors.blueGrey` metinleri
  `onSurfaceVariant`'a taşı. Koyu temada cihazda gözle doğrula.

### ORTA (medium)

- **C12** `medvisual-api/app/routers/proxy.py:22` — `?token=` JWT log/Referer/geçmiş sızıntısı.
  Faz 6: görseller için kısa ömürlü tek-amaç token veya imzalı URL; şimdilik dokunma (mobil/web buna bağımlı).
- **C13** `medvisual-api/app/routers/documents.py:143` (+ cards.py import) — upload boyut sınırı yok (DoS).
  Faz 6: parçalı okuma + 413; PDF için 100MB, import için 10MB makul.
- **C14** `medvisual-api/app/routers/cards.py:207` — upload_image content-type'a güveniyor; magic-byte yok.
  Faz 6: PNG/JPEG/WebP whitelist + magic-byte (veya Pillow doğrulaması); `select_image` zaten image/png zorluyor.
- **C15** `medvisual-api/app/routers/cards.py:175` — kart görselleri public bucket'ta. Faz 6 / sunum SONRASI:
  private bucket + imzalı URL (istemcileri de değiştirir — riskli, acele etme).
- **C16** `medvisual-web/src/pages/Dashboard.tsx:209` (+ Sets.tsx:119, Quizzes.tsx:78) — sorgu hatası
  "henüz yok" boş durumuna düşüyor. **Düzeltme:** üç sayfada boş durumdan önce `isError` dalı + "Tekrar dene".
- **C17** `medvisual-web/src/pages/Study.tsx:47` — `/study` ↔ `/study/:setId` geçişinde kuyruk sıfırlanmıyor.
  **Düzeltme:** App.tsx'te `<Study key={setId ?? 'all'} />` sarmalayıcı (H'deki "key ile remount" önerisinin parçası).
- **C18** `medvisual-web/src/pages/QuizPlayer.tsx:17` — quiz id değişiminde index/answers kalıyor.
  **Düzeltme:** `useEffect(() => { setIndex(0); setAnswers([]); setSelected(null) }, [id])` (veya key).
- **C19** `medvisual-web/src/pages/Study.tsx:68` — başarısız review kaybı + oturum sonu stats yarışı.
  **Düzeltme:** mutation'a `retry: 2`; başarısızları listede tut → oturum sonunda yeniden gönder (C49 ile
  birleşik: özet ekranında "N cevap kaydedilemedi" uyarısı); stats invalidation'ı mutasyonlar bitince yap.
- **C20/C27** `medvisual-web/src/pages/DocumentDetail.tsx:175-176` — form max 200/50, API limiti 120/40 → 422.
  **Düzeltme:** input max'larını 120/40 yap + `lib/api.ts`te detail dizisini okunur mesaja çevir.
- **C21** `medvisual-api/app/routers/study.py:144` — `total_reviews` tüm zamanlar; web "son 14 gün" diye
  gösterip doğruluk %'sini yanlış hesaplıyor. **Düzeltme:** `total_reviews`'u `days` penceresinden hesapla
  (`sum(v["total"])`), web etiketiyle uyumlu hale getir.
- **C22** `generate_cubit.dart:56` + QuizzesCubit/StudyHomeCubit/SettingsCubit/ThemeCubit — await sonrası
  `isClosed` kontrolü yok. **Düzeltme:** ortak `safeEmit` (mixin veya base class) tanımla, tüm Cubit async
  metodlarına uygula. C8 ile aynı kalıp.
- **C23** `medvisual-mobile/lib/core/api_client.dart:28` — 401'de refresh/retry/signOut yok.
  **Düzeltme:** `onError`: 401 → `auth.refreshSession()` dene → isteği bir kez tekrarla → olmadı `signOut()`.
- **C24** `documents_bloc.dart:84` — poll eventleri concurrent; istek yığılması + eski yanıt yeniyi ezebilir.
  **Düzeltme:** `bloc_concurrency`'den `droppable()` transformer'ı poll handler'ına ver (pubspec'e paket ekle).
- **C25** `quizzes_cubit.dart:56` — rename PATCH yanıtı `question_count` içermiyor → listede 0.
  **Düzeltme:** SetsBloc kalıbı: `q.copyWith(title: updated.title)`.
- **C26 (+U14)** `sm2.dart:32` vs `sm2.py:52` — yuvarlama half-even (Python) vs half-away (Dart);
  ulaşılabilir sapma kanıtlı (ef=1.3, interval=1.75, hard → 1.36 vs 1.37 gün).
  **Düzeltme (Faz 5):** iki tarafta da açık half-up'a sabitle — Python'da
  `float(Decimal(str(x)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))` yardımıcısı, Dart `_round2`
  zaten half-up. pytest tablolarını ve gerekirse dart testlerini güncelle; H'deki golden-vektör testini ekle.
- **C28** `medvisual-web/src/pages/SetDetail.tsx:61` — C7'nin istemci yüzü; backend düzeltmesiyle çözülür,
  webde değişiklik gerekmez (term boşaltma `null` göndermeye devam etsin), yine de elle test et.
- **C29** `set_detail_screen.dart:309` + `sets_repository.dart:72` — mobil kart düzenlemede terim yok.
  **Düzeltme:** `_edit` diyaloğuna `TermAutocompleteField` ekle; `updateCard`'a `term` parametresi
  (PATCH zaten destekliyor; C7 düzeltmesi sonrası null ile temizleme de çalışır).
- **C30** `sets_screen.dart:63` — mobilde boş deste oluşturma yok. **Düzeltme:** app bar'a "+ Yeni Deste"
  → başlık/açıklama diyaloğu → `POST /sets` (SetsBloc'a event ekle).
- **C31** `generate_cubit.dart:32` — üretim sihirbazında kaynak (auto/metin/OCR) seçimi yok.
  **Düzeltme:** `GenerateWizardScreen`'e SegmentedButton ekle; `submit` → repository'ye `source` geçir.
- **C32** `generate_wizard_screen.dart:67` + web `DocumentDetail.tsx:11` — aralık doğrulama tutarsız.
  **Düzeltme (ortak kural):** tek sayfa kabul ("n" → "n-n"), başlangıç≤bitiş ve sayfa-sınırı kontrolü
  İKİ istemcide de; mobil regex'i gevşet, web'e sınır/ters-aralık kontrolü ekle (candidate akışları dahil).
- **C33** PRD vaadi `llm_enhanced` rozeti hiçbir istemcide yok; quiz'de bilgi saklanmıyor bile.
  **Düzeltme (hafif):** kart setinde description'a gömülen "uretim: X" zaten var — set detayında bunu
  rozet olarak yüzeye çıkar (web+mobil); quiz için `_generate_quiz_job`'ta aynı bilgiyi quizzes.title'a
  değil DB'ye yazmak migration ister → migration istemiyorsan quiz rozetini Faz 6'ya bırak, set rozetini yap.

### DÜŞÜK (low) — hızlı kazanımlar, çoğu 5-15 dk

- **C34** `sets.py:208` — add_card position=count → silme sonrası çakışma. Düzeltme: `max(position)+1`.
- **C35** `exporters.py:74` — TSV back None koruması + `\r` temizliği: `(c.get("back") or "")`, `.replace("\r"," ")`.
- **C36** `exporters.py:149` — APKG temp dizini silinmiyor + medya adı çakışıyor. `TemporaryDirectory` + benzersiz önek.
- **C37** `deps.py:64` + proxy.py:31 — ham istisna metni istemciye dönüyor. Genel mesaj + sunucu logu (Faz 6 olabilir).
- **C38** `CandidateModal.tsx:271` — sorgu çözülünce kullanıcının yazdığı aralık ezilir. Effect bağımlılığından
  `page_count`'u çıkar / dirty-flag koy.
- **C39** `SetDetail.tsx:52` — Düzenle açılışında state'i o anki prop'tan doldur.
- **C40** `main.py:33` — `expose_headers=["Content-Disposition"]` ekle; webde anki fallback uzantısını `tsv` yap.
- **C41** `generate_wizard_screen.dart:93` — `listenWhen: (p,c) => p.error != c.error || p.createdId != c.createdId`
  + `setKind`'da `error: null`.
- **C42** sets/quizzes/set_detail/settings ekranlarındaki dialog `TextEditingController`'ları dispose edilmiyor.
  Dialog kapanışında `dispose()` (await sonrası) veya StatefulWidget'a taşı.
- **C43** `export_file.dart:26` — RFC 5987 regex'i raw string içinde `''` kaybediyor; dosya adı `''` önekli çıkıyor.
  Çift tırnaklı string ile yaz: `RegExp("filename\\*?=(?:UTF-8'')?\"?([^\";]+)\"?")`.
- **C44** `api_client.dart:25` — match çağrısına özel `Options(receiveTimeout: Duration(minutes: 30))`.
- **C45** `study.py:138` — 'doğru' eşiği grade>=2, SM-2 hard'ı başarılı sayıyor. Eşiği `>=1` yap veya hard'ı
  ayrı kategori göster; tek sabite bağla.
- **C46** `study.py:136` — gün sınırı UTC; TR'de 21:00 sonrası ertesi güne yazılıyor. `/study/history`'ye
  `tz_offset_minutes` query param ekle (varsayılan 0), gruplamada uygula; istemciler cihaz offset'ini göndersin.
  **Faz 4 heatmap bununla birlikte yapılmalı.**
- **C47** `study_bloc.dart:128` + web Study.tsx:69 — 'again' kartı oturum içinde geri gelmiyor.
  Again'lenen kartı kuyruk sonuna ekle (iki istemcide); oturum bitişi = cevaplanmamış kart kalmadı.
- **C48** `set_detail_screen.dart:83` — boş arka yüz kabul ediliyor. `back.trim().isNotEmpty` koşulu ekle.
- **C49** web Study — başarısız review'lar özetlenmiyor (mobil sayıyor). C19 düzeltmesinin parçası:
  başarısız sayacı + özet uyarısı.
- **C50** mobil metinlerde 'Vazgec'/'Vazgeç' karışık. `lib/` altında görünür TÜM metinleri tam Türkçe'ye
  normalleştir (grep: `Vazgec|Calis|Dokuman|Kutuphane|Gorsel|Olustur|Yukle|Iceri|Cikis|Sifre|Uye|Giris` vb.).

---

# F. BELİRSİZ 16 BULGU (tek doğrulayıcı onayladı — kararım/önerim ile)

| ID | Yer | Konu | Önerim |
|---|---|---|---|
| U1 | `dip_client.py:25` | Tek 1800sn read timeout her uca uygulanıyor; /health bile takılabilir | **YAP (kolay):** health/terms/books için `timeout=10` parametreli ayrı çağrı |
| U2 | `study.py:46` | PostgREST 1000 satır tavanı /due ve /stats'ı sessizce keser | **YAP (Faz 5):** `.limit(2000)` açık ver veya sayfalama; demo verisinde görünmez ama gerçek risk |
| U3 | `gemini.py:141` | `str(None)` → literal `"none"` term'i | **YAP (Faz 1, 1 satır):** `it.get("term") or ""` üzerinden str |
| U4 | `study.py:138` | C45 ile aynı konu (hard sayımı) | C45'le birlikte çöz |
| U5 | `main.py:33` | CORS `*` | Faz 6: origin listesi env'den; lokal demo için dokunma |
| U6 | `deps.py:47` | JWKS'te issuer kontrolü yok | Faz 6: `issuer=f"{SUPABASE_URL}/auth/v1"` ekle |
| U7 | `Settings.tsx:49` | Profil refetch'i yazılan adı eziyor | **YAP (Faz 2):** input dirty ise effect ezmesin |
| U8 | `api.ts:56` | 401'de merkezi oturum işleme yok | İsteğe bağlı: 401 → `supabase.auth.signOut()` + login'e yönlendir |
| U9-U11 | `types.ts` | El yazımı tiplerde alan kaymaları (id/grade, card_count, MatchResponse null'luk) | **YAP (Faz 2, 10 dk):** tipleri gerçek yanıtlarla hizala (H'deki OpenAPI önerisi kalıcı çözüm) |
| U12 | `candidate_sheet.dart:194` | URL elle kuruluyor; token null'sa `?token=null` | **YAP (Faz 3, 1 satır):** `resolveImageUrl()` helper'ını kullan |
| U13 | `quiz.dart:13` | DB'de title nullable, Dart'ta zorunlu — null başlık listeyi çökertir | **YAP (Faz 3):** `String? title` + UI fallback `'Quiz'` (backend her zaman title yazıyor ama savunma) |
| U14 | — | C26 ile aynı (yuvarlama) | C26'da çöz |
| U15 | `study.py:72` | submit_review read-modify-write atomik değil (son yazan kazanır) | Faz 6 / sonrası: RPC ile atomikleştir; demo riski düşük |
| U16 | `migration.sql:120` | card_reviews kolonları float4 | İsteğe bağlı migration (double precision); acil değil |

**Çürütülen 8 bulgu** (uygulama GEREKMEZ; merak edersen `DENETIM-BULGULARI.json > curutulen_bulgular`):
hardcoded bucket iddiası, answer_index "sessiz yanlış işaretleme" iddiası, RLS-bypass'ın hata sayılması,
Flashcard/QuizQuestion parse çökmesi iddiaları, 0-bayt PDF yükleme, `token=null` (ölü yol — ama U12 gerçek
kısmını yakalıyor), mobil cihaz saati sapması.

---

# G. ONAYLI YENİ ÖZELLİK SPESİFİKASYONLARI (kullanıcı seçimi)

## G.1 Serbest Çalışma (Cram) Modu — web + mobil

**Amaç:** Vadesi gelmiş kart olmasa da çalışılabilsin; sunumda "çalışılacak kart yok" boş ekranı asla görünmesin.

**Tasarım kararları (kesin):**
- Cram oturumu **SM-2 zamanlamasını ETKİLEMEZ**: `/study/reviews` ÇAĞRILMAZ; `card_reviews` değişmez.
- Not butonları çalışır ama yalnız **yerel oturum istatistiği** günceller (again/hard/good/easy sayaçları).
- Ekranda kalıcı bir **"Serbest mod — zamanlama etkilenmez"** rozeti/bandı görünür.
- 'again' denen kart cram'de de kuyruk sonuna geri eklenir (C47 davranışıyla tutarlı).

**Backend (küçük):** `GET /study/due`'ya `mode` query param ekle: `mode=cram` ise due/fresh filtresi atlanır,
kullanıcının (verilmişse set'in) TÜM kartları döner; sunucuda karıştırma yapma (istemci karıştırır),
`limit` aynen uygulanır. Yanıt şekli DEĞİŞMEZ (`cards/total_due/new_count` — cram'de total_due=kart sayısı,
new_count=0 kabul edilebilir). Mevcut davranış (param yokken) birebir korunur.

**Web:** `Study.tsx` — (1) route `/study/:setId?` aynı; `?mode=cram` search param'ı ile cram başlat;
(2) boş due durumunda "🎯 Serbest çalış" butonu; SetDetail'e "Serbest çalış" girişi (opsiyonel);
(3) cram'de `review.mutate` çağrısını atla, rozet göster, özet ekranında "Serbest oturum — kayıt edilmedi" yaz.

**Mobil:** `StudyBloc`'a `cramMode` bayrağı (constructor/event ile). `study_repository.due(...)`'ya
`mode` parametresi. `StudyHomeScreen`'e set listesinin yanına "Serbest çalışma" girişi + due=0 boş
durumuna buton. `_onGraded`: cram'de `submitReview` çağrılmaz. AppBar'da rozet. State değişiyorsa
build_runner'ı çalıştırmayı unutma (A.2/5).

**Kabul testleri:** cram oturumu öncesi/sonrası `card_reviews` satırları birebir aynı (API'den `/study/due`
sayılarıyla teyit edilebilir); normal mod regresyonsuz; `flutter test` + web build yeşil.

## G.2 Çalışma Serisi (Streak) + Isı Haritası — web + mobil

**Veri:** `GET /study/history?days=126&tz_offset_minutes=<cihaz offset>` (C46 düzeltmesiyle birlikte:
gruplama yerel güne göre). Yanıt: `{days: [{date, total, correct}], total_reviews}`. `review_events`
tablosu gerekli — `needs_migration:true` dönerse UI bilgilendirici boş durum göstersin
("İlerleme grafiği için migration_02 gerekli").

**Streak hesabı (saf fonksiyon, iki istemcide aynı):** bugünden (yerel) geriye `total>0` olan ardışık gün
sayısı; bugün 0 ise dünden saymaya başla (bugün seriyi BOZMAZ, sadece eklemez).

**Isı haritası:** GitHub tarzı — sütun=hafta (18 hafta ≈ 126 gün), satır=haftanın günü (Pzt-Paz),
hücre yoğunluğu: 0 / 1-4 / 5-9 / 10-19 / 20+ tekrar → 5 kademe (temanın primary tonları).
Hücre tooltip/long-press: "12 Haz: 14 tekrar".

**Web:** `Study` veya `Dashboard`'a (Dashboard'da zaten history grafiği var — onun yanına) `<Heatmap>` +
"🔥 N gün seri" çipi. Saf CSS grid yeterli, kütüphane EKLEME.

**Mobil:** `study_home_screen.dart`'a `progress_chart.dart` kalıbında yeni `heatmap.dart` widget'ı
(satır/sütun `Container`'ları; CustomPaint şart değil) + streak çipi. Koyu temada renkleri colorScheme'den türet (C11 dersini unutma).

**Kabul:** Web ve mobil aynı gün için aynı sayı/yoğunluğu gösteriyor; migration yoksa kırılmıyor;
21:00 sonrası (TR) atılan tekrar bugünün hücresine işleniyor (C46 kanıtı).

---

# H. İYİLEŞTİRME ÖNERİLERİ (hata değil — tam liste JSON'da, 40 adet)

**Sunum öncesi değerli (küçük efor):**
1. **Again kartını kuyruğa geri al** (C47 ile aynı — iki istemci).
2. **Route param → key ile remount** (App.tsx wrapper'ları; C17/C18'i kalıcı çözer).
3. **ErrorBoundary + react-query global onError** (beyaz ekran sigortası).
4. **Web not butonlarına öngörülen aralık etiketi** (mobil paritesi — `projectedIntervalLabel`'ın TS karşılığı).
5. **Mobil quiz sonunda yanlış-cevap inceleme listesi** (web'de var).
6. **Görsel arama varsayılan aralığını hizala** (web ±15 / mobil ±2 → ortak ±5).
7. **SM-2 golden-vektör testi**: tek JSON fixture → hem pytest hem dart test (C26 regresyonunu kilitler).
8. **Görsel seçiminde önbellek kırma:** `select_image`/`upload_image` aynı Storage yoluna upsert ediyor;
   URL değişmediği için tarayıcı/`Image.network` eski görseli gösterebilir → `image_url`'e `?v=<timestamp>`
   ekle (benim ek gözlemim, denetim bulgusu değil).
9. **Gemini fallback'i içerik-doğrulamada da zincirlesin** (parse edilemeyen JSON'da sonraki modele geç;
   `raw_in[:8000]` budamasını kart sayısı sınırına çevir).

**Sunum sonrası (orta/büyük):** RLS politikaları (savunma derinliği), imzalı URL'ler, oran sınırlama,
ortak güvenli-upload yardımcısı, OpenAPI'den TS tipi üretimi, kontrat smoke testleri, mobil kalıcı outbox,
export görsellerini paralel indirme, `/study/due`'yu DB tarafında filtreleme, yeni-kart günlük limiti,
StudyHome için hafif sayım ucu, mobil upload-image/kırpma paritesi, Modal focus-trap, RefreshIndicator
Future'ları, `_break_long_tokens` ölü kodunun silinmesi, startup'ta takılı 'processing/generating' temizliği.

---

# I. BEKLEYEN GÖREVLER VE SUNUM GÜNÜ KONTROL LİSTESİ

## I.1 Görev listesi durumu (bu oturumun task tracker'ı)

| # | Görev | Durum | Karşılık |
|---|---|---|---|
| 1 | Çok ajanlı denetim | ✅ tamamlandı | Bölüm C/E/F |
| 2 | Bulgu sentezi + plan | ✅ tamamlandı (bu rapor) | — |
| 3 | Backend düzeltmeleri | ⏳ bekliyor | Faz 1 (+5/6'nın backend kısmı) |
| 4 | Web düzeltmeleri | ⏳ bekliyor | Faz 2 |
| 5 | Mobil düzeltmeleri | ⏳ bekliyor | Faz 3 |
| 6 | Tüm test/analizler + sunuma hazırlık doğrulaması | ⏳ bekliyor | Faz 7 |
| 7 | Serbest çalışma modu | ⏳ bekliyor | Faz 4 / G.1 |
| 8 | Streak + ısı haritası | ⏳ bekliyor | Faz 4 / G.2 |
| 9 | Telefonda derle/kur/test (SM M336B USB'de hazır) | ⏳ bekliyor | Faz 7 / A.4 |

## I.2 Sunum günü kontrol listesi (kullanıcı + uygulayıcı)

1. **Supabase'i uyandır** (free tier 1 hafta inaktivitede uyur) — dashboard'a gir, bir sorgu çalıştır.
2. `migration_02` (review_events) uygulanmış mı? → `/study/history` yanıtında `needs_migration` olmamalı.
3. `medvisual-api/.env`'de `GOOGLE_API_KEY` dolu mu? (Gemini yoksa demo offline rozetle yine çalışır.)
4. `BASLAT.bat` → 3 pencere açık kalmalı; `http://localhost:8000/health` → `dip_engine: ok` kontrolü.
5. Telefon: USB takılı + `TELEFON-BAGLA.bat` (her USB takışında yeniden gerekir; `adb reverse` kalıcı değil).
6. Windows güvenlik duvarı 8000 inbound izni (yalnız LAN-IP ile bağlanılacaksa gerekir; USB tünelde gerekmez).
7. Demo akışı önerisi: web'de PDF yükle → kart üret (enhance açık) → görsel aday seç → mobilde AYNI hesapla
   aç (senkron kanıtı) → mobilde çalış (koyu temada!) → serbest mod → ısı haritası → export (PDF, Türkçe karakter).
8. Prova sırasında Study oturumunu 1 saatten uzun açık tutma ya da C6 düzeltmesinin yapıldığından emin ol.

---

*Bu rapor 156 alt-ajanlık çok boyutlu denetimin, üç projenin test/derleme doğrulamasının ve çekirdek
dosyaların satır satır okunmasının sentezidir. Bulgu kanıtlarının tamamı `DENETIM-BULGULARI.json` içindedir;
oradaki `refuteVerdict`/`impactVerdict` alanları her bulgunun iki bağımsız doğrulayıcı tarafından nasıl
teyit edildiğini gösterir. Uygulayıcı model: Bölüm A kurallarına uy, Bölüm D sırasını izle, her fazda test koş.*
