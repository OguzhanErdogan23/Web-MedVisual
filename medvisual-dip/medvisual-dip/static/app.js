/* MedVisual DIP - arayuz mantigi (vanilla JS, framework yok)
   Modlar: cards | image-cards | quiz | add-image | segment */
(() => {
  "use strict";

  const $ = (id) => document.getElementById(id);
  const state = {
    docId: null, pageCount: 0, hasText: false, page: 1,
    mode: null, cards: [], quiz: null,
  };

  // ---- elemanlar ----
  const drop = $("drop"), fileInput = $("fileInput");
  const docInfo = $("docInfo"), docName = $("docName"), docPages = $("docPages"), docText = $("docText");
  const modeCard = $("modeCard"), modesEl = $("modes");
  const paramCard = $("paramCard"), legendCard = $("legendCard");
  const rangeInput = $("rangeInput"), rangeNote = $("rangeNote");
  const pageInput = $("pageInput"), pageOf = $("pageOf"), prevPage = $("prevPage"), nextPage = $("nextPage");
  const termInput = $("termInput"), termList = $("termList");
  const maxCards = $("maxCards"), nQuiz = $("nQuiz");
  const cardsFile = $("cardsFile"), importInfo = $("importInfo");
  const sourceSel = $("sourceSel");
  const runBtn = $("runBtn");
  const placeholder = $("placeholder"), output = $("output");
  const toast = $("toast"), busy = $("busy"), busyText = $("busyText");
  const segRangeInput = $("segRangeInput");

  // ---- calisma ortami elemanlari ----
  const studyOverlay = $("studyOverlay");
  const studyClose = $("studyClose");
  const studyCardInner = $("studyCardInner");
  const studyFront = $("studyFront");
  const studyBack = $("studyBack");
  const studyProgress = $("studyProgress");
  const studyScore = $("studyScore");
  const studyActions = $("studyActions");
  const studyWrong = $("studyWrong");
  const studyCorrect = $("studyCorrect");
  const studyPrev = $("studyPrev");
  const studyNext = $("studyNext");
  const printArea = $("printArea");

  const MODE_LABELS = {
    "cards": "Bilgi Kartı Oluştur",
    "image-cards": "Görselli Bilgi Kartı Oluştur",
    "quiz": "Test / Quiz Oluştur",
    "add-image": "Kartlara Görsel Ekle",
    "segment": "Sayfayı Analiz Et",
  };

  // ---- yardimcilar ----
  let toastTimer = null;
  function showToast(msg) {
    toast.textContent = msg; toast.classList.remove("hidden");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.add("hidden"), 3600);
  }
  function setBusy(on, text) {
    if (text) busyText.textContent = text;
    busy.classList.toggle("hidden", !on);
  }
  async function postJSON(url, body) {
    const r = await fetch(url, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!r.ok) {
      let msg = "İstek başarısız (" + r.status + ").";
      try { const d = await r.json(); msg = d.error || msg; } catch {}
      throw new Error(msg);
    }
    return r.json();
  }
  function escapeHtml(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, m =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[m]));
  }
  function el(tag, cls, html) {
    const e = document.createElement(tag);
    if (cls) e.className = cls;
    if (html != null) e.innerHTML = html;
    return e;
  }

  // ---- sozluk onerileri ----
  fetch("/api/terms").then(r => r.json()).then(d => {
    (d.terms || []).forEach(t => {
      const o = document.createElement("option"); o.value = t; termList.appendChild(o);
    });
  }).catch(() => {});

  // LLM durum gostergesi
  fetch('/api/health')
    .then(r => r.json())
    .then(h => {
      const el2 = document.getElementById('llm-status');
      if (!el2) return;
      if (h && h.dictionary_loaded) {
        el2.textContent = 'Sozluk: ' + h.dictionary_size + ' terim yuklu';
      }
    })
    .catch(() => {});

  // ---- yukleme ----
  drop.addEventListener("dragover", (e) => { e.preventDefault(); drop.classList.add("drag"); });
  drop.addEventListener("dragleave", () => drop.classList.remove("drag"));
  drop.addEventListener("drop", (e) => {
    e.preventDefault(); drop.classList.remove("drag");
    if (e.dataTransfer.files.length) handleUpload(e.dataTransfer.files[0]);
  });
  fileInput.addEventListener("change", () => {
    if (fileInput.files.length) handleUpload(fileInput.files[0]);
  });

  async function handleUpload(file) {
    if (!file.name.toLowerCase().endsWith(".pdf")) {
      showToast("Lütfen bir PDF dosyası seçin."); return;
    }
    setBusy(true, "PDF yükleniyor…");
    try {
      const fd = new FormData(); fd.append("file", file);
      const r = await fetch("/api/upload", { method: "POST", body: fd });
      if (!r.ok) {
        let msg = "Yükleme başarısız (" + r.status + ").";
        try { const d = await r.json(); msg = d.error || msg; } catch {}
        throw new Error(msg);
      }
      const data = await r.json();

      state.docId = data.doc_id;
      state.pageCount = data.page_count;
      state.hasText = !!data.has_text;
      state.page = 1;

      docName.textContent = data.filename;
      docPages.textContent = data.page_count + " sayfa";
      docText.innerHTML = data.has_text
        ? '<span class="ok">var (hızlı)</span>'
        : '<span class="no">yok — OCR</span>';
      docInfo.classList.remove("hidden");
      modeCard.setAttribute("aria-disabled", "false");

      pageInput.value = 1; pageInput.max = data.page_count;
      pageOf.textContent = "/ " + data.page_count;
      sourceSel.value = data.has_text ? "auto" : "ocr";
      rangeInput.value = "1-" + Math.min(10, data.page_count);

      showToast("Yüklendi. Şimdi ne yapmak istediğini seç.");
    } catch (err) {
      showToast(err.message);
    } finally {
      setBusy(false);
    }
  }

  // ---- mod secimi ----
  modesEl.addEventListener("click", (e) => {
    const btn = e.target.closest(".mode");
    if (!btn || modeCard.getAttribute("aria-disabled") === "true") return;
    state.mode = btn.dataset.mode;
    [...modesEl.querySelectorAll(".mode")].forEach(m => m.classList.toggle("sel", m === btn));
    applyMode();
  });

  function applyMode() {
    paramCard.setAttribute("aria-disabled", "false");
    runBtn.disabled = false;
    runBtn.textContent = MODE_LABELS[state.mode] || "Çalıştır";
    legendCard.classList.toggle("hidden", state.mode !== "segment");

    // alan gorunurlugu (data-show ozniteligine gore)
    document.querySelectorAll("#paramCard .field[data-show]").forEach(f => {
      const modes = f.getAttribute("data-show").split(" ");
      f.classList.toggle("hidden", !modes.includes(state.mode));
    });
    rangeNote.textContent = state.mode === "add-image"
      ? "Kartlara görsel bu sayfalarda aranır."
      : "Tüm dökümanı değil, yalnızca bu sayfalar işlenir.";

    const rangeWarning = $("rangeWarning");
    if (rangeWarning) {
      const showWarn = ["cards", "image-cards", "quiz"].includes(state.mode);
      rangeWarning.classList.toggle("hidden", !showWarn);
    }
  }

  // ---- sayfa gezinme (segment) ----
  function clampPage(p) { p = parseInt(p, 10) || 1; return Math.min(Math.max(1, p), state.pageCount || 1); }
  prevPage.addEventListener("click", () => { pageInput.value = clampPage(state.page - 1); state.page = +pageInput.value; });
  nextPage.addEventListener("click", () => { pageInput.value = clampPage(state.page + 1); state.page = +pageInput.value; });
  pageInput.addEventListener("change", () => { state.page = clampPage(pageInput.value); pageInput.value = state.page; });

  // ---- mevcut kart dosyasi ice aktarma ----
  cardsFile.addEventListener("change", async () => {
    if (!cardsFile.files.length) return;
    setBusy(true, "Kartlar okunuyor…");
    try {
      const fd = new FormData(); fd.append("file", cardsFile.files[0]);
      const r = await fetch("/api/cards/import", { method: "POST", body: fd });
      if (!r.ok) {
        let msg = "İçe aktarma başarısız (" + r.status + ").";
        try { const d = await r.json(); msg = d.error || msg; } catch {}
        throw new Error(msg);
      }
      const data = await r.json();
      state.cards = data.cards;
      importInfo.innerHTML = '<span class="ok">' + data.count + " kart içe aktarıldı.</span><br>";
      const isb = el("button", "study-start-btn", "📖 Çalışmaya Başla");
      isb.style.marginTop = "8px";
      isb.addEventListener("click", () => startStudy(state.cards));
      importInfo.appendChild(isb);
      showToast(data.count + " kart yüklendi.");
    } catch (err) {
      showToast(err.message);
    } finally {
      setBusy(false);
    }
  });

  // ---- CALISTIR ----
  runBtn.addEventListener("click", run);

  async function run() {
    if (!state.docId) { showToast("Önce bir PDF yükle."); return; }
    if (!state.mode) { showToast("Bir görev seç."); return; }
    const source = sourceSel.value;
    try {
      if (state.mode === "segment") return await runSegment(source);
      if (state.mode === "quiz") return await runQuiz(source);
      if (state.mode === "add-image") return await runAddImage(source);
      // cards | image-cards
      return await runCards(source, state.mode === "image-cards");
    } catch (err) {
      showToast(err.message);
    } finally {
      setBusy(false);
    }
  }

  function showOutput() {
    placeholder.classList.add("hidden");
    output.classList.remove("hidden");
    output.innerHTML = "";
  }

  // ===================== MOD: BILGI KARTI / GORSELLI ===================== //
  async function runCards(source, withImages) {
    setBusy(true, "Sayfalar işleniyor, kartlar üretiliyor…");
    const enhance = document.getElementById('enhance-toggle') ? document.getElementById('enhance-toggle').checked : false;
    const data = await postJSON("/api/generate/cards", {
      doc_id: state.docId, range: rangeInput.value, source,
      max_cards: parseInt(maxCards.value, 10) || 30, enhance,
    });
    setBusy(false);
    state.cards = data.cards;
    if (!data.cards.length) {
      showOutput();
      const msg = data.reason || "Bu aralıkta sözlük terimi içeren tanım cümlesi bulunamadı.";
      const div = document.createElement('div');
      div.style.cssText = 'padding:20px;background:#fff3cd;border:1px solid #ffc107;border-radius:8px;margin:10px 0;';
      div.innerHTML = '<strong>&#9888; Kart üretilemedi</strong><br>' + escapeHtml(msg) +
        '<br><br><small>İpucu: <a href="/api/health" target="_blank">/api/health</a> adresinden ortam durumunu kontrol et.</small>';
      output.appendChild(div);
      return;
    }
    renderCards(withImages, data);
  }

  function renderCards(withImages, meta) {
    showOutput();
    if (meta.llm_enhanced) {
      const badge = document.createElement('div');
      badge.innerHTML = '<span style="background:#1a73e8;color:white;padding:3px 8px;border-radius:4px;font-size:0.8em;margin-bottom:8px;display:inline-block;">Gemini ile Zenginlestirildi</span>';
      output.appendChild(badge);
    }
    output.appendChild(resultHead(
      (withImages ? "Görselli Bilgi Kartları" : "Bilgi Kartları"),
      `${state.cards.length} kart · sayfa ${rangeInput.value} · kaynak: ${meta.source}`
        + (meta.truncated ? " · (aralık kırpıldı)" : "")
    ));
    output.appendChild(exportBar());

    const grid = el("div", "card-grid");
    state.cards.forEach((c, i) => grid.appendChild(makeStudyCard(c, i, withImages)));
    output.appendChild(grid);

    const actRow = el("div", "card-act-row");
    const studyBtn = el("button", "study-start-btn", "📖 Çalışmaya Başla");
    studyBtn.addEventListener("click", () => startStudy(state.cards));
    actRow.appendChild(studyBtn);
    const saveLibBtn = el("button", "lib-save-btn", "💾 Kütüphaneye Ekle");
    saveLibBtn.addEventListener("click", async () => {
      const name = window.prompt("Kart seti adı:", "Kart Seti " + new Date().toLocaleDateString("tr-TR"));
      if (name === null) return;
      const hasImages = state.cards.some(c => c.image_url && c.image_url.startsWith("/work/"));
      setBusy(true, hasImages ? "Görseller kaydediliyor…" : "Kaydediliyor…");
      try {
        await libAddSet(name || "Kart Seti", state.cards);
        showToast('"' + (name || "Kart Seti") + '" kütüphaneye eklendi.');
      } catch (e) { showToast(e.message); } finally { setBusy(false); }
    });
    actRow.appendChild(saveLibBtn);
    output.appendChild(actRow);
  }

  function makeStudyCard(c, idx, withImages) {
    const wrap = el("div", "study");
    const kindBadge = c.kind === "cloze" ? "boşluk" : "tanım";
    wrap.appendChild(el("div", "study-top",
      `<span class="badge ${c.kind}">${kindBadge}</span><span class="pg">s.${c.page}</span>`));

    const flip = el("div", "flip");
    flip.innerHTML =
      `<div class="flip-inner">
         <div class="face front"><div class="lbl">SORU / ÖN</div><div class="txt">${escapeHtml(c.front)}</div></div>
         <div class="face back"><div class="lbl">CEVAP / ARKA</div><div class="txt">${escapeHtml(c.back)}</div></div>
       </div>`;
    flip.addEventListener("click", () => flip.classList.toggle("flipped"));
    wrap.appendChild(flip);

    // secilen gorsel
    const imgBox = el("div", "card-img" + (c.image_url ? "" : " hidden"));
    if (c.image_url) imgBox.innerHTML = `<img src="${c.image_url}" alt=""><span>${escapeHtml(c.image_label || "")}</span>`;
    wrap.appendChild(imgBox);

    if (withImages || state.mode === "add-image") {
      const bar = el("div", "card-actions");
      const btn = el("button", "ghost small", c.image_url ? "🔄 Görseli değiştir" : "🔎 Görsel bul");
      btn.addEventListener("click", () => findImageForCard(c, idx, wrap, btn));
      bar.appendChild(btn);
      const rmBtn = el("button", "ghost small btn-danger", "✕ Görseli Kaldır");
      rmBtn.style.display = c.image_url ? "" : "none";
      rmBtn.addEventListener("click", () => {
        c.image_url = ""; c.image_label = "";
        const ib = wrap.querySelector(".card-img");
        if (ib) { ib.classList.add("hidden"); ib.innerHTML = ""; }
        btn.textContent = "🔎 Görsel bul";
        rmBtn.style.display = "none";
      });
      bar.appendChild(rmBtn);
      wrap.appendChild(bar);
    }
    return wrap;
  }

  async function findImageForCard(card, idx, wrap, btn) {
    let cand = wrap.querySelector(".cand-pick");
    if (cand) { cand.remove(); }  // toggle kapat
    btn.disabled = true; btn.textContent = "Aranıyor…";
    try {
      const data = await postJSON("/api/cards/match", {
        doc_id: state.docId, range: rangeInput.value, source: sourceSel.value,
        term: card.term || "", front: card.front, back: card.back,
      });
      const box = el("div", "cand-pick");
      const head = data.matched
        ? `<b>"${escapeHtml(data.match_text || data.term)}"</b> bulundu (s.${data.best_page}, benzerlik ${data.similarity}). Bir görsel seç:`
        : `Terim (<b>${escapeHtml(data.term)}</b>) bu aralıkta net bulunamadı; en olası figürler:`;
      box.appendChild(el("div", "cand-head", head + ` <span class="dim">${data.pages_scanned} sayfa tarandı</span>`));
      if (!data.candidates.length) {
        box.appendChild(emptyMsg("Bu aralıkta figür adayı çıkmadı. Aralığı bu terimin geçtiği sayfalara daralt."));
      } else {
        const g = el("div", "cand-grid");
        data.candidates.forEach(cc => g.appendChild(makeCandPick(cc, card, wrap)));
        box.appendChild(g);
      }
      wrap.appendChild(box);
    } catch (err) {
      showToast(err.message);
    } finally {
      btn.disabled = false; btn.textContent = card.image_url ? "Görseli değiştir" : "🔎 Görsel bul";
    }
  }

  function makeCandPick(cc, card, wrap) {
    const e = el("div", "cand");
    e.innerHTML =
      `<div class="thumb"><img src="${cc.url}?t=${Date.now()}" alt="${escapeHtml(cc.label)}" title="Buyutmek icin tikla" style="cursor:zoom-in;"></div>
       <div class="meta"><div class="label">${escapeHtml(cc.label)}</div>
       <div class="dist">s.${cc.page} · uzaklık ${cc.distance}px</div>
       <button class="ghost small cand-sel-btn" style="margin-top:6px;">Bu Görseli Seç</button></div>`;
    e.querySelector(".thumb img").addEventListener("click", (ev) => {
      ev.stopPropagation();
      showImgPreview(cc.url, cc.label);
    });
    e.querySelector(".cand-sel-btn").addEventListener("click", () => {
      card.image_url = cc.url; card.image_label = cc.label + " (s." + cc.page + ")";
      const imgBox = wrap.querySelector(".card-img");
      imgBox.classList.remove("hidden");
      imgBox.innerHTML = `<img src="${cc.url}" alt=""><span>${escapeHtml(card.image_label)}</span>`;
      wrap.querySelectorAll(".cand").forEach(x => x.classList.remove("sel"));
      e.classList.add("sel");
      const rmBtn = wrap.querySelector(".card-actions .btn-danger");
      if (rmBtn) rmBtn.style.display = "";
      const findBtn = wrap.querySelector(".card-actions .ghost.small:not(.btn-danger)");
      if (findBtn) findBtn.textContent = "🔄 Görseli değiştir";
      showToast("Görsel karta eklendi.");
    });
    return e;
  }

  function showImgPreview(url, label) {
    const ov = el("div", "img-preview-ov");
    ov.innerHTML = `<div class="img-preview-box"><img src="${escapeHtml(url)}" alt="${escapeHtml(label)}"><div class="img-preview-label">${escapeHtml(label)}</div><div class="img-preview-close">✕ Kapatmak için tıkla</div></div>`;
    ov.addEventListener("click", () => ov.remove());
    document.body.appendChild(ov);
  }

  // ===================== MOD: KARTLARA GORSEL EKLE ===================== //
  async function runAddImage(source) {
    if (!state.cards.length) { showToast("Önce bir kart dosyası (CSV/JSON) yükle."); return; }
    renderCards(true, { source: "—", truncated: false });
    // baslik metnini ozellestir
    const h = output.querySelector(".rhead .sub");
    if (h) h.textContent = `${state.cards.length} içe aktarılan kart · görseller sayfa ${rangeInput.value} aralığında aranır`;
  }

  // ===================== MOD: QUIZ ===================== //
  async function runQuiz(source) {
    setBusy(true, "Sorular üretiliyor…");
    const enhanceQuiz = document.getElementById('enhance-toggle') ? document.getElementById('enhance-toggle').checked : false;
    const data = await postJSON("/api/generate/quiz", {
      doc_id: state.docId, range: rangeInput.value, source,
      n: parseInt(nQuiz.value, 10) || 10, enhance: enhanceQuiz,
    });
    setBusy(false);
    state.quiz = data.questions || [];
    showOutput();
    if (!state.quiz.length) {
      output.appendChild(emptyMsg(data.warning || "Bu aralıkta yeterli terim bulunamadı."));
      return;
    }
    output.appendChild(resultHead("Test / Quiz",
      `${state.quiz.length} soru · sayfa ${rangeInput.value}` + (data.truncated ? " · (aralık kırpıldı)" : "")));

    const form = el("div", "quiz");
    state.quiz.forEach((q, qi) => form.appendChild(makeQuestion(q, qi)));
    output.appendChild(form);

    const bar = el("div", "quiz-bar");
    const submit = el("button", "primary", "Cevapları Kontrol Et");
    const score = el("span", "score", "");
    submit.addEventListener("click", () => gradeQuiz(score));
    bar.appendChild(submit); bar.appendChild(score);
    output.appendChild(bar);

    // Quiz disa aktarim
    const qExportBar = el("div", "export-bar", "<span>Quiz'i dışa aktar:</span>");
    [["JSON", "json"], ["CSV", "csv"], ["PDF", "pdf"]].forEach(([lbl, fmt]) => {
      const b = el("button", "ghost small", lbl);
      b.addEventListener("click", () => exportQuiz(fmt));
      qExportBar.appendChild(b);
    });
    output.appendChild(qExportBar);
  }

  function makeQuestion(q, qi) {
    const card = el("div", "qcard");
    card.appendChild(el("div", "q-no", `Soru ${qi + 1} <span class="pg">s.${q.page}</span>`));
    card.appendChild(el("div", "q-text", escapeHtml(q.question).replace(/\n/g, "<br>")));
    const opts = el("div", "opts");
    q.options.forEach((o, oi) => {
      const id = `q${qi}_o${oi}`;
      const lab = el("label", "opt");
      lab.innerHTML = `<input type="radio" name="q${qi}" value="${oi}" id="${id}"><span>${escapeHtml(o)}</span>`;
      opts.appendChild(lab);
    });
    card.appendChild(opts);
    card.dataset.answer = q.answer_index;
    card.dataset.qi = qi;
    return card;
  }

  function gradeQuiz(scoreEl) {
    let correct = 0;
    document.querySelectorAll(".qcard").forEach(card => {
      const ans = +card.dataset.answer;
      const picked = card.querySelector("input:checked");
      const labels = card.querySelectorAll(".opt");
      labels.forEach(l => l.classList.remove("right", "wrong"));
      labels[ans].classList.add("right");
      if (picked) {
        const pi = +picked.value;
        if (pi === ans) correct++; else labels[pi].classList.add("wrong");
      }
    });
    scoreEl.textContent = `Skor: ${correct} / ${state.quiz.length}`;
  }

  // ===================== MOD: SAYFA BOLUTLEME ===================== //
  async function runSegment(source) {
    const segRange = segRangeInput ? segRangeInput.value.trim() : "";
    const term = termInput.value.trim();

    if (segRange && term) {
      // Aralik tarama: birden fazla sayfa
      setBusy(true, "Sayfa aralığı taranıyor…");
      showOutput();
      output.appendChild(resultHead("Sayfa Bölütleme Aralık Taraması",
        `Terim: "${term}" · Aralık: ${segRange}`));

      // Aralik ayristir (basit)
      const pages = [];
      for (const part of segRange.split(",")) {
        const m = part.trim().match(/^(\d+)(?:-(\d+))?$/);
        if (m) {
          const a = parseInt(m[1], 10), b = parseInt(m[2] || m[1], 10);
          for (let p = a; p <= Math.min(b, a + 29); p++) pages.push(p);
        }
      }

      let found = 0;
      for (const p of pages) {
        busyText.textContent = `Sayfa ${p} / ${pages[pages.length-1]} analiz ediliyor…`;
        try {
          const data = await postJSON("/api/analyze", { doc_id: state.docId, page: p, term, source });
          if (data.candidates && data.candidates.length > 0) {
            found++;
            const sec = el("div", "seg-section");
            sec.style.marginBottom = "16px";
            sec.appendChild(resultHead(`Sayfa ${p}`, `${data.n_figure_blocks} figür · ${data.match && data.match.matched ? "✓ Terim bulundu" : "terim bulunamadı"}`));
            renderSegment(data, sec);
            output.appendChild(sec);
          }
        } catch (err) { /* sayfayi atla */ }
      }
      if (!found) output.appendChild(emptyMsg(`${pages.length} sayfada "${term}" için figür adayı bulunamadı.`));
      setBusy(false);
    } else {
      // Tek sayfa
      state.page = clampPage(pageInput.value);
      setBusy(true, "Sayfa " + state.page + " analiz ediliyor…");
      const data = await postJSON("/api/analyze", {
        doc_id: state.docId, page: state.page, term: termInput.value.trim(), source,
      });
      setBusy(false);
      renderSegment(data);
    }
  }

  function renderSegment(d, container) {
    const target = container || output;
    if (!container) showOutput();
    target.appendChild(resultHead("Sayfa Bölütleme",
      `sayfa ${d.page} · ${d.n_text_blocks} metin / ${d.n_figure_blocks} figür bloğu · ${d.width}×${d.height} · kaynak: ${d.source}`));

    if (d.match) {
      const m = el("div", "match");
      m.innerHTML = d.match.matched
        ? `<span class="ok">✓ Eşleşme:</span> "${escapeHtml(d.match.match_text)}" · benzerlik ${d.match.similarity}`
        : `<span class="no">⚠ Terim bulunamadı</span> · en büyük figürler aday sunuldu`;
      target.appendChild(m);
    }

    const grid = el("div", "seg-layout");
    const figw = el("figure", "seg-wrap",
      `<figcaption>Bölütleme (yeşil=metin, kırmızı=figür)</figcaption>
       <div class="seg-frame"><img src="${d.segmentation_url}?t=${Date.now()}" alt="Bölütleme"></div>`);
    grid.appendChild(figw);

    const side = el("div", "side");
    const tb = el("div", "block", "<h3>Tespit Edilen Terimler</h3>");
    const chips = el("div", "chips");
    if (d.detected_terms && d.detected_terms.length) {
      d.detected_terms.forEach(t => {
        const c = el("span", "chip", escapeHtml(t.term) + `<span class="sim">${t.similarity}</span>`);
        c.title = `Sayfada: "${t.found_text}" — tıkla, bu terim için aday üret`;
        c.addEventListener("click", () => { termInput.value = t.term; runSegment(sourceSel.value); });
        chips.appendChild(c);
      });
    } else { chips.appendChild(emptyMsg("Sözlükten terim tespit edilmedi.")); }
    tb.appendChild(chips); side.appendChild(tb);

    const cb = el("div", "block", '<h3>Görsel Adayları</h3>');
    const cg = el("div", "cand-grid");
    if (d.candidates && d.candidates.length) {
      d.candidates.forEach(cc => {
        const e = el("div", "cand",
          `<div class="thumb"><img src="${cc.url}?t=${Date.now()}"></div>
           <div class="meta"><div class="label">${escapeHtml(cc.label)}</div>
           <div class="dist">uzaklık ${cc.distance}px</div></div>`);
        cg.appendChild(e);
      });
    } else { cg.appendChild(emptyMsg("Aday üretmek için bir hedef terim gir ya da yukarıdaki bir terime tıkla.")); }
    cb.appendChild(cg); side.appendChild(cb);

    grid.appendChild(side);
    target.appendChild(grid);
  }

  // ===================== ORTAK PARCALAR ===================== //
  function resultHead(title, sub) {
    return el("div", "rhead", `<h2>${escapeHtml(title)}</h2><div class="sub">${escapeHtml(sub)}</div>`);
  }
  function emptyMsg(msg) { return el("div", "empty-box", escapeHtml(msg)); }

  function exportBar() {
    const bar = el("div", "export-bar", "<span>Disa aktar:</span>");
    [["JSON", "json"], ["CSV", "csv"], ["Anki (TSV)", "anki"], ["TXT", "txt"], ["PDF", "pdf"]].forEach(([lbl, fmt]) => {
      const b = el("button", "ghost small", lbl);
      b.addEventListener("click", () => exportCards(fmt));
      bar.appendChild(b);
    });
    return bar;
  }

  function exportCards(fmt) {
    if (!state.cards.length) { showToast("Disari aktarilacak kart yok."); return; }

    if (fmt === "pdf") {
      if (!printArea) { showToast("PDF destegi yuklenemedi."); return; }
      printArea.innerHTML = "<h1>MedVisual - Bilgi Kartlari</h1>" +
        state.cards.map((c, i) =>
          "<div class='print-card'>" +
          "<div class='print-q'>" + (i+1) + ". " + escapeHtml(c.front) + "</div>" +
          (c.image_url ? "<img class='print-img' src='" + escapeHtml(c.image_url) + "' alt=''>" : "") +
          "<div class='print-a'>" + escapeHtml(c.back) + "</div>" +
          "</div>"
        ).join("");
      window.print();
      return;
    }

    let content = "", mime = "text/plain", ext = "txt";
    if (fmt === "json") {
      content = JSON.stringify(state.cards, null, 2); mime = "application/json"; ext = "json";
    } else if (fmt === "csv") {
      const esc = (s) => '"' + String(s == null ? "" : s).replace(/"/g, '""') + '"';
      content = "front,back,term,page\n" + state.cards.map(c =>
        [c.front, c.back, c.term, c.page].map(esc).join(",")).join("\n");
      mime = "text/csv"; ext = "csv";
    } else if (fmt === "txt") {
      content = state.cards.map((c, i) =>
        "SORU " + (i+1) + ": " + c.front + "\nCEVAP: " + c.back
      ).join("\n\n---\n\n");
      mime = "text/plain"; ext = "txt";
    } else {
      content = state.cards.map(c => {
        let back = c.back;
        if (c.image_url) back += '<br><img src="' + location.origin + c.image_url + '">';
        return c.front + "\t" + back;
      }).join("\n");
      mime = "text/tab-separated-values"; ext = "tsv";
    }
    const blob = new Blob([content], { type: mime });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "medvisual_kartlar." + ext;
    a.click(); URL.revokeObjectURL(a.href);
    showToast("Indirildi: medvisual_kartlar." + ext);
  }

  function exportQuiz(fmt) {
    if (!state.quiz || !state.quiz.length) { showToast("Disari aktarilacak quiz yok."); return; }

    if (fmt === "pdf") {
      if (!printArea) { showToast("PDF destegi yuklenemedi."); return; }
      printArea.innerHTML = "<h1>MedVisual - Test / Quiz</h1>" +
        state.quiz.map((q, i) =>
          "<div class='print-question'>" +
          "<div class='print-q'>Soru " + (i+1) + " (s." + q.page + "): " + escapeHtml(q.question) + "</div>" +
          "<div class='print-options'>" + q.options.map((o, oi) =>
            "<div class='print-option" + (oi === q.answer_index ? " print-correct" : "") + "'>" +
            String.fromCharCode(65+oi) + ") " + escapeHtml(o) + "</div>"
          ).join("") + "</div></div>"
        ).join("");
      window.print();
      return;
    }

    let content = "", mime = "text/plain", ext = "txt";
    if (fmt === "json") {
      content = JSON.stringify(state.quiz, null, 2); mime = "application/json"; ext = "json";
    } else {
      const esc = (s) => '"' + String(s == null ? "" : s).replace(/"/g, '""') + '"';
      content = "soru,secenekler,dogru_cevap,sayfa\n" + state.quiz.map(q =>
        [q.question, q.options.join(" | "), q.options[q.answer_index], q.page].map(esc).join(",")).join("\n");
      mime = "text/csv"; ext = "csv";
    }
    const blob = new Blob([content], { type: mime });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob); a.download = "medvisual_quiz." + ext;
    a.click(); URL.revokeObjectURL(a.href);
    showToast("Indirildi: medvisual_quiz." + ext);
  }

  // ===================== KUTUPHANE ===================== //
  const _LIB_KEY = "medvisual_library";
  function libLoad() {
    try { return JSON.parse(localStorage.getItem(_LIB_KEY) || "[]"); } catch { return []; }
  }
  function libSave(sets) {
    try {
      localStorage.setItem(_LIB_KEY, JSON.stringify(sets));
    } catch (e) {
      // localStorage doldu — gorselleri data URL yerine bos birak, metinler kalsin
      const stripped = sets.map(s => ({
        ...s, cards: s.cards.map(c => ({ ...c, image_url: c.image_url && c.image_url.startsWith("data:") ? "" : c.image_url, image_label: c.image_url && c.image_url.startsWith("data:") ? "" : c.image_label }))
      }));
      try { localStorage.setItem(_LIB_KEY, JSON.stringify(stripped)); } catch {}
      throw new Error("Depolama doldu — görseller kaydedilemedi ama kartlar metinleriyle eklendi.");
    }
  }

  async function _toDataUrl(url) {
    try {
      const r = await fetch(url);
      if (!r.ok) return url;
      const blob = await r.blob();
      return await new Promise(res => { const fr = new FileReader(); fr.onload = () => res(fr.result); fr.readAsDataURL(blob); });
    } catch { return url; }
  }

  async function libAddSet(name, cards) {
    // Sunucu tarafli gorsel URL'lerini base64 data URL'ye cevir (kalici depolama icin)
    const persisted = await Promise.all(cards.map(async c => {
      const cp = Object.assign({}, c);
      if (cp.image_url && cp.image_url.startsWith("/work/")) {
        cp.image_url = await _toDataUrl(cp.image_url);
      }
      return cp;
    }));
    const sets = libLoad();
    sets.unshift({ id: Date.now().toString(36), name: name || "Kart Seti", created: new Date().toISOString(), cards: persisted });
    libSave(sets);
  }
  function libDeleteSet(id) { libSave(libLoad().filter(s => s.id !== id)); }
  function libRenameSet(id, name) {
    const sets = libLoad(); const s = sets.find(x => x.id === id);
    if (s) { s.name = name; libSave(sets); }
  }

  function openLibrary() {
    renderLibraryPanel();
    const lo = $("libOverlay");
    if (lo) { lo.classList.remove("hidden"); document.body.style.overflow = "hidden"; }
  }
  function closeLibrary() {
    const lo = $("libOverlay");
    if (lo) { lo.classList.add("hidden"); document.body.style.overflow = ""; }
  }

  function renderLibraryPanel() {
    const container = $("libSets");
    const empty = $("libEmpty");
    if (!container) return;
    const sets = libLoad();
    container.innerHTML = "";
    if (!sets.length) {
      if (empty) empty.classList.remove("hidden"); return;
    }
    if (empty) empty.classList.add("hidden");
    sets.forEach(s => {
      const row = el("div", "lib-row");
      const info = el("div", "lib-info");
      const nameEl = el("span", "lib-name", escapeHtml(s.name));
      nameEl.contentEditable = "true";
      nameEl.title = "Adı değiştirmek için tıkla ve düzenle";
      nameEl.addEventListener("blur", () => libRenameSet(s.id, nameEl.textContent.trim() || s.name));
      nameEl.addEventListener("keydown", e2 => { if (e2.key === "Enter") { e2.preventDefault(); nameEl.blur(); } });
      const meta = el("span", "lib-meta", s.cards.length + " kart · " + new Date(s.created).toLocaleDateString("tr-TR"));
      info.appendChild(nameEl); info.appendChild(meta);
      const acts = el("div", "lib-actions");
      const studyLibBtn = el("button", "ghost small", "📖 Çalış");
      studyLibBtn.addEventListener("click", () => { closeLibrary(); startStudy(s.cards); });
      const delBtn = el("button", "ghost small btn-danger", "🗑");
      delBtn.title = "Bu seti sil";
      delBtn.addEventListener("click", () => {
        if (window.confirm('"' + s.name + '" setini silmek istiyor musun?')) { libDeleteSet(s.id); renderLibraryPanel(); }
      });
      acts.appendChild(studyLibBtn); acts.appendChild(delBtn);
      row.appendChild(info); row.appendChild(acts);
      container.appendChild(row);
    });
  }

  // ===================== CALISMA MODU ===================== //
  const studyState = { cards: [], idx: 0, correct: 0, wrong: 0, flipped: false };

  function startStudy(cards) {
    if (!cards || !cards.length) { showToast("Calisacak kart yok."); return; }
    studyState.cards = cards.slice();
    studyState.idx = 0;
    studyState.correct = 0;
    studyState.wrong = 0;
    studyState.flipped = false;
    studyOverlay.classList.remove("hidden");
    document.body.style.overflow = "hidden";
    showStudyCard();
  }

  function showStudyCard() {
    const card = studyState.cards[studyState.idx];
    if (!card) return;
    studyFront.innerHTML = escapeHtml(card.front);
    let backHtml = escapeHtml(card.back);
    if (card.image_url) {
      backHtml += "<br><img src='" + escapeHtml(card.image_url) + "' class='study-img' alt='" + escapeHtml(card.image_label || "") + "'>";
    }
    studyBack.innerHTML = backHtml;
    studyCardInner.classList.remove("flipped");
    studyActions.classList.add("hidden");
    studyState.flipped = false;
    studyProgress.textContent = (studyState.idx + 1) + " / " + studyState.cards.length;
    const total = studyState.correct + studyState.wrong;
    studyScore.textContent = total > 0
      ? "Dogru: " + studyState.correct + " / " + total
      : "";
  }

  if (studyOverlay) {
    // Kart tikla - cevabi goster
    $("studyCard").addEventListener("click", () => {
      studyState.flipped = !studyState.flipped;
      studyCardInner.classList.toggle("flipped", studyState.flipped);
      studyActions.classList.toggle("hidden", !studyState.flipped);
    });

    studyCorrect.addEventListener("click", () => {
      studyState.correct++;
      nextStudyCard();
    });

    studyWrong.addEventListener("click", () => {
      studyState.wrong++;
      nextStudyCard();
    });

    studyPrev.addEventListener("click", () => {
      if (studyState.idx > 0) {
        studyState.idx--;
        showStudyCard();
      }
    });

    studyNext.addEventListener("click", nextStudyCard);

    studyClose.addEventListener("click", () => {
      studyOverlay.classList.add("hidden");
      document.body.style.overflow = "";
    });
  }

  function nextStudyCard() {
    if (studyState.idx < studyState.cards.length - 1) {
      studyState.idx++;
      showStudyCard();
    } else {
      // Son kart - sonuc goster
      const total = studyState.correct + studyState.wrong;
      const pct = total > 0 ? Math.round(studyState.correct / total * 100) : 0;
      studyFront.textContent = "Calisma Tamamlandi!";
      studyBack.textContent = "Dogru: " + studyState.correct + " / " + total + " (" + pct + "%)";
      studyCardInner.classList.add("flipped");
      studyActions.classList.add("hidden");
      studyProgress.textContent = "Bitti!";
      studyScore.textContent = pct + "% basari";
    }
  }
  // ---- Kutuphane buton dinleyicileri ----
  const libOpenBtn = $("libOpenBtn");
  if (libOpenBtn) libOpenBtn.addEventListener("click", openLibrary);
  const libCloseBtn = $("libClose");
  if (libCloseBtn) libCloseBtn.addEventListener("click", closeLibrary);
  document.addEventListener("keydown", e3 => { if (e3.key === "Escape") closeLibrary(); });

  // ---- Direkt kart dosyasi / PDF yukleme (calisma kisa yolu) ----
  function _showStudyFileResult(info, count, label, file) {
    info.innerHTML = '<span class="ok">' + count + " kart hazır (" + label + ").</span><br>";
    const sb = el("button", "study-start-btn", "📖 Çalışmaya Başla");
    sb.style.marginTop = "8px";
    sb.addEventListener("click", () => startStudy(state.cards));
    info.appendChild(sb);
    const sv = el("button", "lib-save-btn", "💾 Kütüphaneye Ekle");
    sv.style.marginTop = "4px";
    sv.addEventListener("click", async () => {
      const nm = window.prompt("Kart seti adı:", file.name.replace(/\.[^.]+$/, ""));
      if (nm === null) return;
      setBusy(true, "Kaydediliyor…");
      try {
        await libAddSet(nm || "Kart Seti", state.cards);
        showToast('"' + (nm || "Kart Seti") + '" kütüphaneye eklendi.');
      } catch (e) { showToast(e.message); } finally { setBusy(false); }
    });
    info.appendChild(document.createElement("br"));
    info.appendChild(sv);
  }

  async function _importStudyPdf(file) {
    const info = $("studyFileInfo");
    if (info) info.innerHTML = "";
    setBusy(true, "PDF yükleniyor…");
    const fd = new FormData(); fd.append("file", file);
    const r1 = await fetch("/api/upload", { method: "POST", body: fd });
    if (!r1.ok) {
      let msg = "PDF yüklenemedi.";
      try { const d = await r1.json(); msg = d.error || msg; } catch {}
      throw new Error(msg);
    }
    const up = await r1.json();
    state.docId = up.doc_id; state.pageCount = up.page_count; state.hasText = !!up.has_text;

    let range = "1-" + up.page_count;
    if (up.page_count > 15) {
      const ans = window.prompt(
        "PDF " + up.page_count + " sayfalı. Hangi sayfalar işlensin?",
        "1-" + Math.min(20, up.page_count)
      );
      if (ans === null) return;
      range = ans.trim() || ("1-" + Math.min(20, up.page_count));
    }

    setBusy(true, "Kartlar üretiliyor…");
    const r2 = await fetch("/api/generate/cards", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ doc_id: up.doc_id, range, source: "auto", max_cards: 40, enhance: false })
    });
    if (!r2.ok) {
      let msg = "Kart üretilemedi.";
      try { const d = await r2.json(); msg = d.error || msg; } catch {}
      throw new Error(msg);
    }
    const cd = await r2.json();
    if (!cd.cards || !cd.cards.length) throw new Error("Bu aralıkta kart üretilemedi. Farklı sayfa aralığı deneyin.");
    state.cards = cd.cards;
    if (info) _showStudyFileResult(info, cd.count, "sayfa " + range, file);
    showToast(cd.count + " kart üretildi.");
  }

  async function _importStudyCards(file) {
    const info = $("studyFileInfo");
    if (info) info.innerHTML = "";
    setBusy(true, "Kartlar okunuyor…");
    const fd = new FormData(); fd.append("file", file);
    const r = await fetch("/api/cards/import", { method: "POST", body: fd });
    if (!r.ok) {
      let msg = "Aktarma başarısız (" + r.status + ").";
      try { const d = await r.json(); msg = d.error || msg; } catch {}
      throw new Error(msg);
    }
    const data = await r.json();
    state.cards = data.cards;
    if (info) _showStudyFileResult(info, data.count, file.name, file);
    showToast(data.count + " kart yüklendi.");
  }

  const studyFileInput = $("studyFileInput");
  if (studyFileInput) {
    studyFileInput.addEventListener("change", async () => {
      if (!studyFileInput.files.length) return;
      const file = studyFileInput.files[0];
      try {
        if (file.name.toLowerCase().endsWith(".pdf")) {
          await _importStudyPdf(file);
        } else {
          await _importStudyCards(file);
        }
      } catch (err) {
        showToast(err.message);
        const info = $("studyFileInfo");
        if (info) info.innerHTML = '<span style="color:#dc2626;">' + escapeHtml(err.message) + "</span>";
      } finally {
        setBusy(false);
        studyFileInput.value = "";
      }
    });
  }

  // ===================== VARSAYILAN KITAPLAR ===================== //
  function loadDefaultBooks() {
    fetch("/api/books")
      .then(r => r.json())
      .then(data => {
        const list = $("defaultBooksList");
        if (!list) return;
        list.innerHTML = "";
        if (!data.books || !data.books.length) {
          list.innerHTML = '<div class="db-empty">Varsayılan kitap bulunamadı.<br><small>books/ klasörüne PDF eklenebilir.</small></div>';
          return;
        }
        data.books.forEach(book => {
          const btn = document.createElement("button");
          btn.className = "db-book-btn";
          btn.innerHTML = `<span class="db-ico">📘</span><span class="db-name">${escapeHtml(book.display)}</span><span class="db-meta">${book.pages ? book.pages + " sayfa" : ""} · ${book.size_mb} MB</span>`;
          btn.addEventListener("click", () => selectDefaultBook(book.name, book.display));
          list.appendChild(btn);
        });
      })
      .catch(() => {
        const list = $("defaultBooksList");
        if (list) list.innerHTML = '<div class="db-empty">Kitap listesi alınamadı.</div>';
      });
  }

  async function selectDefaultBook(name, display) {
    setBusy(true, `"${display}" yükleniyor…`);
    try {
      const r = await fetch("/api/books/load", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name }),
      });
      if (!r.ok) {
        const d = await r.json().catch(() => ({}));
        throw new Error(d.error || "Kitap yüklenemedi.");
      }
      const data = await r.json();
      state.docId = data.doc_id;
      state.pageCount = data.page_count;
      state.hasText = !!data.has_text;
      state.page = 1;

      const mid = Math.floor(data.page_count / 2);
      const suggestStart = Math.max(1, mid - 10);
      const suggestEnd = Math.min(data.page_count, mid + 10);

      $("docName").textContent = data.filename;
      $("docPages").textContent = data.page_count + " sayfa";
      $("docText").innerHTML = data.has_text
        ? '<span class="ok">var (hızlı)</span>'
        : '<span class="no">yok — OCR</span>';
      $("docInfo").classList.remove("hidden");
      $("modeCard").setAttribute("aria-disabled", "false");

      $("pageInput").value = 1;
      $("pageInput").max = data.page_count;
      $("pageOf").textContent = "/ " + data.page_count;
      $("sourceSel").value = data.has_text ? "auto" : "ocr";
      $("rangeInput").value = `${suggestStart}-${suggestEnd}`;

      showToast(`"${display}" yüklendi (${data.page_count} sayfa). Önerilen aralık: ${suggestStart}-${suggestEnd}`);

      document.querySelectorAll(".db-book-btn").forEach(b => b.classList.remove("sel"));
      const allBtns = document.querySelectorAll(".db-book-btn");
      allBtns.forEach(b => { if (b.querySelector(".db-name").textContent === display) b.classList.add("sel"); });
    } catch (err) {
      showToast(err.message);
    } finally {
      setBusy(false);
    }
  }

  loadDefaultBooks();

  // ===================== NASIL KULLANILIR TURU ===================== //
  const TOUR_STEPS = [
    {
      title: "MedVisual'e Hoş Geldiniz!",
      content: `<p>Bu uygulama, tıbbi PDF kaynaklarından otomatik olarak bilgi kartları, görselli kartlar ve çoktan seçmeli testler üretir.</p>
      <ul>
        <li>📖 <b>Bilgi Kartı</b> — Latince terim ve tanım çiftleri</li>
        <li>🖼️ <b>Görselli Kart</b> — Karta uygun anatomik şema</li>
        <li>❓ <b>Test / Quiz</b> — Çoktan seçmeli sorular</li>
        <li>🔬 <b>Sayfa Bölütleme</b> — DIP hattını görsel olarak incele</li>
      </ul>
      <div class="tour-tip">💡 Varsayılan kitaplar panelinden hızlıca başlayabilirsiniz!</div>`
    },
    {
      title: "Adım 1: Kitap veya PDF Seç",
      content: `<p>İki yoldan birini seçin:</p>
      <ul>
        <li><b>📖 Varsayılan Kitaplar</b> panelinden hazır kitaplardan birini seçin (PDF yüklemeye gerek yok)</li>
        <li><b>Kendi PDF'inizi</b> sürükle-bırak veya dosya seçici ile yükleyin</li>
      </ul>
      <p>PDF yüklendikten sonra sayfa sayısı ve metin katmanı bilgisi gösterilir.</p>
      <div class="tour-tip">💡 Metin seçilebilen PDF'lerde (dijital baskı) işlem çok daha hızlıdır.</div>`
    },
    {
      title: "Adım 2: Görev Seç",
      content: `<p>"Ne yapmak istersin?" bölümünden bir mod seçin:</p>
      <ul>
        <li><b>🃏 Bilgi Kartı Oluştur</b> — Terim–tanım kartları üretir</li>
        <li><b>🖼️ Görselli Bilgi Kartı</b> — Karta en uygun figürü önerir</li>
        <li><b>❓ Test / Quiz</b> — Çoktan seçmeli sorular üretir</li>
        <li><b>➕ Karta Görsel Ekle</b> — Mevcut kartlarınıza figür bulur</li>
        <li><b>🔬 Sayfa Bölütleme</b> — Görüntü işleme hattını sergiler</li>
      </ul>`
    },
    {
      title: "Adım 3: Sayfa Aralığı Girin",
      content: `<p>İşlenecek sayfa aralığını belirleyin (ör. <code>45-65</code>)</p>
      <div class="tour-tip">⚠️ <b>Önemli İpucu:</b> En iyi sonuçlar için kitabın <b>orta bölümlerinden 10–20 sayfalık aralıklar</b> seçin. Çok kısa aralıklar yeterli terim içermeyebilir; çok geniş aralıklar işlem süresini uzatır.</div>
      <p style="margin-top:10px;">Örnekler: <code>50-70</code> · <code>100-120</code> · <code>25,30,45-50</code></p>`
    },
    {
      title: "Adım 4: Çalıştır ve Sonuçları İncele",
      content: `<p>"Çalıştır" butonuna tıklayın ve sonuçları sağ panelde görün.</p>
      <ul>
        <li>Kartları <b>çevir</b> (tıkla) ve <b>çalışmaya başla</b></li>
        <li>Görselli kartlarda "🔎 Görsel bul" ile en uygun figürü seçin</li>
        <li>Quiz'de cevapları işaretleyip "Cevapları Kontrol Et"e tıklayın</li>
        <li>Kartları <b>JSON / CSV / Anki TSV</b> olarak dışa aktarın</li>
      </ul>`
    },
    {
      title: "Ek Özellikler",
      content: `<ul>
        <li>📚 <b>Kütüphane</b> — Kartlarınızı kaydedip sonra tekrar çalışın</li>
        <li>🤖 <b>Gemini ile Zenginleştir</b> — Google API key ile klinik kaliteli kartlar</li>
        <li>➕ <b>Çoklu Kaynak</b> — Birden fazla kitaptan aynı anda kart üretimi</li>
        <li>📤 <b>İçe Aktarma</b> — Anki, CSV, JSON kart dosyalarını yükle ve çalış</li>
      </ul>
      <div class="tour-tip">✅ Artık kullanmaya hazırsınız! Varsayılan kitaplardan birini seçerek başlayın.</div>`
    }
  ];

  let tourCurrentStep = 0;

  function openTour() {
    tourCurrentStep = 0;
    renderTourStep();
    const ov = $("tourOverlay");
    if (ov) { ov.classList.remove("hidden"); document.body.style.overflow = "hidden"; }
  }

  function closeTour() {
    const ov = $("tourOverlay");
    if (ov) { ov.classList.add("hidden"); document.body.style.overflow = ""; }
  }

  function renderTourStep() {
    const step = TOUR_STEPS[tourCurrentStep];
    if (!step) return;
    const contentEl = $("tourContent");
    const stepNum = $("tourStepNum");
    const prevBtn = $("tourPrev");
    const nextBtn = $("tourNext");
    if (contentEl) contentEl.innerHTML = `<h3>${step.title}</h3>${step.content}`;
    if (stepNum) stepNum.textContent = `Adım ${tourCurrentStep + 1} / ${TOUR_STEPS.length}`;
    if (prevBtn) prevBtn.disabled = tourCurrentStep === 0;
    if (nextBtn) nextBtn.textContent = tourCurrentStep === TOUR_STEPS.length - 1 ? "✓ Kapat" : "Sonraki ›";
  }

  const tourBtn = $("tourBtn");
  if (tourBtn) tourBtn.addEventListener("click", openTour);

  const tourClose = $("tourClose");
  if (tourClose) tourClose.addEventListener("click", closeTour);

  const tourPrev = $("tourPrev");
  if (tourPrev) tourPrev.addEventListener("click", () => {
    if (tourCurrentStep > 0) { tourCurrentStep--; renderTourStep(); }
  });

  const tourNext = $("tourNext");
  if (tourNext) tourNext.addEventListener("click", () => {
    if (tourCurrentStep < TOUR_STEPS.length - 1) { tourCurrentStep++; renderTourStep(); }
    else closeTour();
  });

  document.addEventListener("keydown", e4 => {
    if (!$("tourOverlay") || $("tourOverlay").classList.contains("hidden")) return;
    if (e4.key === "Escape") closeTour();
    if (e4.key === "ArrowRight") { if (tourCurrentStep < TOUR_STEPS.length - 1) { tourCurrentStep++; renderTourStep(); } }
    if (e4.key === "ArrowLeft") { if (tourCurrentStep > 0) { tourCurrentStep--; renderTourStep(); } }
  });
})();
