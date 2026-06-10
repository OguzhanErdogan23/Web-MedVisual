# CLAUDE.md — MedVisual / Sayısal Görüntü İşleme (DIP) Modülü

Bu dosya Claude Code'un projeyi hızlıca anlaması içindir. Yeni bir oturumda
önce bunu oku.

## Proje nedir
Tıp öğrencileri için görsel flashcard ekosistemi **MedVisual**'in *Sayısal
Görüntü İşleme* bileşeni. Bir tıbbi PDF'ten SEÇİLEN SAYFA ARALIĞINI alır;
metin/figür bloklarına ayırır (Otsu + morfoloji), Latince terimleri bulur ve
kullanıcının seçtiği göreve göre: (1) bilgi kartı, (2) görselli bilgi kartı,
(3) test/quiz üretir veya (4) mevcut kartlara görsel ekler. Ayrıca bir "Sayfa
Bölütleme İnceleme" modu DIP hattını sergiler. Web/mobil entegrasyon AYRI
derslerde yapılacak; buradaki Flask arayüzü sade bir demodur.

## Mimari (tek giriş noktası: `dip/pipeline.py`)
- `dip/pdf_loader.py` — PDF → sayfa görüntüsü (pdf2image + poppler). `render_page` **1 tabanlı**.
- `dip/textextract.py` — **[YENİ]** Gömülü metin + kelime kutuları (`pdftotext -bbox -enc UTF-8`). Koordinatlar render dpi'a ölçeklenir → bölütleme bloklarıyla AYNI uzayda. Metin SEÇİLEBİLEN PDF'lerde OCR yerine bu kullanılır; `Word` dataclass'ı `ocr` ile ortaktır.
- `dip/segmentation.py` — Otsu + morfoloji + CCA. Figür tespiti 3 ipucu: (a) büyük nesne/çizgi-resim, (b) renk doygunluğu, (c) doku (satır-boşluk oranı).
- `dip/ocr.py` — Tesseract + elle yazılmış Levenshtein + Latince gövdeleme (declension ekleri).
- `dip/enhancement.py` — histogram eşitleme / CLAHE / median-Gaussian-bilateral.
- `dip/cropping.py` — kontur ile boşluk kırpma + terime en yakın figür + aday üretimi (figürün tamamı dahil).
- `dip/cards.py` — **[YENİ]** Offline (LLM'siz) kart + quiz: cümle bölütleme, tanım puanlama, cloze, çeldiricili MCQ.
- `dip/flashcard_io.py` — **[YENİ]** Kart içe/dışa aktarma (CSV/JSON/Anki-TSV) + `term_for_card`.
- `dip/pipeline.py` — `get_page_words` (metin-katmanı-önce, OCR fallback), `analyze_pdf_page`, `parse_page_range`, `iter_page_text`, `find_candidates_in_range`.
- `app.py` — Flask: `/api/upload` (has_text), `/api/analyze`, `/api/generate/cards`, `/api/generate/quiz`, `/api/cards/import`, `/api/cards/match`, `/work/...`.
- `data/latin_terms.txt` — ~140 terimlik sözlük.

## Çalıştırma / test
```bash
# Windows: run_server.bat Tesseract+Poppler'i PATH'e ekleyip başlatır.
run_server.bat                           # http://localhost:5000
# veya elle (PATH'te tesseract + pdftotext olmalı):
python app.py
python make_sample.py && python test_pipeline.py   # sentetik uçtan uca test (v0.2 dahil)
```
> ÇALIŞMA ANI: `pdftotext` ve `tesseract` PATH'te olmalı. winget:
> `UB-Mannheim.TesseractOCR`, `oschwartz10612.Poppler`.

## Kritik tasarım kararları — DEĞİŞTİRMEDEN ÖNCE OKU
- **Bölütleme küçültülmüş görüntüde yapılır** (`segment_page(max_proc_dim=1600)`), sonra blok koordinatları tam çözünürlüğe geri ölçeklenir. Tam çözünürlükte sayfa başına ~30 sn'di; bu ~1 sn. Tüm eşikler medyan karakter yüksekliğine **göreli** olduğu için sonuç değişmez. Bu mantığı bozma.
- Doku ile figür yeniden-sınıflandırması `saturation > 20` şartına bağlı; bu, saf siyah metin paragraflarının yanlışlıkla figür sayılmasını engeller.
- OCR ve kırpma **tam çözünürlükte** çalışır (kalite için). Sadece bölütleme küçültülür.
- 600+ sayfa için doküman tamamı belleğe alınmaz; yalnızca seçilen aralık işlenir.
- **Metin-katmanı-önce:** `get_page_words` önce `textextract` ile gömülü metni dener (OCR'sız, hızlı, hatasız); boşsa OCR'a düşer. `textextract` kutuları render dpi'a ölçeklediği için segmentation figürleriyle AYNI koordinat uzayında olur → terim↔figür uzaklığı doğrudan hesaplanır. Bu eşleşmeyi (aynı dpi) bozma.
- **Kart/quiz offline ve çıkarımsaldır** (`cards.py`): kaynaktaki cümleleri seçer/dönüştürür, metin uydurmaz. Bilinçli karar (açıklanabilirlik + dış-bağımsızlık). LLM eklenecekse `generate_flashcards/generate_quiz` imzaları korunmalı.
- `find_candidates_in_range` bellekte yalnızca en iyi `keep_top_pages` sayfanın görüntüsünü tutar; tarama `SCAN_DPI=150` ile yapılır (hız). `MAX_IMG_SCAN_PAGES` ile sınırlıdır.

## Bilinen sınırlama
Bu ortamda Tesseract'ta yalnızca `eng` dil paketi vardı (`tur`/`lat` yok).
Latince terimler Latin alfabesinde olduğu için `eng` ile okunuyor. Daha iyi
sonuç için hedef makineye `tesseract-ocr-lat` kurulabilir; `ocr_words(lang=...)`
parametresi hazır.

## Kütüphane ikameleri (PRD'ye göre)
- PyMuPDF → pdf2image + poppler  ·  FastAPI → Flask  ·  rapidfuzz → elle Levenshtein.
Çağrı imzaları, ileride orijinallere geçişi kolaylaştıracak şekilde korundu.

## Sıradaki olası işler (fikir)
- Görsel eşleştirmede ilerleme çubuğu / arka plan işi (uzun aralıklarda).
- Kart/quiz kalitesini LLM ile zenginleştirme (offline yedek korunarak).
- Sözlüğü genişletmek / kullanıcının terim eklemesi.
- Bölütleme parametrelerini taranmış (düşük kaliteli) PDF'ler için ayarlamak.
- Adayları merkezi DB / flashcard şemasına bağlamak (Web modülü).
- Toplu işleme: tüm sayfaları tarayıp terim→sayfa dizini çıkarmak.

## Kod stili
Türkçe yorumlar (ASCII), açıklayıcı dataclass'lar, yan etkisiz saf fonksiyonlar.
Yeni bağımlılık eklemeden önce gerçekten gerekli mi diye düşün.
