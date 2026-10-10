/* ── State ── */
let analyses = [];
let chartLine = null, chartPie = null, chartBar = null;
let selectedFiles = []; // Store multiple files
let currentDiningHall = null;
let analysesByHall = {}; // Store analyses per dining hall
let menuStateByHall = {}; // Store menu settings per dining hall
let currentTheme = "dark";

const themeToggle = document.getElementById("theme-toggle");
const themeToggleLabel = document.getElementById("theme-toggle-label");

function getThemePalette() {
  const css = getComputedStyle(document.documentElement);
  return {
    text: css.getPropertyValue("--text").trim(),
    textMuted: css.getPropertyValue("--text-muted").trim(),
    border: css.getPropertyValue("--border").trim(),
    surface: css.getPropertyValue("--surface").trim(),
  };
}

function applyTheme(theme) {
  currentTheme = theme === "light" ? "light" : "dark";
  document.documentElement.setAttribute("data-theme", currentTheme);
  if (themeToggleLabel) {
    themeToggleLabel.textContent = currentTheme === "light" ? "Dark mode" : "Light mode";
  }
  if (chartLine || chartPie || chartBar) {
    renderAnalytics();
  }
}

function initializeTheme() {
  const savedTheme = window.localStorage.getItem("binsight-theme");
  applyTheme(savedTheme === "light" ? "light" : "dark");
}

themeToggle?.addEventListener("click", () => {
  const nextTheme = currentTheme === "light" ? "dark" : "light";
  window.localStorage.setItem("binsight-theme", nextTheme);
  applyTheme(nextTheme);
});

