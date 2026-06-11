"""Kart ve quiz disa aktarma — cok formatli (csv/json/tsv/txt/pdf/apkg).

Gorselli kartlar: PDF ve APKG'ye secilen gorsel de gomulur (Storage'dan indirilir).
Donus: (bytes, media_type, dosya_uzantisi).
"""
import csv
import io
import json
import os
import tempfile
import zlib
from typing import List, Optional, Tuple

import httpx

# Anki not tipleri icin sabit (deterministik — Date.now kullanmadan)
_ANKI_MODEL_ID = 1607392319
_ANKI_DECK_ID = 2059400110

# Turkce (ğ/ş/ı/İ) destekli TTF adaylari: (normal, kalin, italik).
# fpdf cekirdek fontlari latin-1 oldugu icin bu harfleri '?' yapar.
_FONT_CANDIDATES = [
    (r"C:\Windows\Fonts\arial.ttf", r"C:\Windows\Fonts\arialbd.ttf", r"C:\Windows\Fonts\ariali.ttf"),
    (r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\segoeuib.ttf", r"C:\Windows\Fonts\segoeuii.ttf"),
    (r"C:\Windows\Fonts\tahoma.ttf", r"C:\Windows\Fonts\tahomabd.ttf", r"C:\Windows\Fonts\tahoma.ttf"),
    ("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
     "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
     "/usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf"),
]


def _setup_font(pdf) -> str:
    """Unicode TTF bulup kaydeder ve aile adini dondurur.

    Bulunamazsa cekirdek Helvetica'ya duser (latin-1 sadelestirmeli);
    pdf._uni_font bayragi _fit'in donusum karari icin kullanilir.
    """
    for regular, bold, italic in _FONT_CANDIDATES:
        if not os.path.exists(regular):
            continue
        try:
            pdf.add_font("AppFont", "", regular)
            pdf.add_font("AppFont", "B", bold if os.path.exists(bold) else regular)
            pdf.add_font("AppFont", "I", italic if os.path.exists(italic) else regular)
            pdf._uni_font = True
            return "AppFont"
        except Exception:
            continue
    pdf._uni_font = False
    return "Helvetica"


def _img_bytes(url: Optional[str]) -> Optional[bytes]:
    if not url:
        return None
    try:
        r = httpx.get(url, timeout=httpx.Timeout(8.0, connect=4.0))
        if r.status_code == 200:
            return r.content
    except httpx.HTTPError:
        pass  # gorsel cekilemezse karti gorselsiz aktarmaya devam et
    return None


# --------------------------------------------------------------------------- #
# KARTLAR
# --------------------------------------------------------------------------- #
def cards_to_json(cards: List[dict]) -> Tuple[bytes, str, str]:
    payload = [
        {
            "front": c.get("front", ""),
            "back": c.get("back", ""),
            "term": c.get("term"),
            "page": c.get("page"),
            "kind": c.get("kind"),
            "image_url": c.get("image_url"),
        }
        for c in cards
    ]
    data = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
    return data, "application/json", "json"


def cards_to_csv(cards: List[dict], delimiter: str = ",") -> Tuple[bytes, str, str]:
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=delimiter)
    w.writerow(["front", "back", "term", "page", "image_url"])
    for c in cards:
        w.writerow(
            [c.get("front", ""), c.get("back", ""), c.get("term", ""),
             c.get("page", ""), c.get("image_url", "")]
        )
    ext = "tsv" if delimiter == "\t" else "csv"
    mime = "text/tab-separated-values" if delimiter == "\t" else "text/csv"
    return buf.getvalue().encode("utf-8"), mime, ext


def cards_to_anki_tsv(cards: List[dict]) -> Tuple[bytes, str, str]:
    """Anki'nin 'Import' ile dogrudan okudugu sade TSV (on<TAB>arka, gorsel <img>)."""
    lines = []
    for c in cards:
        back = c.get("back") or ""
        if c.get("image_url"):
            back = f'{back}<br><img src="{c["image_url"]}">'
        front = (c.get("front") or "").replace("\t", " ").replace("\n", " ").replace("\r", " ")
        back = back.replace("\t", " ").replace("\n", " ").replace("\r", " ")
        lines.append(f"{front}\t{back}")
    return ("\n".join(lines)).encode("utf-8"), "text/tab-separated-values", "tsv"


