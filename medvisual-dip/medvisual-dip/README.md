# MedVisual — Sayısal Görüntü İşleme (DIP) Modülü

Tıp öğrencileri için görsel odaklı bilgi kartı (flashcard) ekosistemi
**MedVisual**'in *Sayısal Görüntü İşleme* bileşeni. Tek başına çalıştırılabilir
bir prototip + sade web arayüzüdür. Yoğun bir tıbbi PDF'ten **seçilen sayfa
aralığını** alır; içeriği **metin** ve **figür** bloklarına ayırır, **Latince
tıbbi terimleri** tespit eder, ve kullanıcının seçtiği göreve göre:

1. **Bilgi kartı oluşturur** (terim–tanım + boşluk doldurma / cloze),
2. **Görselli bilgi kartı** üretir (kart + sayfadaki **en uygun figürü** önerir),
3. **Test/Quiz** (çoktan seçmeli) üretir,
4. **Mevcut kartlara görsel ekler** (kullanıcının Anki/CSV/JSON kartlarını yükler).

Ayrıca bir **Sayfa Bölütleme İnceleme** modu, görüntü işleme hattını (Otsu +
morfoloji + bağlı bileşen analizi) görsel olarak sergiler.

> Web ve mobil entegrasyon **ayrı derslerde** (Web Programlama / Fonksiyonel
> Programlama) yeniden ve daha gösterişli yapılacaktır. Buradaki arayüz bilinçli
> olarak **sade** tutulmuştur; amaç görüntü işleme çekirdeğini sergilemek. `dip/`
> paketi çerçeveden bağımsızdır; ileride aynı çağrı imzalarıyla merkezi bir
> RESTful API'ye bağlanabilir.

---

## Öne çıkan tasarım kararları

| Gereksinim | Çözüm |
|---|---|
| **Tüm dökümanı değil, sayfa aralığı** (ör. 25–50) işlenebilmeli | `pipeline.parse_page_range` + sayfa-bazlı (lazy) işleme. Tek sayfa render edilmez; yalnızca aralık. |
| **Metin seçilebilen PDF'lerde önce kelimelere bak** | `textextract.py` — `pdftotext -bbox` ile gömülü metni ve kelime kutularını **OCR'sız**, hatasız ve hızlı alır. Yalnızca taranmış sayfalarda OCR'a (`ocr.py`) düşülür. |
| **Karttaki bilgiye en uygun görseli bul, birkaç aday sun** | `pipeline.find_candidates_in_range` — aralık boyunca terimi bulanık eşleştirir, en güçlü sayfalardaki figürleri sıralar, 3–6 aday üretir. |
| **İç içe terimli figürlerde tam figür de önerilsin** | Adaylar arasında *sıkı kırpılmış figür*, **figürün tamamı** (sayfanın değil), *CLAHE ile netleştirilmiş* ve *diğer sayfalardan alternatifler* yer alır. |
| **NotebookLM benzeri kart/test, dış servise bağımsız** | `cards.py` — tamamen **offline**, açıklanabilir çıkarımsal (extractive) üretim: cümle bölütleme + tanım puanlama + cloze + çeldiricili MCQ. |
| **Mevcut kartlara görsel ekleme** | `flashcard_io.py` — CSV/JSON/Anki-TSV içe aktarma + kart başına görsel arama. |

---

## Kurulum (Windows)

Sistem bağımlılıkları (pip ile gelmez) — winget ile:

```powershell
winget install UB-Mannheim.TesseractOCR     # OCR motoru (taranmış sayfalar için)
winget install oschwartz10612.Poppler        # PDF -> görüntü + pdftotext (metin katmanı)
```

Python bağımlılıkları:

```powershell
python -m venv venv
.\venv\Scripts\python.exe -m pip install -r requirements.txt
```

> **Not:** `pdftotext` ve `tesseract` çalışma anında PATH'te bulunmalıdır. Hazır
> `run_server.bat` bunları otomatik PATH'e ekleyip sunucuyu başlatır.

### Linux / macOS

```bash
sudo apt-get install poppler-utils tesseract-ocr      # Debian/Ubuntu
brew install poppler tesseract                         # macOS
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
```

## Çalıştırma

```powershell
# Windows (PATH'i otomatik ayarlar):
.\run_server.bat
```
```bash
# veya elle:
python app.py
```
Tarayıcıda: **http://localhost:5000**

### Akış
1. Bir tıbbi PDF yükle (yükleme anında *metin katmanı var mı* tespit edilir).
2. **Ne yapmak istediğini seç** (5 mod).
3. **Sayfa aralığını** gir (ör. `25-50`, `30`, ya da `10,12,40-42`).
4. Gerekirse metin kaynağını seç: *Otomatik* (metin katmanı varsa onu kullan)
   veya *Görsel/OCR* (taranmış sayfalar / “tüm sayfayı görsel olarak işle”).
5. **Çalıştır** → kartlar / quiz / bölütleme / görsel adayları gelir.
   - Görselli kart & “karta görsel ekle” modlarında her kartın altındaki
     **🔎 Görsel bul** ile adaylar listelenir; birini seçince karta eklenir.
   - Kartları **JSON / CSV / Anki (TSV)** olarak dışa aktarabilirsin.

---

## Programatik kullanım

