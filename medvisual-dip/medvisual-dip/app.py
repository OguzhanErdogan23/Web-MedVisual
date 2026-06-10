"""
app.py
------
MedVisual - Sayisal Goruntu Isleme (DIP) Modulu icin web arayuzu.

Bu arayuz, DIP cekirdeginin (dip/ paketi) tek basina calistirilabilir bir
demosudur. Ileride Web Programlama modulunde React + FastAPI ile yeniden
yazilacaktir; burada amac goruntu isleme hattini ve uretilen icerigi gorsel
olarak sergilemek.

Desteklenen gorevler (kullanici yukleme sonrasi secer):
  1) Bilgi karti olusturma            -> /api/generate/cards (mode=text)
  2) Gorselli bilgi karti olusturma   -> /api/generate/cards + /api/cards/match
  3) Test / quiz olusturma            -> /api/generate/quiz
  4) Mevcut karta gorsel ekleme       -> /api/cards/import + /api/cards/match

Onemli tasarim noktalari:
  * Sayfa ARALIGI (orn. 25-50) islenebilir; tek sayfa zorunlu degil.
  * Metin SECILEBILEN PDF'lerde once gomulu metin katmani kullanilir
    (pdftotext); yalnizca taranmis sayfalarda OCR'a dusulur. Boylece tum
    dokuman goruntuye cevrilmeden, hizli ve dogru calisir.
  * Calisma dosyalari (yuklenen PDF, render sayfalar, aday gorseller) WORK_DIR
    altinda doc_id ile izole tutulur.
"""

from __future__ import annotations

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

import os
import uuid
import glob

import cv2
from flask import (
    Flask, request, jsonify, render_template,
    send_from_directory, abort,
)
from werkzeug.utils import secure_filename

from dip import (
    pdf_loader, segmentation, pipeline, ocr, textextract,
    cards as cards_mod, flashcard_io, llm_enhance, gemini_cards,
)

# --------------------------------------------------------------------------- #
# Yollar / yapilandirma  (phantom dizin sorununa karsi mutlak yollar)
# --------------------------------------------------------------------------- #
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
WORK_DIR = os.path.join(BASE_DIR, "work")
DATA_DIR = os.path.join(BASE_DIR, "data")
TEMPLATE_DIR = os.path.join(BASE_DIR, "templates")
STATIC_DIR = os.path.join(BASE_DIR, "static")
DICT_PATH = os.path.join(DATA_DIR, "latin_terms.txt")

ALLOWED_EXT = {".pdf"}
RENDER_DPI = 200
SCAN_DPI = 150               # aralik gorsel taramasinda hiz icin daha dusuk dpi
MAX_CONTENT_MB = 250
MAX_TEXT_PAGES = 80          # kart/quiz icin tek istekte islenecek azami sayfa
MAX_IMG_SCAN_PAGES = 40      # gorsel eslestirmede taranacak azami sayfa

os.makedirs(WORK_DIR, exist_ok=True)

app = Flask(__name__, template_folder=TEMPLATE_DIR, static_folder=STATIC_DIR)
app.config["MAX_CONTENT_LENGTH"] = MAX_CONTENT_MB * 1024 * 1024

# HTTP hatalari her zaman JSON olarak donersin (abort() HTML dondurmez)
@app.errorhandler(400)
@app.errorhandler(404)
@app.errorhandler(413)
@app.errorhandler(500)
def _json_error(e):
    code = getattr(e, "code", 500)
    desc = getattr(e, "description", str(e))
    return jsonify({"error": str(desc)}), code

try:
    DICTIONARY = ocr.load_dictionary(DICT_PATH)
except Exception:
    DICTIONARY = []


# --------------------------------------------------------------------------- #
# Yardimcilar
# --------------------------------------------------------------------------- #
def _doc_dir(doc_id: str) -> str:
    safe = secure_filename(doc_id)
    if not safe:
        abort(400, "Gecersiz dokuman kimligi.")
    d = os.path.join(WORK_DIR, safe)
    if not os.path.isdir(d):
        abort(404, "Dokuman bulunamadi.")
    return d


def _pdf_path(doc_id: str) -> str:
    d = _doc_dir(doc_id)
    hits = glob.glob(os.path.join(d, "*.pdf"))
    if not hits:
        abort(404, "PDF dosyasi bulunamadi.")
    return hits[0]


def _page_count(doc_id: str) -> int:
    try:
        return pdf_loader.page_count(_pdf_path(doc_id))
    except Exception:
        return 0


