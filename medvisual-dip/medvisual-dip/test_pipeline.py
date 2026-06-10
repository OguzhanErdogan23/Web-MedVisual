"""Pipeline'i sentetik sayfa uzerinde uctan uca test eder."""
import os, cv2
from dip import pipeline, segmentation, ocr

SAMPLE = "samples/sample_page.png"
OUT = "outputs/test_run"
os.makedirs(OUT, exist_ok=True)

bgr = cv2.imread(SAMPLE)
print("Goruntu:", bgr.shape)

dictionary = ocr.load_dictionary("data/latin_terms.txt")
print("Sozluk terim sayisi:", len(dictionary))

analysis = pipeline.analyze_page(bgr, page_number=1, dictionary=dictionary)
print("\n=== BOLUTLEME ===")
print("Medyan karakter yuksekligi:", round(analysis.median_char_h, 1))
print("Metin blogu sayisi  :", len(analysis.text_blocks))
print("Figur blogu sayisi  :", len(analysis.figure_blocks))
for i, b in enumerate(analysis.figure_blocks):
    print(f"  figur[{i}] bbox=({b.x},{b.y},{b.w},{b.h}) alan={b.area} doygunluk={b.saturation:.0f} fill={b.fill:.2f}")

print("\n=== OCR ===")
print("Okunan kelime sayisi:", len(analysis.words))
sample_words = [w.text for w in analysis.words[:25]]
print("Ornek kelimeler:", sample_words)

print("\n=== OTOMATIK TERIM TESPITI ===")
for m in analysis.detected_terms[:15]:
    print(f"  '{m.query}' <- '{m.found_text}' benzerlik={m.similarity}")

# Segmentasyon gorsellestirmesi kaydet
vis = segmentation.draw_segmentation(bgr, analysis.seg_result)
cv2.imwrite(os.path.join(OUT, "segmentation.png"), vis)

print("\n=== TERIM ICIN ADAY URETIMI: 'femur' ===")
res = pipeline.find_candidates_for_term(analysis, "femur", OUT, threshold=0.7)
print("Eslesti mi:", res["matched"], "| bulunan:", res.get("match_text"), "| benzerlik:", res.get("similarity"))
for c in res["candidates"]:
    print(f"  - {c['label']:35s} uzaklik={c['distance']:8} -> {c['filename']}")

# Ek olarak ek almis / hatali yazim testi
print("\n=== BULANIK ESLESME TESTI (ek/hata) ===")
for q in ["femoris", "muskulus", "tibialis", "vertebrae", "arteri"]:
    ms = ocr.match_term(analysis.words, q, threshold=0.7)
    top = f"{ms[0].found_text} ({ms[0].similarity})" if ms else "—"
    print(f"  '{q}' -> {top}")

print("\nCiktilar:", os.listdir(OUT))


# ===================================================================== #
#  v0.2 - Offline kart/quiz + sayfa araligi + kart ice/disa aktarma
#  (Gercek PDF gerektirmez; sentetik metin uzerinde calisir.)
# ===================================================================== #
from dip import cards, flashcard_io, pipeline as pl

print("\n\n########## v0.2 OZELLIKLERI ##########")

# Sentetik sayfa metni (kart/quiz icin) - sozluk terimleri icerir
SAMPLE_TEXT = (
    "Femur is the longest and strongest bone in the human body and forms the "
    "hip joint with the pelvis. The tibia is the larger of the two leg bones "
    "and bears most of the body weight. Arteria femoralis is the main artery "
    "supplying blood to the lower limb. A neuron is the basic functional unit "
    "of the nervous system that transmits electrical signals. The patella is a "
    "small sesamoid bone located within the quadriceps tendon at the knee."
)
# (sayfa, metin, kelimeler) -> kelimeler bos verilebilir; o zaman metin taranir
pages_data = [(10, SAMPLE_TEXT, [])]

print("\n=== CUMLE BOLUTLEME ===")
sents = cards.split_sentences(SAMPLE_TEXT)
print("Cumle sayisi:", len(sents))
for s in sents:
    print("  -", s[:70], "..." if len(s) > 70 else "")

print("\n=== BILGI KARTLARI (offline) ===")
fcs = cards.generate_flashcards(pages_data, dictionary, max_cards=8)
assert fcs, "En az bir kart uretilmeliydi"
for c in fcs:
    print(f"  [{c.kind:10s} s.{c.page}] ON : {c.front[:55]}")
    print(f"  {'':17s} ARKA: {c.back[:60]}")

print("\n=== QUIZ (offline MCQ) ===")
quiz = cards.generate_quiz(pages_data, dictionary, n_questions=4)
for q in quiz:
    print("  S:", q.question.replace(chr(10), " ")[:70])
    print("     dogru ->", q.options[q.answer_index][:55])
    assert 0 <= q.answer_index < len(q.options)
    assert len(q.options) == 4

print("\n=== SAYFA ARALIGI AYRISTIRMA ===")
for spec, mx in [("25-50", 585), ("30", 585), ("10,12,40-42", 585), ("580-999", 585)]:
    pages = pl.parse_page_range(spec, mx)
    print(f"  '{spec}' -> {pages[:5]}{'...' if len(pages) > 5 else ''} ({len(pages)} sayfa)")

print("\n=== KART ICE/DISA AKTARMA (round-trip) ===")
csv_text = flashcard_io.export_csv(fcs)
back = flashcard_io.import_cards(csv_text.encode("utf-8"), "x.csv")
print("  CSV  ihrac/ithal kart sayisi:", len(back))
js = flashcard_io.export_json(fcs)
back2 = flashcard_io.import_cards(js.encode("utf-8"), "x.json")
print("  JSON ihrac/ithal kart sayisi:", len(back2))
imp = flashcard_io.import_cards(
    b'[{"front":"Femur nedir?","back":"En uzun kemik"},{"term":"arteria","definition":"atardamar"}]',
    "x.json")
print("  Esnek JSON alan eslemesi:", [(c.front or c.term, c.back) for c in imp])
print("  term_for_card secimi:",
      flashcard_io.term_for_card(imp[0], dictionary), "/",
      flashcard_io.term_for_card(imp[1], dictionary))

print("\nTUM v0.2 TESTLERI GECTI.")
