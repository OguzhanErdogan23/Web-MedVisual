# MedVisual: Yapay Zeka Destekli Görsel Öğrenme ve Flashcard Ekosistemi
## Ürün Gereksinimleri Dokümanı (PRD) & Mimari Yol Haritası

Bu doküman, üç farklı yazılım mühendisliği lisans dersi (Sayısal Görüntü İşleme, Fonksiyonel Programlama, Web Programlama) kapsamında geliştirilecek olan ortak ekosistemin kapsamını, mimarisini ve teknik gereksinimlerini içerir. Projenin amacı, tıp fakültesi öğrencilerinin yoğun akademik PDF dokümanlarını görsel odaklı ve etkileşimli bilgi kartlarına (Flashcards) dönüştürmesini sağlamaktır. Sistem yüklenen dökümandan hem standart metin gibi bilgi kartlarını oluşturacak hem de ilgili görselleri bilgi kartlarına yerleştirerek görsel hafızayla öğrenmeyi pekiştirecektir. Benim aklımda olan şunun gibi;
Bilgi kartındaki bilgiye en uygun görsel bulması, bir kemikten bahsediyor mesela onun için en uygun görseli buluyor gibi. Tabi burada öğrenciye birkaç seçenekte sunabilir, şu kart için şu görselleri buldum hangisi senin için uygun diyip seçtirsin ve karta o görsel eklensin. tıp dökümanlarındaki görsellerin terimleri çok iç içe olduğu için seçmesi zor olacaktır o durumlarda görselde 10 farklı yere değiniliyor ve bizimki sadece biriyse orayı bulup ilgili kısmı kırpması zor olabilir, bu sebeple ilgili görselin tamamı da öneriler arasında sunulmalı(sayfanın tamamı değil sayfadaki ilgili görselin bütünü). Kullanıcı başka yerde oluşturduğu bilgi kartlarını ve ilgili dökümanı yükleyerekte sadece kartlara görsel eklemek için de kullanabilsin. Aynı zamanda program bilgi kartlarını da kendisi oluşturarak, sürecin tamamını kendisi de yönetebilsin. Bilgi kartlarının yanı sıra test/quiz sistemi de olsun.

---

## 1. Genel Sistem Mimarisi & "Single Source of Truth"

Sistem, merkezi bir veritabanı (PostgreSQL/Supabase veya Firebase) etrafında kurulu bir **çapraz platform (cross-platform) ekosistemidir**. 
*hem Web hem de Mobil platformlar sistemde eşit yetkilere (Feature Parity) sahiptir.* Kullanıcılar her iki ortamdan da doküman yükleyebilir, içerik üretebilir ve kart çalışabilir.

┌──────────────────────────────┐
              │      Merkezi Veritabanı      │
              │   (PostgreSQL / Cloud Obj)   │
              └──────────────┬───────────────┘
                             │
               ┌─────────────┴─────────────┐
               │    Merkezi RESTful API    │
               └─────────────┬─────────────┘
                             │
     ┌───────────────────────┼───────────────────────┐
     │                       │                       │
┌────────▼────────┐     ┌────────▼────────┐     ┌────────▼────────┐
│  Mobile Client  │     │   Web Client    │     │   DIP Engine    │
│  (Flutter/RN)   │     │ (React/Next.js) │     │ (Python/OpenCV) │
└─────────────────┘     └─────────────────┘     └─────────────────┘


---

## 2. Modüler Proje Bileşenleri & Ders Gereksinimleri

Proje, akademik olarak birbirinden bağımsız üç farklı klasörde (modülde) geliştirilecek, ancak aynı veritabanı şemasını konuşacaktır.