function switchTab(tab) {
  document.querySelectorAll("nav button").forEach(b => b.classList.remove("active"));
  document.querySelectorAll(".tab-panel").forEach(p => p.classList.remove("active"));

  document.querySelector(`nav button[data-tab="${tab}"]`)?.classList.add("active");
  document.getElementById(`tab-${tab}`)?.classList.add("active");

  if (tab === "analytics") renderAnalytics();
  if (tab === "recommendations") initRecommendations();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

document.getElementById("start-dashboard-btn")?.addEventListener("click", () => {
  switchTab("ingest");
});

document.getElementById("home-jac-btn")?.addEventListener("click", () => {
  document.getElementById("home-jac-section")?.scrollIntoView({ behavior: "smooth", block: "start" });
});

async function loadHomeContent() {
  try {
    const res = await fetch("/api/home-content");
    if (!res.ok) {
      throw new Error("Failed to load home content");
    }
    const content = await res.json();
    renderHomeContent(content);
  } catch (err) {
    console.error(err);
  }
}

function renderHomeContent(content) {
  document.getElementById("home-hero-kicker").textContent = content.hero_kicker;
  document.getElementById("home-hero-title").textContent = content.hero_title;
  document.getElementById("home-hero-body").textContent = content.hero_body;
  document.getElementById("start-dashboard-btn").textContent = content.start_label;
  document.getElementById("home-jac-btn").textContent = content.jac_label;

  document.getElementById("home-impact-strip").innerHTML = (content.impacts || []).map(card => `
    <div class="impact-card">
      <span class="hero-stat-label">${card.label}</span>
      <strong>${card.value}</strong>
      <span class="hero-stat-meta">${card.meta}</span>
    </div>
  `).join("");

  document.getElementById("home-pitch-title").textContent = content.pitch_title;
  document.getElementById("home-pitch-body").innerHTML = (content.pitch_body || [])
    .map(paragraph => `<p>${paragraph}</p>`)
    .join("");

  document.getElementById("home-workflow-steps").innerHTML = (content.workflow_steps || []).map(step => `
    <div class="workflow-step">
      <span>${step.index}</span>
      <div>
        <strong>${step.title}</strong>
        <p>${step.description}</p>
      </div>
    </div>
  `).join("");

  document.getElementById("home-jac-title").textContent = content.jac_title;
  document.getElementById("home-jac-body").textContent = content.jac_body;
  document.getElementById("home-jac-snippet").textContent = content.jac_snippet;
  document.getElementById("home-jac-chips").innerHTML = (content.jac_chips || [])
    .map(chip => `<span>${chip}</span>`)
    .join("");

  const mediaCards = content.media_cards || [];
  if (mediaCards[0]) {
    const mediaOne = document.getElementById("home-media-1-image");
    mediaOne.src = mediaCards[0].image_url;
    mediaOne.alt = mediaCards[0].alt;
    document.getElementById("home-media-1-label").textContent = mediaCards[0].label;
  }
  if (mediaCards[1]) {
    const mediaTwo = document.getElementById("home-media-2-image");
    mediaTwo.src = mediaCards[1].image_url;
    mediaTwo.alt = mediaCards[1].alt;
    document.getElementById("home-media-2-label").textContent = mediaCards[1].label;
  }
}
/* ── Tab routing ── */
document.querySelectorAll("nav button").forEach(btn => {
  btn.addEventListener("click", () => {
    switchTab(btn.dataset.tab);
  });
});

/* ── Drag & drop upload ── */
const dropZone = document.getElementById("drop-zone");
const fileInput = document.getElementById("file-input");
const previewWrap = document.getElementById("preview-wrap");
const previewImg = document.getElementById("preview-img");

dropZone.addEventListener("dragover", e => { e.preventDefault(); dropZone.classList.add("dragover"); });
dropZone.addEventListener("dragleave", () => dropZone.classList.remove("dragover"));
dropZone.addEventListener("drop", e => {
  e.preventDefault();
  dropZone.classList.remove("dragover");
  setFiles(Array.from(e.dataTransfer.files));
});
fileInput.addEventListener("change", () => {
  setFiles(Array.from(fileInput.files));
});

function setFiles(files) {
  selectedFiles = files.filter(f => f.type.startsWith('image/'));
  const previewContainer = document.getElementById("preview-container");
  previewContainer.innerHTML = selectedFiles.map((file, idx) => {
    const url = URL.createObjectURL(file);
    return `<div style="position:relative;border-radius:8px;overflow:hidden;aspect-ratio:1;">
      <img src="${url}" alt="Preview ${idx + 1}" style="width:100%;height:100%;object-fit:cover;" />
      <div style="position:absolute;bottom:4px;right:4px;background:rgba(0,0,0,0.7);color:#fff;font-size:11px;padding:2px 6px;border-radius:4px;">${idx + 1}</div>
    </div>`;
  }).join("");
  previewWrap.style.display = selectedFiles.length > 0 ? "block" : "none";
  checkAnalyzeReady();
}

/* ── Menu source radio ── */
const radioOptions = document.querySelectorAll(".radio-option");
function applyMenuSourceSelection(selectedRadio) {
  if (!selectedRadio) return;

  radioOptions.forEach(opt => opt.classList.remove("selected"));
  selectedRadio.closest(".radio-option")?.classList.add("selected");

  document.getElementById("menu-url-wrap").classList.toggle("active", selectedRadio.value === "url");
  document.getElementById("menu-manual-wrap").classList.toggle("active", selectedRadio.value === "manual");

  if (selectedRadio.value !== "url") {
    document.getElementById("menu-preview-wrap").style.display = "none";
  }
}

document.querySelectorAll("input[name='menu-source']").forEach(radio => {
  radio.addEventListener("change", () => {
    applyMenuSourceSelection(radio);
  });
});

/* ── School selector with search ── */
const schoolSearch = document.getElementById("school-search");
schoolSearch.addEventListener("input", () => {
  const searchText = schoolSearch.value.toLowerCase();
  document.querySelectorAll(".school-option").forEach(option => {
    const text = option.textContent.toLowerCase();
    if (text.includes(searchText)) {
      option.classList.remove("hidden");
    } else {
      option.classList.add("hidden");
    }
  });
});

document.querySelectorAll(".school-option").forEach(option => {
  option.addEventListener("click", () => {
    document.querySelectorAll(".school-option").forEach(o => o.classList.remove("selected"));
    option.classList.add("selected");
    const url = option.dataset.url;
    if (url) {
      // Save current dining hall's menu state
      if (currentDiningHall) {
        analysesByHall[currentDiningHall] = analyses;
        menuStateByHall[currentDiningHall] = {
          menuSource: document.querySelector("input[name='menu-source']:checked").value,
          menuUrl: document.getElementById("menu-url").value,
          menuText: document.getElementById("menu-text").value,
          menuItems: document.getElementById("menu-items-edit").value
        };
      }
      
      // Switch to new dining hall
      currentDiningHall = url;
      analyses = analysesByHall[url] || [];
      
      // Restore menu state for this dining hall, default to URL mode for selected hall
      const savedMenu = menuStateByHall[url] || { menuSource: "url", menuUrl: url, menuText: "", menuItems: "" };
      const menuSource = (savedMenu.menuSource && savedMenu.menuSource !== "none") ? savedMenu.menuSource : "url";
      const menuUrl = savedMenu.menuUrl || url;
      document.querySelector(`input[name='menu-source'][value='${menuSource}']`).checked = true;
      document.getElementById("menu-url").value = menuUrl;
      document.getElementById("menu-text").value = savedMenu.menuText;
      document.getElementById("menu-items-edit").value = savedMenu.menuItems;
      
      // Trigger radio change to update UI
      const radioEvent = new Event("change", { bubbles: true });
      document.querySelector(`input[name='menu-source'][value='${menuSource}']`).dispatchEvent(radioEvent);
      
      schoolSearch.value = "";
      document.querySelectorAll(".school-option").forEach(o => o.classList.remove("hidden"));
      
      // Reset upload preview only (keep menu settings)
      selectedFiles = [];
      fileInput.value = "";
      previewWrap.style.display = "none";
      document.getElementById("preview-container").innerHTML = "";
      checkAnalyzeReady();
      
      // Render new analyses
      renderGallery();
    }
  });
});

/* ── Scrape menu ── */
const umichSampleMenus = {
  "https://dining.umich.edu/menus-locations/dining-halls/bursley/": ["Grilled Chicken", "Brown Rice", "Roasted Vegetables", "Pasta Primavera", "Caesar Salad", "Garlic Bread", "Apple Pie"],
  "https://dining.umich.edu/menus-locations/dining-halls/east-quad/": ["Beef Steak", "Mashed Potatoes", "Steamed Broccoli", "Fried Rice", "Stir Fry Vegetables", "Rolls", "Chocolate Cake"],
  "https://dining.umich.edu/menus-locations/dining-halls/markley/": ["Turkey Chili", "Rice Pilaf", "Green Beans", "Mac and Cheese", "Dinner Roll", "Garden Salad", "Brownie"],
  "https://dining.umich.edu/menus-locations/dining-halls/mosher-jordan/": ["Lemon Herb Chicken", "Roasted Potatoes", "Sauteed Spinach", "Penne Alfredo", "Garlic Bread", "Fruit Cup", "Cookie"],
  "https://dining.umich.edu/menus-locations/dining-halls/north-quad/": ["Grilled Salmon", "Quinoa Salad", "Roasted Brussels Sprouts", "Sweet Potato Fries", "Garden Salad", "Yogurt Parfait", "Berry Crisp"],
  "https://dining.umich.edu/menus-locations/dining-halls/south-quad/": ["Turkey Meatballs", "Marinara Sauce", "Whole Wheat Pasta", "Mixed Greens", "Italian Vegetables", "Breadsticks", "Tiramisu"],
  "https://dining.umich.edu/menus-locations/dining-halls/twigs-at-oxford/": ["Chicken Tenders", "French Fries", "Coleslaw", "Veggie Wrap", "Tomato Soup", "Fruit Salad", "Cookie Bar"],
  "https://dining.umich.edu/menus-locations/dining-halls/wolverine-village-dining-hall/": ["Baked Cod", "Wild Rice", "Steamed Carrots", "House Salad", "Dinner Roll", "Fresh Fruit", "Pudding"],
};

function getSampleMenu(url) {
  if (umichSampleMenus[url]) {
    return umichSampleMenus[url];
  }
  if (url.includes("dining.umich.edu")) {
    return ["House Salad", "Roasted Chicken", "Garlic Mashed Potatoes", "Steamed Greens", "Focaccia Bread", "Fruit Cup", "Cookies"];
  }
  return null;
}

const MEAL_PERIOD_ORDER = ["Breakfast", "Brunch", "Lunch", "Dinner", "Late Night"];

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  }[c]));
}