def _resolve_pages(data: dict, max_pages: int, cap: int):
    """Istek govdesinden sayfa araligini cozer ve ust sinira kirpar."""
    spec = data.get("range")
    if spec is None:
        start = data.get("page_start", data.get("page", 1))
        end = data.get("page_end", start)
        spec = {"start": int(start), "end": int(end)}
    pages = pipeline.parse_page_range(spec, max_pages)
    truncated = len(pages) > cap
    return pages[:cap], truncated


# --------------------------------------------------------------------------- #
# Sayfalar
# --------------------------------------------------------------------------- #
@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/health")
def health():
    """Ortam diagnostigi: Tesseract, pdftotext, sozluk durumu."""
    import shutil

    def _check_exe(name):
        path = shutil.which(name)
        return {"available": path is not None, "path": path or "NOT FOUND"}

    tesseract = _check_exe("tesseract")
    pdftotext = _check_exe("pdftotext")

    if tesseract["available"]:
        try:
            import subprocess
            ver = subprocess.run(
                ["tesseract", "--version"],
                capture_output=True, text=True, timeout=5
            ).stdout.splitlines()[0]
            tesseract["version"] = ver
        except Exception:
            tesseract["version"] = "unknown"

    return jsonify({
        "status": "ok",
        "tesseract": tesseract,
        "pdftotext": pdftotext,
        "dictionary_size": len(DICTIONARY),
        "dictionary_path": DICT_PATH,
        "dictionary_loaded": len(DICTIONARY) > 0,
        "work_dir": WORK_DIR,
    })


@app.route("/api/terms")
def terms():
    return jsonify({"terms": DICTIONARY})


