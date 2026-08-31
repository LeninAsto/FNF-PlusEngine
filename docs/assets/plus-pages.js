(async function () {
  const lang = document.body?.dataset?.lang === "es" ? "es" : "en";
  const pageId = document.body?.dataset?.plusPage || "video";
  const dataBase = new URL("../data/", document.currentScript.src);
  const videoBase = new URL("videos/", document.currentScript.src);

  function esc(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  function local(value, fallback = "") {
    if (value == null) return fallback;
    if (typeof value === "string") return value;
    return value[lang] || value.en || fallback;
  }

  async function readJson(name, fallback) {
    try {
      const response = await fetch(new URL(name, dataBase), { cache: "no-cache" });
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`);
      return await response.json();
    } catch (error) {
      console.warn(`[plus-docs] Could not load ${name}`, error);
      return fallback;
    }
  }

  const [ui, api] = await Promise.all([
    readJson(`plus-ui.${lang}.json`, {}),
    readJson("plus-api.json", { order: [], pages: {} })
  ]);

  function routeFor(id) {
    return `../${id}/`;
  }

  function languageRoute(id) {
    return lang === "es" ? `../../../../plus/pages/${id}/` : `../../../es/plus/pages/${id}/`;
  }

  function pages() {
    return api.order.map((id) => {
      const page = api.pages[id];
      return page ? { id, ...page, title: local(page[lang]?.title || page.en?.title), summary: local(page[lang]?.summary || page.en?.summary) } : null;
    }).filter(Boolean);
  }

  function renderTopbar() {
    const home = document.querySelector('.top-actions a[data-plus-home]');
    const psych = document.querySelector('.top-actions a[data-plus-psych]');
    const actions = document.querySelector(".top-actions");
    const theme = document.getElementById("themeToggle");

    if (home) home.textContent = ui.home || home.textContent;
    if (psych) psych.textContent = ui.psych || psych.textContent;
    if (theme && theme.textContent.trim().toLowerCase() === "theme") theme.textContent = ui.theme || "Theme";

    if (actions && !actions.querySelector(".lang-switch")) {
      const link = document.createElement("a");
      link.className = "text-link lang-switch";
      link.textContent = ui.languageSwitchLabel || (lang === "es" ? "English" : "Español");
      link.href = languageRoute(pageId);
      actions.insertBefore(link, theme);
    }
  }

  function renderShell() {
    const sidebar = document.querySelector(".psych-sidebar");
    if (!sidebar) return;
    sidebar.querySelector(".eyebrow").textContent = ui.plusPages || "Plus Pages";
    sidebar.querySelector("h2").textContent = ui.chooseSection || "Choose a section";
    sidebar.querySelector(".sidebar-copy").textContent = ui.navLead || "";
    sidebar.querySelector("label").textContent = ui.searchPages || "Search pages";
    document.getElementById("pageSearch").placeholder = ui.searchPlaceholder || "";
  }

  function renderNav() {
    const nav = document.getElementById("pageNav");
    const query = document.getElementById("pageSearch")?.value.toLowerCase().trim() || "";
    const filtered = pages().filter((page) => {
      if (!query) return true;
      return `${page.id} ${page.title} ${page.summary}`.toLowerCase().includes(query);
    });

    if (!filtered.length) {
      nav.innerHTML = `<div class="inline-note">${esc(ui.noSearchResults || "No results.")}</div>`;
      return;
    }

    nav.innerHTML = filtered.map((page) => `
      <a class="${page.id === pageId ? "is-active" : ""}" href="${esc(routeFor(page.id))}">
        ${esc(page.title)}
        <small>${esc(page.summary)}</small>
      </a>
    `).join("");
  }

  function hero(page) {
    const meta = page[lang] || page.en || {};
    return `
      <article class="card section-card page-route-hero">
        <p class="eyebrow">Plus Engine</p>
        <h1>${esc(meta.title)}</h1>
        <p>${esc(meta.intro || meta.summary)}</p>
        <div class="page-route-meta">
          <span class="chip">${esc(ui.folderRoute || "Folder route")}</span>
          <span class="chip">${esc(ui.sourcePreset || "JSON preset")}</span>
        </div>
        ${page.warning ? `<div class="inline-note danger-note"><strong>${esc(ui.warning || "Warning")}:</strong> ${esc(local(page.warningText))}</div>` : ""}
      </article>
    `;
  }

  function functionList(items) {
    if (!Array.isArray(items) || !items.length) return "";
    return `
      <article class="card section-card">
        <h2>${esc(ui.functions || "Functions")}</h2>
        <div class="function-list">
          ${items.map((item) => {
            const signature = typeof item === "string" ? item : item.signature;
            const name = typeof item === "string" ? signature.split("(")[0] : item.name;
            const desc = typeof item === "string" ? "" : local(item);
            return `
              <div class="function-item">
                <h2 id="${esc(name)}">${esc(name)}</h2>
                <p class="function-sig"><code>${esc(signature)}</code></p>
                ${desc ? `<p class="function-desc">${esc(desc)}</p>` : ""}
                ${paramList(item)}
              </div>
            `;
          }).join("")}
        </div>
      </article>
    `;
  }

  function paramList(item) {
    if (!item || !Array.isArray(item.params) || !item.params.length) return "";
    return `
      <ul class="function-params">
        ${item.params.map((param) => `
          <li>
            <strong>${esc(param.name)}</strong>
            ${param.type ? `<em>${esc(param.type)}</em>` : ""}
            <span>${esc(local(param.description || param))}</span>
          </li>
        `).join("")}
      </ul>
    `;
  }

  function variableList(items) {
    if (!Array.isArray(items) || !items.length) return "";
    return `
      <article class="card section-card">
        <h2>${esc(ui.variables || "Variables")}</h2>
        <ul class="psych-list">
          ${items.map((item) => `<li><span class="code-pill">${esc(item.name)}</span> - ${esc(local(item))}</li>`).join("")}
        </ul>
      </article>
    `;
  }

  function modchartGroups(groups) {
    if (!Array.isArray(groups) || !groups.length) return "";
    return groups.map((group) => `
      <article class="card section-card" id="${esc(group.id)}">
        <h2>${esc(local(group))}</h2>
        <div class="function-list compact-functions">
          ${group.functions.map((item) => {
            const signature = typeof item === "string" ? item : item.signature;
            const name = typeof item === "string" ? signature.split("(")[0] : item.name;
            const desc = typeof item === "string" ? "" : local(item);
            return `
              <div class="function-item">
                <h2 id="${esc(name)}">${esc(name)}</h2>
                <p class="function-sig"><code>${esc(signature)}</code></p>
                ${desc ? `<p class="function-desc">${esc(desc)}</p>` : ""}
                ${paramList(item)}
              </div>
            `;
          }).join("")}
        </div>
      </article>
    `).join("");
  }

  function modifierCards(items) {
    if (!Array.isArray(items) || !items.length) return "";
    return `
      <article class="card section-card">
        <h2>${esc(ui.modifiers || "Modifiers")}</h2>
        <div class="modifier-grid">
          ${items.map((item) => `
            <div class="modifier-card">
              <h3>${esc(item.name)}</h3>
              <p>${esc(local(item))}</p>
              <strong class="modifier-subtitle">${esc(ui.submodifiers || "Submodifiers / aliases")}</strong>
              <div class="chip-row">
                ${(item.aliases || []).map((alias) => `<span class="chip">${esc(alias)}</span>`).join("")}
              </div>
              ${modifierVideo(item)}
            </div>
          `).join("")}
        </div>
      </article>
    `;
  }

  function modifierVideo(item) {
    if (!item.video) {
      return `
        <div class="inline-note">
          <strong>${esc(ui.videoPending || "Video pending")}</strong>
        </div>
      `;
    }

    const src = new URL(item.video, videoBase).href;
    return `
      <div class="modifier-video">
        <video src="${esc(src)}" controls muted playsinline preload="metadata"></video>
        ${item.videoNote ? `<p>${esc(local(item.videoNote))}</p>` : ""}
        <a class="text-link" href="${esc(src)}">${esc(ui.openReference || "Open reference")}</a>
      </div>
    `;
  }

  function variableGroups(groups) {
    if (!Array.isArray(groups) || !groups.length) return "";
    return groups.map((group) => `
      <article class="card section-card">
        <h2>${esc(local(group))}</h2>
        <div class="chip-row">
          ${group.items.map((name) => `<span class="chip">${esc(name)}</span>`).join("")}
        </div>
      </article>
    `).join("");
  }

  function renderPage() {
    const content = document.getElementById("pageContent");
    const page = api.pages[pageId];
    if (!content) return;

    if (!page) {
      document.title = `Plus Engine - ${ui.pageNotFound || "Page not found"}`;
      content.innerHTML = `
        <article class="card section-card page-route-hero">
          <p class="eyebrow">Plus Engine</p>
          <h1>${esc(ui.pageNotFound || "Page not found")}</h1>
          <p>${esc(ui.pageNotFoundBody || "")}</p>
        </article>
      `;
      return;
    }

    const title = page[lang]?.title || page.en?.title || pageId;
    document.title = `Plus Engine - ${title}`;

    content.innerHTML = `
      ${hero(page)}
      <section class="page-route-content">
        ${functionList(page.functions)}
        ${variableList(page.variables)}
        ${pageId === "modchart" ? modchartGroups(page.groups) : ""}
        ${modifierCards(page.items)}
        ${pageId === "variables" ? variableGroups(page.groups) : ""}
      </section>
    `;
  }

  renderTopbar();
  renderShell();
  renderNav();
  renderPage();
  document.getElementById("pageSearch")?.addEventListener("input", renderNav);
})();