```python
from dip import pipeline, ocr, cards, flashcard_io

dic = ocr.load_dictionary("data/latin_terms.txt")

# 1) Sayfa aralığını çöz ve metni topla (metin katmanı varsa render YOK)
pages = pipeline.parse_page_range("25-50", max_pages=585)
pages_data = list(pipeline.iter_page_text("kitap.pdf", pages))   # (sayfa, metin, kelimeler)

# 2) Offline bilgi kartı + quiz
flashcards = cards.generate_flashcards(pages_data, dic, max_cards=30)
quiz       = cards.generate_quiz(pages_data, dic, n_questions=10)

# 3) Bir terim için aralık genelinde görsel adaylar (figürün tamamı dahil)
res = pipeline.find_candidates_in_range("kitap.pdf", pages, "femur", out_dir="cikti")
#   res["candidates"] -> diske yazılmış aday görsellerin yolları + sayfa no

# 4) Mevcut kartları içe aktar, kart için arama terimini seç
imported = flashcard_io.import_cards(open("kartlar.csv","rb").read(), "kartlar.csv")
term = flashcard_io.term_for_card(imported[0], dic)
```

Sentetik uçtan uca test (gerçek PDF gerektirmeyen kısımlar dahil):

```bash
python make_sample.py      # samples/sample_page.png üretir
python test_pipeline.py    # bölütleme + OCR + kart + quiz + aralık + içe/dışa aktarma
```

---

## HTTP API (Flask)

| Uç | Açıklama |
|---|---|
| `POST /api/upload` | PDF yükler; `doc_id`, `page_count`, `has_text` döner. |
| `POST /api/analyze` | Tek sayfa bölütleme + terim tespiti (+ terim verilirse adaylar). |
| `POST /api/generate/cards` | Sayfa aralığından bilgi kartları (offline). |
| `POST /api/generate/quiz` | Sayfa aralığından çoktan seçmeli test. |
| `POST /api/cards/import` | Mevcut kartları (CSV/JSON/TSV) içe aktarır. |
| `POST /api/cards/match` | Tek kart için aralıkta en uygun figür adayları. |
| `GET  /api/terms` | Gömülü Latince terim sözlüğü. |
| `GET  /work/<doc_id>/<path>` | Render sayfa / aday görsel servisi. |

Ortak gövde alanları: `doc_id`, `range` (ör. `"25-50"`) veya
`page_start`/`page_end`, `source` (`auto`|`ocr`).

---

## Modül yapısı

```
app.py                 Flask arayüzü (upload / analyze / generate / import / match)
run_server.bat         Windows başlatıcı (Tesseract+Poppler PATH + sunucu)
dip/
  pdf_loader.py        PDF -> sayfa görüntüsü (pdf2image + poppler)
  textextract.py       Gömülü metin + kelime kutuları (pdftotext -bbox)  [YENİ]
  segmentation.py      Otsu + morfoloji + CCA ile metin/figür bölütleme
  ocr.py               Tesseract OCR + Levenshtein + Latince gövdeleme
  enhancement.py       Histogram eşitleme / CLAHE / median-Gaussian-bilateral
  cropping.py          Kontur kırpma + terime en yakın figür + aday üretimi
  cards.py             Offline bilgi kartı + quiz üretimi                 [YENİ]
  flashcard_io.py      Kart içe/dışa aktarma + kart->terim seçimi         [YENİ]
  pipeline.py          Tüm adımlar + sayfa aralığı + metin/OCR seçimi
data/latin_terms.txt   ~140 terimlik Latince anatomi/histoloji sözlüğü
templates/, static/    Web arayüzü (5 mod, flip kart, quiz, aday seçici)
samples/               Örnek/sentetik test sayfaları
```

---

## Performans (600+ sayfalık dökümanlar)

- Doküman **tamamı belleğe yüklenmez**; yalnızca seçilen aralık işlenir.
- **Metin katmanı olan PDF'lerde kart/quiz için sayfa render EDİLMEZ**; metin
  doğrudan `pdftotext` ile alınır → 25 sayfalık aralık < 1–2 sn.
- Bölütleme, hızı için sayfayı içeride ~1600 px'e küçültüp koordinatları tam
  çözünürlüğe geri ölçekler (eşikler medyan karakter yüksekliğine **göreli**,
  sonuç değişmez): sayfa başına ~30 sn → ~1 sn.
- **Görsel eşleştirme** (figür arama) aralıktaki her sayfayı render + bölütler;
  bu mod doğası gereği ağırdır. Hız için tarama `SCAN_DPI=150` ile yapılır ve
  bellekte yalnızca en iyi birkaç sayfanın görüntüsü tutulur. Taranmış (OCR
  gereken) dökümanlarda sayfa başına maliyet daha yüksektir; bu yüzden görsel
  ararken aralığı ilgili terimin geçtiği sayfalara daraltmak önerilir.

## Bilinen sınırlamalar / notlar

- **Tesseract dil paketi:** Bu ortamda yalnızca `eng` yüklüdür; Latince terimler
  Latin alfabesinde olduğundan `eng` ile okunur. Daha iyi sonuç için hedef
  sisteme `tesseract-ocr-lat`/`-tur` kurulabilir (`ocr_words(..., lang=...)`).
- **Kart/quiz üretimi offline ve çıkarımsaldır** (LLM yok): kaynaktaki cümleleri
  seçip dönüştürür, yeni metin “uydurmaz”. Bu, görüntü işleme dersinin
  açıklanabilirlik ve dış-bağımsızlık ilkesine uygundur; istenirse ileride bir
  LLM ile zenginleştirilebilir (`cards.py` arayüzü korunarak).
- Arayüz tek kullanıcılık bir demodur; kalıcı veritabanı yoktur (üretilenler
  `work/` altında geçici tutulur). Merkezi DB entegrasyonu Web modülünde.