function renderGroupedMenuPreview(grouped, flatItems) {
  const container = document.getElementById("menu-grouped-preview");
  const toggleBtn = document.getElementById("menu-toggle-full");
  if (!container) return;

  const periods = Object.keys(grouped).sort((a, b) => {
    const ai = MEAL_PERIOD_ORDER.indexOf(a);
    const bi = MEAL_PERIOD_ORDER.indexOf(b);
    if (ai === -1 && bi === -1) return a.localeCompare(b);
    if (ai === -1) return 1;
    if (bi === -1) return -1;
    return ai - bi;
  });

  // If the server didn't return groups (fallback path), synthesize a single group
  // with each entry as a bare name (no nutrition).
  const toItemDict = x => typeof x === "string" ? { name: x, nutrition: [] } : x;
  const effectiveGrouped = periods.length
    ? grouped
    : { "Menu": (flatItems || []).map(toItemDict) };
  const effectivePeriods = periods.length ? periods : ["Menu"];

  const renderItem = item => {
    const it = toItemDict(item);
    const nutritionHtml = (it.nutrition && it.nutrition.length)
      ? `<div class="menu-item-nutrition">${it.nutrition.map(n => `<span>${escapeHtml(n)}</span>`).join("")}</div>`
      : "";
    return `<li><div class="menu-item-name">${escapeHtml(it.name)}</div>${nutritionHtml}</li>`;
  };

  const totalItems = effectivePeriods.reduce((sum, period) => sum + (effectiveGrouped[period] || []).length, 0);
  const html = effectivePeriods.map(period => {
    const items = effectiveGrouped[period] || [];
    if (!items.length) return "";
    const itemLabel = items.length === 1 ? "item" : "items";
    const itemLis = items.map(renderItem).join("");
    return `
      <div class="menu-period-group" data-period="${escapeHtml(period)}">
        <div class="menu-period-header">
          <div class="menu-period-label">${escapeHtml(period)} <span class="menu-period-count">${items.length}</span></div>
          <div class="menu-period-summary">${items.length} ${itemLabel}</div>
        </div>
        <ul class="menu-period-items" hidden>${itemLis}</ul>
      </div>
    `;
  }).join("");

  container.innerHTML = html;

  if (totalItems > 0) {
    toggleBtn.style.display = "inline";
    toggleBtn.dataset.expanded = "false";
    toggleBtn.textContent = `Read more (${totalItems} items)`;
  } else {
    toggleBtn.style.display = "none";
  }
}

