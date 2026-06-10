# MedVisual — Sunum & Test Rehberi

## 0. Tek seferlik (daha önce yapıldıysa atla)
- **Supabase migration'ları** SQL Editor'de çalıştırılmış olmalı:
  - `medvisual-api/supabase/migration.sql` (ana şema — yapıldı)
  - `medvisual-api/supabase/migration_02_review_events.sql` (ilerleme grafiği — aşağıda)
- Tesseract + Poppler kurulu (DIP `run_server.bat` PATH'i ayarlar).

## 1. Başlatma (en kolay yol)
**`BASLAT.bat`** dosyasına çift tıkla. Bu:
1. DIP motorunu (`:5000`),
2. API'yi (`:8000`),
3. Web'i (`:5173`) ayrı pencerelerde açar,
4. Telefon bağlıysa USB tünelini kurar,
5. Tarayıcıda `http://localhost:5173` açar.

> 3 siyah pencereyi **kapatma** (servisler onlarda çalışıyor). Bitince hepsini kapatabilirsin.

İlk açılış 1-2 dk sürebilir (bağımlılık kontrolü). Sonraki açılışlar hızlıdır.

## 2. Web sunumu
- Tarayıcı: `http://localhost:5173`
- Kayıt ol / giriş yap (aynı hesabı telefonda da kullanacaksın).
- Göster: Doküman yükle → Kart/Quiz üret (Gemini açık) → Görselli kart (Görsel Bul / Toplu otomatik) → Çalış (aralıklı tekrar) → Dışa aktar (PDF/Anki) → Ayarlar (karanlık tema).

## 3. Mobil sunumu — TELEFON BAĞLANTISI
İki seçenek var:

### A) USB (önerilen — internet/Wi-Fi gerekmez, en güvenilir)
1. Telefonu USB ile bağla, "USB hata ayıklama" açık olsun.
2. **`TELEFON-BAGLA.bat`**'a çift tıkla (USB tünelini kurar).
3. Telefondaki **MedVisual** uygulamasını aç, web ile **aynı hesapla** giriş yap.
> Uygulama zaten kurulu; yeniden yüklemeye gerek yok. Telefonu çıkarıp
> takarsan `TELEFON-BAGLA.bat`'ı tekrar çalıştır.

### B) Aynı Wi-Fi (telefon kabloya bağlı olmadan)
- Bu senaryoda uygulamanın **PC'nin LAN IP'siyle yeniden derlenmesi** gerekir
  (şu an USB'ye göre `127.0.0.1` derlenmiş). Sunumdan önce haber ver, 5 dk'da
  LAN IP'li sürümü kurarım. Ayrıca PC güvenlik duvarında 8000 portu açık olmalı.
- **Sunum için USB daha pratik** — venue Wi-Fi'sine bağımlı olmazsın.

## 4. Senkronizasyon (SSOT) gösterimi
1. Web'de bir deste oluştur / kart çalış.
2. Telefonda aynı hesapla gir → **aynı içerik anında görünür**.
3. Telefonda kart çalış → web'i yenile → "Vadesi gelen" sayısı değişmiş olur.
   (Tek merkezi DB: Supabase. Web ve mobil aynı API'yi konuşur.)

## 5. Hatırlatmalar / olası takılmalar
- **Supabase uykusu:** ücretsiz proje ~1 hafta inaktif kalırsa uyur. Sunum
  sabahı dashboard'a girip uyandır (bir sorgu çalıştır yeter).
- **Gemini kotası:** ücretsiz katman günlük sınırlı. Kota dolarsa sistem
  otomatik **offline üretime** düşer (yine çalışır, kart kalitesi biraz düşer).
  Model-fallback zinciri birden çok modeli dener.
- **Telefon "Sunucu hatası":** USB tüneli kopmuştur → `TELEFON-BAGLA.bat`.
- **İnternet:** PC'nin internete erişimi olmalı (Supabase + Gemini bulutta).
  Telefonun ayrıca internete ihtiyacı var (Supabase auth) — USB modunda bile.

## 6. migration_02'yi çalıştırma (ilerleme grafiği için)
Aşağıdaki "Migration" bölümüne bak. Çalıştırmazsan grafik boş kalır ama
hiçbir şey bozulmaz.