@app.route("/api/upload", methods=["POST"])
def upload():
    """PDF yukler; doc_id, sayfa sayisi ve metin-katmani durumunu doner."""
    if "file" not in request.files:
        return jsonify({"error": "Dosya gonderilmedi."}), 400
    f = request.files["file"]
    if not f.filename:
        return jsonify({"error": "Dosya secilmedi."}), 400

    ext = os.path.splitext(f.filename)[1].lower()
    if ext not in ALLOWED_EXT:
        return jsonify({"error": "Yalnizca PDF dosyalari desteklenir."}), 400

    doc_id = uuid.uuid4().hex[:12]
    d = os.path.join(WORK_DIR, doc_id)
    os.makedirs(os.path.join(d, "candidates"), exist_ok=True)
    os.makedirs(os.path.join(d, "pages"), exist_ok=True)

    save_path = os.path.join(d, secure_filename(f.filename) or "document.pdf")
    f.save(save_path)

    try:
        n_pages = pdf_loader.page_count(save_path)
    except Exception as exc:
        return jsonify({"error": f"PDF okunamadi: {exc}"}), 400

    # Metin katmani var mi? Ilk birkac sayfadan ornekle (tarama mi dijital mi)
    has_text = False
    if textextract.available():
        for p in {1, min(2, n_pages), min(n_pages, 1 + n_pages // 2)}:
            if p >= 1 and textextract.page_has_text(save_path, p):
                has_text = True
                break

    return jsonify({
        "doc_id": doc_id,
        "filename": os.path.basename(save_path),
        "page_count": n_pages,
        "has_text": has_text,
    })


@app.route("/api/analyze", methods=["POST"])
def analyze():
    """
    Tek bir sayfayi analiz eder (bolutleme gorseli + tespit edilen terimler;
    terim verilirse aday gorseller). Gorselli kart akisinda sayfa incelemek
    ve hizli aday uretmek icin kullanilir.
    Govde: { doc_id, page, term?, source? }
    """
    data = request.get_json(silent=True) or {}
    doc_id = str(data.get("doc_id", ""))
    page = int(data.get("page", 1))
    term = (data.get("term") or "").strip()
    source = data.get("source", "auto")

    pdf_path = _pdf_path(doc_id)
    d = _doc_dir(doc_id)

    try:
        analysis = pipeline.analyze_pdf_page(
            pdf_path, page, dpi=RENDER_DPI, dictionary=DICTIONARY, source=source
        )
    except Exception as exc:
        return jsonify({"error": f"Sayfa analiz edilemedi: {exc}"}), 400

    vis = segmentation.draw_segmentation(analysis.page_image, analysis.seg_result)
    seg_name = f"page_{page}_seg.png"
    cv2.imwrite(os.path.join(d, "pages", seg_name), vis)

    detected, seen = [], set()
    for m in analysis.detected_terms:
        key = m.query.lower()
        if key in seen:
            continue
        seen.add(key)
        detected.append({
            "term": m.query, "found_text": m.found_text,
            "similarity": round(m.similarity, 3),
        })

    result = {
        "doc_id": doc_id, "page": page,
        "width": analysis.width, "height": analysis.height,
        "median_char_h": analysis.median_char_h,
        "n_text_blocks": len(analysis.text_blocks),
        "n_figure_blocks": len(analysis.figure_blocks),
        "source": analysis.source,
        "segmentation_url": f"/work/{doc_id}/pages/{seg_name}",
        "detected_terms": detected,
        "candidates": None, "match": None,
    }

    if term:
        cand_dir = os.path.join(d, "candidates")
        for old in glob.glob(os.path.join(cand_dir, f"{pipeline._slug(term)}_*.png")):
            try:
                os.remove(old)
            except OSError:
                pass
        cand_res = pipeline.find_candidates_for_term(
            analysis, term, cand_dir, threshold=0.72
        )
        result["candidates"] = [{
            "label": c["label"], "distance": c["distance"], "page": page,
            "url": f"/work/{doc_id}/candidates/{c['filename']}",
        } for c in cand_res["candidates"]]
        result["match"] = {
            "matched": cand_res["matched"],
            "match_text": cand_res.get("match_text"),
            "similarity": (round(cand_res["similarity"], 3)
                           if cand_res.get("similarity") is not None else None),
        }

    return jsonify(result)


@app.route("/api/generate/cards", methods=["POST"])
def generate_cards():
    """
    Sayfa araligindan bilgi kartlari uretir.
    Tek kaynak: { doc_id, range, source?, max_cards?, enhance? }
    Cok kaynak:  { sources: [{doc_id, range}, ...], source?, max_cards?, enhance? }
    Enhance=True + GOOGLE_API_KEY: Gemini ile birincil uretim (NotebookLM kalitesi).
    """
    data = request.get_json(silent=True) or {}
    source = data.get("source", "auto")
    max_cards = int(data.get("max_cards", 40))
    do_enhance = bool(data.get("enhance", False)) and llm_enhance.is_llm_available()

    sources_list = data.get("sources")
    if sources_list and isinstance(sources_list, list):
        # Cok kaynak: her kaynaktan sayfa al, birlestir
        pages_data = []
        pages = []
        truncated = False
        for src in sources_list:
            src_doc_id = str(src.get("doc_id", ""))
            if not src_doc_id:
                continue
            try:
                src_pdf = _pdf_path(src_doc_id)
            except Exception:
                continue
            src_pages, src_trunc = _resolve_pages(
                src, _page_count(src_doc_id),
                max(5, MAX_TEXT_PAGES // len(sources_list))
            )
            if src_trunc:
                truncated = True
            if src_pages:
                pages.extend(src_pages)
                src_data = list(pipeline.iter_page_text(src_pdf, src_pages, source=source))
                pages_data.extend(src_data)
    else:
        # Tek kaynak (geri uyumlu)
        doc_id = str(data.get("doc_id", ""))
        pdf_path = _pdf_path(doc_id)
        pages, truncated = _resolve_pages(data, _page_count(doc_id), MAX_TEXT_PAGES)
        if not pages:
            return jsonify({"error": "Gecerli bir sayfa araligi gir (orn. 25-50)."}), 400
        pages_data = list(pipeline.iter_page_text(pdf_path, pages, source=source))

    if not pages_data:
        return jsonify({"error": "Gecerli bir sayfa araligi gir veya kaynak ekle."}), 400

    # Gemini birincil uretim (enhance toggle + API key varsa)
    gemini_used = False
    if do_enhance and gemini_cards.is_available():
        cards = gemini_cards.generate_cards(pages_data, DICTIONARY, max_cards=max_cards)
        if cards:
            gemini_used = True
        else:
            cards = cards_mod.generate_flashcards(pages_data, DICTIONARY, max_cards=max_cards)
    else:
        cards = cards_mod.generate_flashcards(pages_data, DICTIONARY, max_cards=max_cards)
        if do_enhance and cards:
            cards = llm_enhance.enhance_cards_batch(cards, max_enhance=min(20, len(cards)))

    try:
        first_doc = str(data.get("doc_id") or (sources_list[0]["doc_id"] if sources_list else ""))
        first_page = pages[0] if pages else 1
        used = "gemini" if gemini_used else (
            "text" if source != "ocr" and textextract.available()
            and first_doc and textextract.page_has_text(_pdf_path(first_doc), first_page)
            else "ocr"
        )
    except Exception:
        used = "auto"

    reason = None
    if len(cards) == 0:
        if not DICTIONARY:
            reason = "Terim sozlugu yuklenemedi. data/latin_terms.txt dosyasini kontrol et."
        else:
            reason = (
                f"Secilen {len(pages)} sayfada sozlukteki {len(DICTIONARY)} terimden hicbiri bulunamadi. "
                "Daha genis bir sayfa araligi dene veya terimi elle gir."
            )

    return jsonify({
        "pages": pages, "truncated": truncated, "source": used,
        "count": len(cards),
        "cards": [c.to_dict() for c in cards],
        "reason": reason,
        "llm_enhanced": gemini_used or (do_enhance and not gemini_used and bool(cards)),
        "llm_available": llm_enhance.is_llm_available(),
    })


@app.route("/api/generate/quiz", methods=["POST"])
def generate_quiz():
    """
    Sayfa araligindan coktan secmeli test uretir (sadece MCQ, cloze yok).
    Tek kaynak: { doc_id, range, source?, n?, enhance? }
    Cok kaynak:  { sources: [{doc_id, range}, ...], source?, n?, enhance? }
    """
    data = request.get_json(silent=True) or {}
    source = data.get("source", "auto")
    n = int(data.get("n", 10))
    do_enhance_quiz = bool(data.get("enhance", False)) and llm_enhance.is_llm_available()

    sources_list = data.get("sources")
    if sources_list and isinstance(sources_list, list):
        pages_data = []
        pages = []
        truncated = False
        for src in sources_list:
            src_doc_id = str(src.get("doc_id", ""))
            if not src_doc_id:
                continue
            try:
                src_pdf = _pdf_path(src_doc_id)
            except Exception:
                continue
            src_pages, src_trunc = _resolve_pages(
                src, _page_count(src_doc_id),
                max(5, MAX_TEXT_PAGES // len(sources_list))
            )
            if src_trunc:
                truncated = True
            if src_pages:
                pages.extend(src_pages)
                pages_data.extend(list(pipeline.iter_page_text(src_pdf, src_pages, source=source)))
    else:
        doc_id = str(data.get("doc_id", ""))
        pdf_path = _pdf_path(doc_id)
        pages, truncated = _resolve_pages(data, _page_count(doc_id), MAX_TEXT_PAGES)
        if not pages:
            return jsonify({"error": "Gecerli bir sayfa araligi gir (orn. 25-50)."}), 400
        pages_data = list(pipeline.iter_page_text(pdf_path, pages, source=source))

    if not pages_data:
        return jsonify({"error": "Gecerli bir sayfa araligi gir veya kaynak ekle."}), 400

    # Gemini birincil uretim veya offline MCQ
    gemini_used = False
    if do_enhance_quiz and gemini_cards.is_available():
        quiz = gemini_cards.generate_quiz(pages_data, DICTIONARY, n_questions=n)
        if quiz:
            gemini_used = True
        else:
            quiz = cards_mod.generate_quiz(pages_data, DICTIONARY, n_questions=n)
    else:
        quiz = cards_mod.generate_quiz(pages_data, DICTIONARY, n_questions=n)
        if do_enhance_quiz and quiz:
            quiz = llm_enhance.enhance_quiz_batch(quiz, max_enhance=min(10, len(quiz)))

    if not quiz:
        return jsonify({
            "pages": pages, "truncated": truncated,
            "count": 0, "questions": [],
            "warning": "Bu aralikta yeterli terim/tanim bulunamadi. Daha genis "
                       "veya icerik yogun bir aralik dene.",
        })
    return jsonify({
        "pages": pages, "truncated": truncated,
        "count": len(quiz), "questions": [q.to_dict() for q in quiz],
        "llm_enhanced": gemini_used,
    })


@app.route("/api/cards/import", methods=["POST"])
def import_cards():
    """Mevcut kartlari (CSV/JSON/TSV) ice aktarir; front/back listesi doner."""
    if "file" not in request.files:
        return jsonify({"error": "Kart dosyasi gonderilmedi."}), 400
    f = request.files["file"]
    if not f.filename:
        return jsonify({"error": "Dosya secilmedi."}), 400
    try:
        cards = flashcard_io.import_cards(f.read(), f.filename)
    except Exception as exc:
        return jsonify({"error": f"Kartlar okunamadi: {exc}"}), 400
    if not cards:
        return jsonify({"error": "Dosyada kart bulunamadi (front/back sutunlari)."}), 400
    return jsonify({
        "count": len(cards),
        "cards": [c.to_dict() for c in cards],
    })


@app.route("/api/cards/match", methods=["POST"])
def match_card_image():
    """
    Tek bir kart icin sayfa araliginda en uygun figur adaylarini bulur.
    Govde: { doc_id, range|page_start/page_end, front?, back?, term?, source? }
    """
    data = request.get_json(silent=True) or {}
    doc_id = str(data.get("doc_id", ""))
    pdf_path = _pdf_path(doc_id)
    d = _doc_dir(doc_id)
    source = data.get("source", "auto")

    # Aranacak terimi belirle: acik 'term' verilmise onu, yoksa kart metninden cikar
    term = (data.get("term") or "").strip()
    if not term:
        card = cards_mod.Flashcard(
            front=str(data.get("front", "")), back=str(data.get("back", "")),
            term=str(data.get("term", "")),
        )
        term = flashcard_io.term_for_card(card, DICTIONARY)
    if not term:
        return jsonify({"error": "Kart icin arama terimi belirlenemedi."}), 400

    pages, truncated = _resolve_pages(data, _page_count(doc_id), MAX_IMG_SCAN_PAGES)
    if not pages:
        return jsonify({"error": "Gecerli bir sayfa araligi gir (orn. 25-50)."}), 400

    cand_dir = os.path.join(d, "candidates")
    res = pipeline.find_candidates_in_range(
        pdf_path, pages, term, cand_dir,
        dpi=SCAN_DPI, source=source, max_pages_scan=MAX_IMG_SCAN_PAGES,
    )
    candidates = [{
        "label": c["label"], "distance": c["distance"], "page": c.get("page"),
        "url": f"/work/{doc_id}/candidates/{c['filename']}",
    } for c in res["candidates"]]

    return jsonify({
        "term": term, "matched": res["matched"],
        "match_text": res.get("match_text"),
        "similarity": res.get("similarity"),
        "best_page": res.get("best_page"),
        "pages_scanned": res.get("pages_scanned"),
        "truncated": truncated or res.get("truncated", False),
        "candidates": candidates,
    })


@app.route("/work/<doc_id>/<path:subpath>")
def serve_work(doc_id, subpath):
    """Render edilen sayfa / aday gorselleri servis eder."""
    d = _doc_dir(doc_id)
    return send_from_directory(d, subpath)


BOOKS_DIR = os.path.join(BASE_DIR, "books")
os.makedirs(BOOKS_DIR, exist_ok=True)

@app.route("/api/books")
def list_books():
    """books/ klasöründeki varsayılan PDF dosyalarını listeler."""
    books = []
    for fname in sorted(os.listdir(BOOKS_DIR)):
        if fname.lower().endswith(".pdf"):
            fpath = os.path.join(BOOKS_DIR, fname)
            try:
                n = pdf_loader.page_count(fpath)
            except Exception:
                n = 0
            books.append({
                "name": fname,
                "display": os.path.splitext(fname)[0],
                "size_mb": round(os.path.getsize(fpath) / 1024 / 1024, 1),
                "pages": n,
            })
    return jsonify({"books": books})


@app.route("/api/books/load", methods=["POST"])
def load_book():
    """books/ klasöründen bir kitabı yükler (dosya upload gerektirmez)."""
    import shutil as _shutil
    data = request.get_json(silent=True) or {}
    name = data.get("name", "")
    if not name:
        return jsonify({"error": "Geçersiz kitap adı."}), 400
    # Adı doğrudan BOOKS_DIR içindeki dosyalarla karşılaştır (secure_filename boşlukları değiştirir)
    available = {f for f in os.listdir(BOOKS_DIR) if f.lower().endswith(".pdf")}
    if name not in available:
        return jsonify({"error": "Kitap bulunamadı."}), 404
    fpath = os.path.join(BOOKS_DIR, name)

    doc_id = uuid.uuid4().hex[:12]
    d = os.path.join(WORK_DIR, doc_id)
    os.makedirs(os.path.join(d, "candidates"), exist_ok=True)
    os.makedirs(os.path.join(d, "pages"), exist_ok=True)

    safe = secure_filename(name) or doc_id + ".pdf"
    dest = os.path.join(d, safe)
    _shutil.copy2(fpath, dest)

    try:
        n_pages = pdf_loader.page_count(dest)
    except Exception as exc:
        return jsonify({"error": f"PDF okunamadı: {exc}"}), 400

    has_text = False
    if textextract.available():
        for p in {1, min(2, n_pages), min(n_pages, 1 + n_pages // 2)}:
            if p >= 1 and textextract.page_has_text(dest, p):
                has_text = True
                break

    return jsonify({
        "doc_id": doc_id,
        "filename": os.path.splitext(name)[0],
        "page_count": n_pages,
        "has_text": has_text,
    })


if __name__ == "__main__":
    # threaded=True: uzun suren gorsel-tarama istekleri sirasinda arayuz
    # (statik dosyalar, paralel istekler) yanitsiz kalmasin.
    app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)