document.getElementById("menu-toggle-full")?.addEventListener("click", (e) => {
  const btn = e.currentTarget;
  const expanded = btn.dataset.expanded === "true";
  const lists = document.querySelectorAll("#menu-grouped-preview .menu-period-items");
  lists.forEach(ul => { ul.hidden = expanded; });
  btn.dataset.expanded = expanded ? "false" : "true";
  const hiddenCount = document.querySelectorAll("#menu-grouped-preview .menu-period-items li").length;
  btn.textContent = expanded ? `Read more (${hiddenCount} items)` : "Show less";
});

document.getElementById("menu-toggle-edit")?.addEventListener("click", () => {
  const editArea = document.getElementById("menu-items-edit");
  if (!editArea) return;
  const visible = editArea.style.display !== "none";
  editArea.style.display = visible ? "none" : "block";
});

document.getElementById("scrape-btn").addEventListener("click", async () => {
  const url = document.getElementById("menu-url").value.trim();
  if (!url) return;

  const btn = document.getElementById("scrape-btn");
  const status = document.getElementById("scrape-status");
  btn.disabled = true;
  btn.textContent = "Scraping…";
  status.textContent = "";

  try {
    const res = await fetch("/api/scrape-menu", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url }),
    });
    
    let data;
    if (!res.ok) {
      // Fallback to sample menus if scraping fails
      const sample = getSampleMenu(url);
      if (sample) {
        data = {
          items: sample,
          confidence: "medium"
        };
      } else {
        const err = await res.json();
        throw new Error(err.detail || "Scrape failed");
      }
    } else {
      data = await res.json();
    }
    
    const previewWrap = document.getElementById("menu-preview-wrap");
    const badge = document.getElementById("menu-confidence-badge");
    const editArea = document.getElementById("menu-items-edit");

    badge.className = `badge badge-${data.confidence}`;
    badge.textContent = `${data.confidence} confidence`;

    editArea.value = data.items.join("\n");
    renderGroupedMenuPreview(data.grouped || {}, data.items || []);
    previewWrap.style.display = "block";
    status.textContent = `Found ${data.items.length} items.`;
  } catch (err) {
    status.style.color = "var(--danger)";
    status.textContent = `Error: ${err.message}`;
  } finally {
    btn.disabled = false;
    btn.textContent = "Scrape";
  }
});

/* ── Analyze button ── */
function checkAnalyzeReady() {
  document.getElementById("analyze-btn").disabled = selectedFiles.length === 0;
}

function saveCurrentMenuState() {
  if (currentDiningHall) {
    menuStateByHall[currentDiningHall] = {
      menuSource: document.querySelector("input[name='menu-source']:checked").value,
      menuUrl: document.getElementById("menu-url").value,
      menuText: document.getElementById("menu-text").value,
      menuItems: document.getElementById("menu-items-edit").value
    };
  }
}