def cards_to_txt(cards: List[dict]) -> Tuple[bytes, str, str]:
    """Insan-okunur duz metin: numarali soru/cevap."""
    out = []
    for i, c in enumerate(cards, 1):
        out.append(f"{i}. SORU: {c.get('front', '')}")
        out.append(f"   CEVAP: {c.get('back', '')}")
        if c.get("term"):
            out.append(f"   Terim: {c['term']}  (sayfa {c.get('page', '-')})")
        out.append("")
    return ("\n".join(out)).encode("utf-8"), "text/plain", "txt"


def cards_to_pdf(cards: List[dict], title: str = "MedVisual Kartlar") -> Tuple[bytes, str, str]:
    from fpdf import FPDF

    pdf = FPDF()
    pdf.set_margins(15, 15, 15)
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    family = _setup_font(pdf)
    pdf.set_font(family, "B", 16)
    _mc(pdf, 10, title)
    pdf.ln(2)

    for i, c in enumerate(cards, 1):
        if pdf.get_y() > 250:
            pdf.add_page()
        pdf.set_font(family, "B", 12)
        _mc(pdf, 7, f"{i}. {c.get('front', '')}")
        pdf.set_font(family, "", 11)
        pdf.set_text_color(60, 60, 60)
        _mc(pdf, 6, c.get("back", ""))
        pdf.set_text_color(0, 0, 0)
        img = _img_bytes(c.get("image_url"))
        if img:
            try:
                pdf.image(io.BytesIO(img), w=70)
            except Exception:
                pass
        if c.get("term"):
            pdf.set_font(family, "I", 9)
            pdf.set_text_color(120, 120, 120)
            _mc(pdf, 5, f"{c['term']} - sayfa {c.get('page', '-')}")
            pdf.set_text_color(0, 0, 0)
        pdf.ln(3)

    out = pdf.output()
    return bytes(out), "application/pdf", "pdf"


def cards_to_apkg(cards: List[dict], deck_name: str = "MedVisual") -> Tuple[bytes, str, str]:
    import genanki

    model = genanki.Model(
        _ANKI_MODEL_ID,
        "MedVisual Basit",
        fields=[{"name": "On"}, {"name": "Arka"}],
        templates=[{
            "name": "Kart",
            "qfmt": "{{On}}",
            "afmt": '{{FrontSide}}<hr id="answer">{{Arka}}',
        }],
    )
    deck = genanki.Deck(_ANKI_DECK_ID, deck_name)
    media_files: List[str] = []
    # Medya adi karta ozgu: iki ayri destenin exportu Anki medya koleksiyonunda
    # birbirinin uzerine yazmasin (eski hali tum exportlarda medvisual_{idx}.png idi)
    with tempfile.TemporaryDirectory(prefix="medvisual_apkg_") as tmpdir:
        for idx, c in enumerate(cards):
            back = c.get("back") or ""
            img = _img_bytes(c.get("image_url"))
            if img:
                uniq = str(c.get("id") or idx).replace("-", "")[:12]
                fname = f"medvisual_{uniq}_{idx}.png"
                fpath = os.path.join(tmpdir, fname)
                with open(fpath, "wb") as f:
                    f.write(img)
                media_files.append(fpath)
                back = f'{back}<br><img src="{fname}">'
            deck.add_note(genanki.Note(model=model, fields=[c.get("front") or "", back]))

        pkg = genanki.Package(deck)
        pkg.media_files = media_files
        out_path = os.path.join(tmpdir, "deck.apkg")
        pkg.write_to_file(out_path)
        with open(out_path, "rb") as f:
            data = f.read()
    return data, "application/octet-stream", "apkg"


# --------------------------------------------------------------------------- #
# QUIZ
# --------------------------------------------------------------------------- #
def quiz_to_json(questions: List[dict]) -> Tuple[bytes, str, str]:
    payload = [
        {
            "question": q.get("question", ""),
            "options": q.get("options", []),
            "answer_index": q.get("answer_index", 0),
        }
        for q in questions
    ]
    return json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8"), "application/json", "json"