### A. Sayısal Görüntü İşleme (DIP) Modülü
* **Teknoloji Yığını:** Python, OpenCV, PyMuPDF, Tesseract OCR
* **Akademik Odak:** Görüntü analizi, bölütleme, morfolojik işlemler ve nesne tespiti.
* **İşlevsel Kapsam (Scanned/Normal PDF Senaryoları):**
  1. **Page Segmentation (Bölütleme):** Yüklenen PDF (taratılmış resim olsa dahi) Otsu Thresholding ve Morphological Operations (Dilation/Erosion) kullanılarak metin blokları ve görsel blokları (diyagram, histoloji slaytı vb.) olarak ayrıştırılacak.
  2. **Metin Analizi & OCR:** Ayrıştırılan bloklar Tesseract OCR ile okunacak. Bilgi kartında geçmesi hedeflenen Latince terim ve türevleri (Fuzzy Matching/Bulanık Eşleme ile ek almış veya hatalı yazılmış halleri dahil) metin içinde tespit edilecek.
  3. **Görüntü Netleştirme (Enhancement):** Tıbbi incelemeye uygunluk için ayıklanan görsellere Histogram Eşitleme (Histogram Equalization), Median veya Gaussian Filtreleme (Denoising) uygulanacak.
  4. **Kırpma (Cropping):** İlgili terimin geçtiği bölgeye en yakın resim bloğu, kenar tespiti (Contour Detection) yapılarak gereksiz beyaz boşluklardan arındırılacak ve kullanıcıya sunulmak üzere 3-5 görsel adayı olarak kaydedilecek.

Konu açıklaması: MedVisual: Tıbbi Dokümanlar Üzerinde Görüntü İşleme ve Segmentation ile Görsel Destekli Öğrenme Sistemi

### B. Web Programlama Modülü
* **Teknoloji Yığını:** React.js veya Next.js (Frontend) | FastAPI veya Node.js (Backend)
* **Akademik Odak:** Full-Stack Client-Server mimarisi, asenkron işlem yönetimi, ilişkisel veri yönetimi.
* **İşlevsel Kapsam:**
  1. **Dinamik Dosya Yönetimi:** Kullanıcıların yüksek boyutlu tıbbi PDF'leri yükleyebileceği, yükleme durumunu (asenkron işlem kuyrukları ile) izleyebileceği Dashboard.
  2. **İnteraktif Doğrulama Arayüzü:** DIP motorunun ürettiği 3-5 görsel adayının kullanıcıya sunulduğu bileşen tabanlı (component-based) onay ekranı. Kullanıcı en doğru görseli seçip kırparak nihai kartı onaylar.
  3. **RESTful API Katmanı:** Verilerin JSON formatında tüm ekosisteme (özellikle mobile) tutarlı dağıtılması ve veri bütünlüğünün (data integrity) korunması.

Konu açıklaması: Tıp eğitiminde kullanılan akademik kaynakların dijitalleştirilmesi ve akıllı öğrenme setlerine dönüştürülmesi amacıyla geliştirilen, merkezi veritabanı mimarisine dayalı Full-Stack bir içerik yönetim ve öğrenme portalıdır. Platform, modern istemci-sunucu (Client-Server) mimarisi üzerine kurgulanmış olup; kullanıcıların PDF dokümanlarını sisteme yüklemesine, bu dokümanlardan sayısal görüntü işleme servisleri aracılığıyla ayıklanan görsel adaylarını analiz edip doğrulamasına ve kişiselleştirilmiş bilgi kartı havuzları oluşturmasına olanak tanıyan tam özellikli bir sistem merkezi işlevi görür. Backend tarafında geliştirilen asenkron işlem kuyrukları ve RESTful servisler, ham verilerin işlenmesi ve mobil istemcilerle gerçek zamanlı senkronizasyonunu sağlayarak "Single Source of Truth" (Tek Doğruluk Kaynağı) prensibiyle veri bütünlüğünü korur. Bileşen tabanlı frontend mimarisi (React/Next.js) ile sunulan interaktif arayüz, kullanıcının cihazdan bağımsız olarak içerik üretme ve ders çalışma fonksiyonlarını tüm derinliğiyle kullanmasını sağlayarak tıbbi literatürün dijital materyallere dönüşüm sürecini profesyonel bir mühendislik standartıyla dijitalleştirir.