document.getElementById("analyze-btn").addEventListener("click", async () => {
  if (!selectedFiles.length) return;
  
  // Save current menu state before analyzing
  saveCurrentMenuState();

  const btn = document.getElementById("analyze-btn");
  const statusEl = document.getElementById("analyze-status");
  const errEl = document.getElementById("analyze-error");

  btn.disabled = true;
  btn.textContent = "Analyzing…";
  statusEl.innerHTML = '<span class="spinner"></span> Sending to vision model…';
  errEl.style.display = "none";

  const menuSource = document.querySelector("input[name='menu-source']:checked").value;
  
  // Process each file
  for (let i = 0; i < selectedFiles.length; i++) {
    const form = new FormData();
    form.append("image", selectedFiles[i]);
    form.append("menu_source", menuSource);

    if (menuSource === "url") {
      form.append("menu_url", document.getElementById("menu-url").value.trim());
      // Use edited items if available
      const editArea = document.getElementById("menu-items-edit");
      if (editArea.value.trim()) {
        form.append("menu_source", "manual");
        form.append("menu_text", editArea.value.trim());
      }
    } else if (menuSource === "manual") {
      form.append("menu_text", document.getElementById("menu-text").value.trim());
    }

    try {
      const res = await fetch("/api/analyses", { method: "POST", body: form });
      const text = await res.text();
      if (!res.ok) {
        let message = text;
        try { message = JSON.parse(text).detail || JSON.parse(text).message || text; } catch {}
        throw new Error(message || "Analysis failed");
      }
      
      const record = JSON.parse(text);
      analyses.unshift(record);
      
      // Update status after each file
      statusEl.innerHTML = `<span class="spinner"></span> Processing image ${i + 1} of ${selectedFiles.length}...`;
    } catch (err) {
      errEl.textContent = `Error on image ${i + 1}: ${err.message}`;
      errEl.style.display = "block";
      statusEl.textContent = "";
    }
  }
  
  // Save current dining hall's analyses
  if (currentDiningHall) {
    analysesByHall[currentDiningHall] = analyses;
  }
  
  renderGallery();
  resetUploadForm();
  statusEl.textContent = "All analyses complete.";
  setTimeout(() => { statusEl.textContent = ""; }, 3000);
  btn.disabled = false;
  btn.textContent = "Analyze Waste";
  checkAnalyzeReady();
});

function resetUploadForm() {
  // Clear only upload section, preserve menu settings
  selectedFiles = [];
  fileInput.value = "";
  previewWrap.style.display = "none";
  document.getElementById("preview-container").innerHTML = "";
  // Hide menu preview but preserve the edited items
  document.getElementById("menu-preview-wrap").style.display = "none";
  checkAnalyzeReady();
}

document.getElementById("reset-gallery-btn").addEventListener("click", async () => {
  if (!analyses.length) return;
  showConfirmation({
    title: "Reset hall history?",
    message: `This will clear all past analyses for the current dining hall across the app and reset the analytics view. This action cannot be undone.`,
    confirmText: "Reset history",
    cancelText: "Cancel",
    onConfirm: async () => {
      try {
        const res = await fetch("/api/analyses?confirm=true", { method: "DELETE" });
        if (!res.ok) {
          throw new Error("Failed to clear saved analyses");
        }
      } catch (err) {
        console.error(err);
      }
      analyses = [];
      analysesByHall = {};
      if (currentDiningHall) {
        analysesByHall[currentDiningHall] = analyses;
      }
      renderGallery();
      renderAnalytics();
    }
  });
});

function showConfirmation({ title, message, confirmText = "Confirm", cancelText = "Cancel", onConfirm }) {
  document.getElementById("modal-body").innerHTML = `
    <div style="display:flex;flex-direction:column;gap:16px;">
      <div>
        <h2 style="font-size:18px;margin:0 0 8px;">${title}</h2>
        <p style="margin:0;color:var(--text-muted);font-size:13px;line-height:1.6;">${message}</p>
      </div>
      <div style="display:flex;justify-content:flex-end;gap:10px;flex-wrap:wrap;">
        <button class="btn btn-ghost" id="confirm-cancel-btn">${cancelText}</button>
        <button class="btn btn-danger" id="confirm-ok-btn">${confirmText}</button>
      </div>
    </div>`;

  document.getElementById("confirm-cancel-btn").addEventListener("click", closeModal);
  document.getElementById("confirm-ok-btn").addEventListener("click", () => {
    onConfirm();
    closeModal();
  });
  document.getElementById("modal-overlay").classList.add("open");
}

/* ── Gallery ── */
function renderGallery() {
  const gallery = document.getElementById("gallery");
  if (!analyses.length) {
    gallery.innerHTML = `<div class="empty-state"><div class="icon">&#128247;</div><p>No analyses yet.</p></div>`;
    gallery.classList.remove("gallery-rows");
    return;
  }
  
  // Add row layout class if 10+ analyses
  if (analyses.length >= 10) {
    gallery.classList.add("gallery-rows");
  } else {
    gallery.classList.remove("gallery-rows");
  }
  
  gallery.innerHTML = analyses.map(r => {
    const date = new Date(r.created_at).toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
    const sev = r.summary.waste_severity;
    return `<div class="gallery-card" data-id="${r.id}">
      <img src="/uploads/${r.image_filename}" alt="Bin scan" loading="lazy" />
      <div class="gallery-card-info">
        <div class="gallery-card-date">${date}</div>
        <div class="gallery-card-sev sev-${sev}">${sev.toUpperCase()}</div>
      </div>
    </div>`;
  }).join("");

  gallery.querySelectorAll(".gallery-card").forEach(card => {
    card.addEventListener("click", () => openModal(card.dataset.id));
  });
}