def quiz_to_csv(questions: List[dict]) -> Tuple[bytes, str, str]:
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(["question", "A", "B", "C", "D", "answer"])
    for q in questions:
        opts = list(q.get("options", []))[:4] + [""] * 4
        ai = q.get("answer_index", 0)
        w.writerow([q.get("question", ""), opts[0], opts[1], opts[2], opts[3],
                    chr(65 + ai) if 0 <= ai < 4 else ""])
    return buf.getvalue().encode("utf-8"), "text/csv", "csv"


def quiz_to_txt(questions: List[dict]) -> Tuple[bytes, str, str]:
    out = []
    for i, q in enumerate(questions, 1):
        out.append(f"{i}. {q.get('question', '')}")
        for j, o in enumerate(q.get("options", [])):
            mark = "*" if j == q.get("answer_index", 0) else " "
            out.append(f"   {mark} {chr(65 + j)}) {o}")
        out.append("")
    return ("\n".join(out)).encode("utf-8"), "text/plain", "txt"


def quiz_to_pdf(questions: List[dict], title: str = "MedVisual Quiz") -> Tuple[bytes, str, str]:
    from fpdf import FPDF

    pdf = FPDF()
    pdf.set_margins(15, 15, 15)
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    family = _setup_font(pdf)
    pdf.set_font(family, "B", 16)
    _mc(pdf, 10, title)
    pdf.ln(2)
    for i, q in enumerate(questions, 1):
        if pdf.get_y() > 250:
            pdf.add_page()
        pdf.set_font(family, "B", 12)
        _mc(pdf, 7, f"{i}. {q.get('question', '')}")
        pdf.set_font(family, "", 11)
        for j, o in enumerate(q.get("options", [])):
            correct = j == q.get("answer_index", 0)
            if correct:
                pdf.set_text_color(20, 130, 60)
                pdf.set_font(family, "B", 11)
            _mc(pdf, 6, f"   {chr(65 + j)}) {o}")
            pdf.set_text_color(0, 0, 0)
            pdf.set_font(family, "", 11)
        pdf.ln(3)
    return bytes(pdf.output()), "application/pdf", "pdf"


def _latin1(text: str) -> str:
    """fpdf çekirdek fontlari latin-1; desteklenmeyen karakterleri sadelestir."""
    if text is None:
        return ""
    repl = {"‘": "'", "’": "'", "“": '"', "”": '"',
            "–": "-", "—": "-", "…": "...", " ": " "}
    for k, v in repl.items():
        text = text.replace(k, v)
    return text.encode("latin-1", "replace").decode("latin-1")


def _mc(pdf, height: float, text: str) -> None:
    """Guvenli multi_cell: x'i sol kenara sifirlar, tam sayfa genisligi kullanir,
    metni font genisligine gore parcalar. fpdf'nin genislik/x belirsizligini onler."""
    pdf.set_x(pdf.l_margin)
    pdf.multi_cell(pdf.epw, height, _fit(pdf, text))


def _fit(pdf, text: str) -> str:
    """Unicode font yoksa latin-1'e indir + her token'i sayfa genisligine
    sigacak sekilde parcala. Genislik gercek font olcumuyle (get_string_width)
    hesaplanir — fpdf'nin 'tek karakter sigmiyor' hatasini tamamen onler."""
    if not getattr(pdf, "_uni_font", False):
        text = _latin1(text)
    elif text is None:
        text = ""
    max_w = pdf.epw - 1  # etkin sayfa genisligi (mm)
    out = []
    for token in text.split(" "):
        if pdf.get_string_width(token) <= max_w:
            out.append(token)
            continue
        chunk = ""
        for ch in token:
            if pdf.get_string_width(chunk + ch) > max_w and chunk:
                out.append(chunk)
                chunk = ch
            else:
                chunk += ch
        if chunk:
            out.append(chunk)
    return " ".join(out)


# --------------------------------------------------------------------------- #
# Format yonlendirme
# --------------------------------------------------------------------------- #
CARD_FORMATS = {
    "json": cards_to_json,
    "csv": cards_to_csv,
    "tsv": lambda c: cards_to_csv(c, delimiter="\t"),
    "anki": cards_to_anki_tsv,
    "txt": cards_to_txt,
    "pdf": cards_to_pdf,
    "apkg": cards_to_apkg,
}
QUIZ_FORMATS = {
    "json": quiz_to_json,
    "csv": quiz_to_csv,
    "txt": quiz_to_txt,
    "pdf": quiz_to_pdf,
}