### C. Fonksiyonel Programlama (Mobil) Modülü
* **Teknoloji Yığını:** Flutter (Dart) veya React Native
* **Akademik Odak:** Değişmezlik (Immutability), saf fonksiyonlar (Pure Functions), deklaratif arayüz.
* **İşlevsel Kapsam:**
  1. **Çok Yönlü İçerik Üretimi:** Tıpkı webdeki gibi mobil cihaz üzerinden de PDF yükleme, DIP tetikleme ve görsel kart oluşturma/onaylama yeteneği (Feature Parity).
  2. **Immutable State Management:** Kart setleri, kullanıcı ilerlemeleri ve "Aralıklı Tekrar" (Spaced Repetition) algoritmaları, yan etkisiz (side-effect free) saf fonksiyonlar ve Redux/BLoC gibi fonksiyonel yaklaşımlarla yönetilecek.
  3. **Çalışma Arayüzü:** Görsel odaklı flashcard çalışma ekranı (Swipe mekanizmaları, deklaratif UI).

Konu açıklaması: Tıp fakültesi öğrencilerinin karmaşık ve yoğun tıbbi dokümanları (PDF) daha verimli çalışabilmesi için tasarlanmış; Fonksiyonel Programlama (FP) prensipleri olan değişmezlik (immutability), saf fonksiyonlar (pure functions) ve deklaratif arayüz yönetimi temel alınarak geliştirilmiş, görsel hafıza odaklı bir mobil öğrenme ve içerik üretim platformudur. Uygulama, kullanıcıların mobil cihazları üzerinden doküman yükleme, görüntü işleme süreçlerini tetikleme ve üretilen görsel içerikli bilgi kartlarını (Flashcards) "Aralıklı Tekrar" (Spaced Repetition) yöntemiyle çalışmaları için tam kapsamlı bir fonksiyonel ekosistem sunar. Yazılım mimarisinde benimsenen FP yaklaşımı, merkezi bir veri kaynağı üzerinden beslenen karmaşık görsel-metin eşleşmelerinin ve kullanıcı ilerleme verilerinin hatasız yönetilmesini sağlayarak tıp eğitimi gibi kritik bir alanda stabil, öngörülebilir ve yüksek performanslı bir kullanıcı deneyimi hedefler. Merkezi veritabanı ile sağlanan senkronizasyon sayesinde kullanıcılar, oluşturdukları çalışma setlerine ve üretim araçlarına tüm cihazlardan tam özellik paritesiyle (feature parity) erişerek eğitim süreçlerini profesyonel bir standartta sürdürebilirler.
---

## 3. Adım Adım Geliştirme Yol Haritası (Asistan Talimatı)

projeyi geliştirirken aşağıdaki sırayı takip etmelidir:

### Adım 1: Veritabanı Şemasının Tasarlanması (Öncelikli)
Her iki platformun ortak konuşabilmesi için merkezi veritabanında şu tablolar oluşturulmalı:
* `Users` (Kullanıcı bilgileri)
* `Documents` (Yüklenen PDF'lerin yolları ve durumları: işleniyor, tamamlandı)
* `Flashcard_Sets` (Kart desteleri)
* `Flashcards` (Metin, Latin Terim, Seçilen Görsel URL'si, Algoritmanın Önerdiği Aday Görsel URL'leri)
* `User_Progress` (Aralıklı tekrar algoritması için kart durumları: kolay, orta, zor)

### Adım 2: DIP Çekirdeğinin Yazılması (Python)
Web ve mobilin çağıracağı ana fonksiyon geliştirilmeli. Tek bir tıp kitabı sayfası (Scanned PDF resmi) üzerinde:
* Sayfayı binary hale getirme, satır ve resim bloklarını kare içine alma (`cv2.boundingRect`),
* Blokları OCR'dan geçirip kelime arama,
* Hedef resimleri dışarıya kırpıp kaydetme prototipi yazılmalı.

### Adım 3: Backend ve REST API Gelişimi
* Dosya yükleme (S3 veya yerel bulut depolama entegrasyonu),
* Python DIP script'ini tetikleyen arka plan işçileri (Background Tasks),
* Mobil ve web için CRUD (Ekle, Oku, Güncelle, Sil) API uç noktaları.

### Adım 4: Web ve Mobil Arayüzlerinin Eşzamanlı İnşası
* Web tarafında React, mobil tarafta seçilen teknolojiyle formların, yükleme ekranlarının ve kart çalışma arayüzlerinin kodlanması.

---