/* ── Modal ── */
function openModal(id) {
  const record = analyses.find(r => r.id === id);
  if (!record) return;

  const date = new Date(record.created_at).toLocaleString();
  const rows = record.items.map(item => `
    <tr>
      <td>${item.food}</td>
      <td>${item.category}</td>
      <td>${item.estimated_weight_oz.toFixed(1)} oz</td>
      <td>${item.estimated_portion_wasted_pct.toFixed(0)}%</td>
      <td>$${item.estimated_cost_usd.toFixed(2)}</td>
      <td><span class="pill ${item.avoidable ? 'pill-avoid' : 'pill-unavoid'}">${item.avoidable ? 'Avoidable' : 'Unavoidable'}</span></td>
    </tr>`).join("");

  document.getElementById("modal-body").innerHTML = `
    <div class="modal-header-block">
      <h2 class="modal-title">Waste Analysis</h2>
      <p class="modal-meta">${date}</p>
    </div>
    <img class="modal-image" src="/uploads/${record.image_filename}" alt="Bin scan" />
    <div class="modal-stats-grid">
      <div class="stat-card modal-stat-card"><div class="label">Severity</div><div class="value sev-${record.summary.waste_severity} modal-stat-value">${record.summary.waste_severity.toUpperCase()}</div></div>
      <div class="stat-card modal-stat-card"><div class="label">Total Weight</div><div class="value modal-stat-value">${record.summary.total_estimated_weight_oz.toFixed(1)} oz</div></div>
      <div class="stat-card modal-stat-card"><div class="label">Cost Wasted</div><div class="value modal-stat-value">$${record.summary.total_estimated_cost_usd.toFixed(2)}</div></div>
    </div>
    <table class="items-table">
      <thead><tr><th>Item</th><th>Category</th><th>Weight</th><th>% Wasted</th><th>Cost</th><th>Type</th></tr></thead>
      <tbody>${rows}</tbody>
    </table>
    ${record.notes ? `<p class="modal-notes">Notes: ${record.notes}</p>` : ""}
    <div class="modal-actions">
      <button class="btn btn-danger" id="modal-delete-btn">Delete</button>
    </div>`;

  document.getElementById("modal-delete-btn").addEventListener("click", () => deleteAnalysis(id));

  document.getElementById("modal-overlay").classList.add("open");
}

document.getElementById("modal-close").addEventListener("click", closeModal);
document.getElementById("modal-overlay").addEventListener("click", e => {
  if (e.target === document.getElementById("modal-overlay")) closeModal();
});

window.addEventListener("scroll", () => {
  const topbar = document.querySelector(".topbar");
  if (!topbar) return;
  topbar.classList.toggle("shrink", window.scrollY > 20);
});

function closeModal() {
  document.getElementById("modal-overlay").classList.remove("open");
}

async function deleteAnalysis(id) {
  if (!confirm("Delete this analysis?")) return;
  try {
    await fetch(`/api/analyses/${id}`, { method: "DELETE" });
    analyses = analyses.filter(r => r.id !== id);
    
    // Save current dining hall's analyses
    if (currentDiningHall) {
      analysesByHall[currentDiningHall] = analyses;
    }
    
    renderGallery();
    closeModal();
  } catch (err) {
    alert("Failed to delete: " + err.message);
  }
}

/* ── Analytics ── */
function renderAnalytics() {
  if (!analyses.length) {
    document.getElementById("stat-total").textContent = "—";
    document.getElementById("stat-cost").textContent = "—";
    document.getElementById("stat-avoidable").textContent = "—";
    document.getElementById("stat-top-cat").textContent = "—";
    if (chartLine) { chartLine.destroy(); chartLine = null; }
    if (chartPie) { chartPie.destroy(); chartPie = null; }
    if (chartBar) { chartBar.destroy(); chartBar = null; }
    return;
  }

  const sorted = [...analyses].sort((a, b) => new Date(a.created_at) - new Date(b.created_at));

  // Stat cards
  const totalCost = analyses.reduce((s, r) => s + r.summary.total_estimated_cost_usd, 0);
  const totalWeight = analyses.reduce((s, r) => s + r.summary.total_estimated_weight_oz, 0);
  const avoidableWeight = analyses.reduce((s, r) => s + r.summary.avoidable_weight_oz, 0);

  const catTotals = {};
  analyses.forEach(r => r.items.forEach(item => {
    catTotals[item.category] = (catTotals[item.category] || 0) + item.estimated_weight_oz;
  }));
  const topCat = Object.entries(catTotals).sort((a, b) => b[1] - a[1])[0]?.[0] || "—";

  document.getElementById("stat-total").textContent = analyses.length;
  document.getElementById("stat-cost").textContent = `$${totalCost.toFixed(2)}`;
  document.getElementById("stat-avoidable").textContent = totalWeight > 0
    ? `${((avoidableWeight / totalWeight) * 100).toFixed(0)}%`
    : "—";
  document.getElementById("stat-top-cat").textContent = topCat;

  const labels = sorted.map(r => new Date(r.created_at).toLocaleDateString(undefined, { month: "short", day: "numeric" }));
  const theme = getThemePalette();

  // Line chart
  if (chartLine) chartLine.destroy();
  chartLine = new Chart(document.getElementById("chart-line"), {
    type: "line",
    data: {
      labels,
      datasets: [
        {
          label: "Total Waste (oz)",
          data: sorted.map(r => r.summary.total_estimated_weight_oz),
          borderColor: "#00e5a0",
          backgroundColor: "rgba(0,229,160,0.08)",
          fill: true,
          tension: 0.3,
          pointBackgroundColor: "#00e5a0",
        },
        {
          label: "Avoidable (oz)",
          data: sorted.map(r => r.summary.avoidable_weight_oz),
          borderColor: "#ff4d4d",
          backgroundColor: "rgba(255,77,77,0.06)",
          fill: true,
          tension: 0.3,
          pointBackgroundColor: "#ff4d4d",
          borderDash: [4, 3],
        },
      ],
    },
    options: chartOptions("", theme),
  });

  // Pie chart
  const catColors = {
    protein: "#00e5a0", grain: "#f5a623", dairy: "#4fc3f7",
    fruit: "#ce93d8", vegetable: "#81c784", beverage: "#4dd0e1", dessert: "#f48fb1",
    bakery: "#d7a86e", snack: "#ffcc80", sauce: "#b39ddb", soup: "#ffab91", mixed: "#9fa8a1", other: "#6b6b6b",
  };
  const catLabels = Object.keys(catTotals);
  const catValues = catLabels.map(c => catTotals[c]);

  if (chartPie) chartPie.destroy();
  chartPie = new Chart(document.getElementById("chart-pie"), {
    type: "doughnut",
    data: {
      labels: catLabels,
      datasets: [{
        data: catValues,
        backgroundColor: catLabels.map(c => catColors[c] || "#6b6b6b"),
        borderColor: theme.surface,
        borderWidth: 2,
      }],
    },
    options: {
      plugins: {
        legend: { labels: { color: theme.text, font: { size: 11 }, padding: 12 } },
      },
      cutout: "60%",
      maintainAspectRatio: false,
    },
  });

  // Stacked bar chart
  if (chartBar) chartBar.destroy();
  chartBar = new Chart(document.getElementById("chart-bar"), {
    type: "bar",
    data: {
      labels,
      datasets: [
        {
          label: "Avoidable (oz)",
          data: sorted.map(r => r.summary.avoidable_weight_oz),
          backgroundColor: "rgba(255,77,77,0.75)",
          borderRadius: 3,
        },
        {
          label: "Unavoidable (oz)",
          data: sorted.map(r => r.summary.unavoidable_weight_oz),
          backgroundColor: "rgba(107,107,107,0.5)",
          borderRadius: 3,
        },
      ],
    },
    options: {
      ...chartOptions("", theme),
      scales: {
        x: { stacked: true, ticks: { color: theme.textMuted }, grid: { color: theme.border } },
        y: { stacked: true, ticks: { color: theme.textMuted }, grid: { color: theme.border } },
      },
    },
  });
}

function chartOptions(yLabel, theme = getThemePalette()) {
  return {
    maintainAspectRatio: false,
    plugins: {
      legend: { labels: { color: theme.text, font: { size: 11 } } },
    },
    scales: {
      x: { ticks: { color: theme.textMuted, font: { size: 11 } }, grid: { color: theme.border } },
      y: { ticks: { color: theme.textMuted, font: { size: 11 } }, grid: { color: theme.border } },
    },
  };
}

/* ── Recommendations ── */
let recsLoaded = false;

function initRecommendations() {
  if (recsLoaded) return;
  // Auto-generate if we have analyses with existing recommendations
  const withRecs = analyses.filter(r => r.recommendations);
  if (withRecs.length > 0) {
    renderRecommendations(withRecs[0].recommendations);
    recsLoaded = true;
  }
}

document.getElementById("gen-rec-btn").addEventListener("click", () => generateRecs(false));
document.getElementById("regen-rec-btn").addEventListener("click", () => generateRecs(true));

async function generateRecs(force = false) {
  if (!analyses.length) {
    document.getElementById("rec-error").textContent = "No analyses available. Upload some bin images first.";
    document.getElementById("rec-error").style.display = "block";
    return;
  }

  const loadEl = document.getElementById("rec-loading");
  const errEl = document.getElementById("rec-error");
  const contentEl = document.getElementById("rec-content");
  const genBtn = document.getElementById("gen-rec-btn");

  loadEl.style.display = "block";
  errEl.style.display = "none";
  contentEl.style.display = "none";
  genBtn.disabled = true;

  try {
    const ids = analyses.map(r => r.id);
    const res = await fetch(`/api/recommendations?force=${force}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ analysis_ids: ids }),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "Failed to generate recommendations");
    }
    const recs = await res.json();
    renderRecommendations(recs);
    recsLoaded = true;
    document.getElementById("regen-rec-btn").style.display = "inline-block";
  } catch (err) {
    errEl.textContent = `Error: ${err.message}`;
    errEl.style.display = "block";
  } finally {
    loadEl.style.display = "none";
    genBtn.disabled = false;
  }
}

function renderRecommendations(recs) {
  const contentEl = document.getElementById("rec-content");
  const overallEl = document.getElementById("rec-overall");
  const overallTextEl = document.getElementById("rec-overall-text");

  const grouped = { high: [], medium: [], low: [] };
  (recs.insights || []).forEach(ins => {
    grouped[ins.priority]?.push(ins);
  });

  const insightsHtml = ["high", "medium", "low"].map(priority => {
    if (!grouped[priority].length) return "";
    const cards = grouped[priority].map(ins => `
      <div class="insight-card">
        <div class="insight-action">${ins.action}</div>
        <div class="insight-rationale">${ins.rationale}</div>
      </div>`).join("");
    return `<div class="rec-section">
      <h3 class="${priority}">${priority.toUpperCase()} PRIORITY</h3>
      ${cards}
    </div>`;
  }).join("");

  const deltaHtml = recs.menu_delta?.length
    ? `<div class="card">
        <div class="card-title">Menu Delta</div>
        <ul class="delta-list">${recs.menu_delta.map(d => `<li>${d}</li>`).join("")}</ul>
      </div>`
    : "";

  // Display overall recommendation
  if (recs.summary_text) {
    overallTextEl.textContent = recs.summary_text;
    overallEl.style.display = "block";
  } else {
    overallEl.style.display = "none";
  }

  const genDate = recs.generated_at
    ? `<p style="font-size:11px;color:var(--text-muted);margin-top:16px;">Generated ${new Date(recs.generated_at).toLocaleString()}</p>`
    : "";

  contentEl.innerHTML = `
    ${insightsHtml}
    ${deltaHtml}
    ${genDate}`;

  contentEl.style.display = "block";
}

/* ── Init ── */
async function loadAppConfig() {
  try {
    const res = await fetch("/api/app-config");
    if (!res.ok) throw new Error("Config unavailable");
    return await res.json();
  } catch (e) {
    return { reset_analyses_on_load: false };
  }
}

async function loadAnalyses() {
  const appConfig = await loadAppConfig();

  try {
    if (appConfig.reset_analyses_on_load) {
      await fetch("/api/analyses?confirm=true", { method: "DELETE" });
    }
  } catch (e) {
    // ignore if reset endpoint is unavailable
  }

  try {
    const res = await fetch("/api/analyses");
    analyses = res.ok ? await res.json() : [];
  } catch (e) {
    analyses = [];
  }
  analysesByHall = {};

  // Set default dining hall if not already set
  if (!currentDiningHall) {
    currentDiningHall = "https://dining.umich.edu/menus-locations/dining-halls/bursley/";
    document.querySelector("[data-url='" + currentDiningHall + "']")?.classList.add("selected");
    
    // Initialize default menu state
    menuStateByHall[currentDiningHall] = {
      menuSource: "url",
      menuUrl: currentDiningHall,
      menuText: "",
      menuItems: ""
    };
  }

  if (currentDiningHall) {
    analysesByHall[currentDiningHall] = analyses;
  }

  applyMenuSourceSelection(document.querySelector("input[name='menu-source']:checked"));
  renderGallery();
}

initializeTheme();
loadHomeContent();
loadAnalyses();
