(async function () {
  const categories = Array.isArray(window.psychCategories) ? window.psychCategories : [];
  const lang = document.body?.dataset?.lang === "es" ? "es" : "en";
  const pageId = document.body?.dataset?.page || "playstate";
  const dataBase = new URL("../data/", document.currentScript.src);

  const fallbackUi = {
    lang,
    languageSwitchLabel: lang === "es" ? "English" : "Español",
    home: lang === "es" ? "Inicio" : "Home",
    plus: "Plus",
    theme: lang === "es" ? "Tema" : "Theme",
    psychPages: lang === "es" ? "Páginas Psych" : "Psych Pages",
    chooseSection: lang === "es" ? "Elige una sección" : "Choose a section",
    navLead: "",
    searchPages: lang === "es" ? "Buscar páginas" : "Search pages",
    searchPlaceholder: "PlayState, variables, snippets...",
    overview: lang === "es" ? "Resumen" : "Overview",
    functions: lang === "es" ? "Funciones" : "Functions",
    functionCount: lang === "es" ? "funciones" : "functions",
    folderRoute: lang === "es" ? "Ruta por carpeta" : "Folder route",
    sourcePreset: "JSON preset",
    videoExamples: lang === "es" ? "Videos de ejemplo" : "Video examples",
    videoIntro: "",
    examples: lang === "es" ? "Ejemplos" : "Examples",
    optional: lang === "es" ? "Opcional" : "Optional",
    pageNotFound: lang === "es" ? "Página no encontrada" : "Page not found",
    pageNotFoundBody: "",
    noSearchResults: lang === "es" ? "Ninguna página coincide con esa búsqueda." : "No pages matched that search.",
    variablesTitle: "Variables",
    variablesSummary: "",
    variablesIntro: "",
    snippetsTitle: lang === "es" ? "Fragmentos de código" : "Code Snippets",
    snippetsSummary: "",
    snippetsIntro: "",
    openReference: lang === "es" ? "Abrir referencia" : "Open reference",
    routeNoteCategory: "",
    routeNoteSpecial: ""
  };

  function esc(value) {
    return String(value ?? "")
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;");
  }

  function text(value, fallback = "") {
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
      console.warn(`[docs] Could not load ${name}`, error);
      return fallback;
    }
  }

  const [uiPreset, pagePreset, specialPreset] = await Promise.all([
    readJson(`ui.${lang}.json`, fallbackUi),
    readJson("psych-pages.json", { order: [], categories: {} }),
    readJson("special-pages.json", {})
  ]);

  const ui = { ...fallbackUi, ...uiPreset };

  function categoryMeta(id, category) {
    const meta = pagePreset.categories?.[id]?.[lang] || pagePreset.categories?.[id]?.en || {};
    return {
      title: meta.title || category?.title || id,
      summary: meta.summary || category?.description || ""
    };
  }

  function routeFor(id) {
    return `../${id}/`;
  }

  function languageRoute(id) {
    return lang === "es" ? `../../../pages/${id}/` : `../../../es/pages/${id}/`;
  }

  function allPages() {
    const ids = pagePreset.order?.length
      ? pagePreset.order
      : [...categories.map((item) => item.id), "variables", "snippets"];

    return ids.map((id) => {
      const category = categories.find((item) => item.id === id);
      if (category) {
        const meta = categoryMeta(id, category);
        return { id, ...meta, route: routeFor(id), kind: "category" };
      }

      if (id === "variables") {
        return { id, title: ui.variablesTitle, summary: ui.variablesSummary, route: routeFor(id), kind: "special" };
      }

      if (id === "snippets") {
        return { id, title: ui.snippetsTitle, summary: ui.snippetsSummary, route: routeFor(id), kind: "special" };
      }

      return null;
    }).filter(Boolean);
  }

  function renderTopbarText() {
    const homeLink = document.querySelector('.top-actions a[href$="index.html"]:not(.lang-switch)');
    const plusLink = document.querySelector('.top-actions a[href*="/plus/"]');
    const themeButton = document.getElementById("themeToggle");

    if (homeLink) homeLink.textContent = ui.home;
    if (plusLink) plusLink.textContent = ui.plus;
    if (themeButton && !themeButton.dataset.readyLabel) {
      themeButton.dataset.readyLabel = "true";
      if (themeButton.textContent.trim().toLowerCase() === "theme") {
        themeButton.textContent = ui.theme;
      }
    }
  }

  function renderShellText() {
    const sidebar = document.querySelector(".psych-sidebar");
    if (!sidebar) return;

    const eyebrow = sidebar.querySelector(".eyebrow");
    const title = sidebar.querySelector("h2");
    const copy = sidebar.querySelector(".sidebar-copy");
    const label = sidebar.querySelector("label[for='pageSearch']");
    const search = document.getElementById("pageSearch");

    if (eyebrow) eyebrow.textContent = ui.psychPages;
    if (title) title.textContent = ui.chooseSection;
    if (copy) copy.textContent = ui.navLead;
    if (label) label.textContent = ui.searchPages;
    if (search) search.placeholder = ui.searchPlaceholder;
  }

  function renderLanguageSwitch() {
    const actions = document.querySelector(".top-actions");
    if (!actions || actions.querySelector(".lang-switch")) return;

    const link = document.createElement("a");
    link.className = "text-link lang-switch";
    link.textContent = ui.languageSwitchLabel;
    link.href = languageRoute(pageId);
    actions.insertBefore(link, document.getElementById("themeToggle"));
  }

  function renderNav() {
    const nav = document.getElementById("pageNav");
    if (!nav) return;

    const query = document.getElementById("pageSearch")?.value.toLowerCase().trim() || "";
    const pages = allPages().filter((item) => {
      if (!query) return true;
      return `${item.title} ${item.summary} ${item.id}`.toLowerCase().includes(query);
    });

    if (!pages.length) {
      nav.innerHTML = `<div class="inline-note">${esc(ui.noSearchResults)}</div>`;
      return;
    }

    nav.innerHTML = pages.map((item) => `
      <a class="${item.id === pageId ? "is-active" : ""}" href="${esc(item.route)}">
        ${esc(item.title)}
        <small>${esc(item.summary)}</small>
      </a>
    `).join("");
  }

  function renderFunctionVideos(fn) {
    if (!Array.isArray(fn.videos) || !fn.videos.length) return "";

    const items = fn.videos.map((video) => {
      if (typeof video === "string") {
        return `<li><video controls src="${esc(video)}"></video></li>`;
      }

      return `
        <li>
          <p>${esc(video.title || video.label || "")}</p>
          <video controls src="${esc(video.src || video.url || "")}"></video>
        </li>
      `;
    }).join("");

    return `
      <details class="function-videos">
        <summary>${esc(ui.videoExamples)}</summary>
        <div class="inline-note">${esc(ui.videoIntro)}</div>
        <ul class="video-list">${items}</ul>
      </details>
    `;
  }

  function renderParameters(fn) {
    if (!Array.isArray(fn.parameters) || !fn.parameters.length) return "";

    return `
      <ul class="function-params">
        ${fn.parameters.map((param) => `
          <li>
            <strong>${esc(param.name)}</strong>${param.optional ? ` (${esc(ui.optional)})` : ""} - <em>${esc(param.type)}</em><br />
            ${esc(param.description)}
          </li>
        `).join("")}
      </ul>
    `;
  }

  function renderExamples(fn) {
    if (!Array.isArray(fn.examples) || !fn.examples.length) return "";

    return `
      <div class="function-examples">
        <strong>${esc(ui.examples)}:</strong>
        ${fn.examples.map((example) => {
          if (typeof example === "string") {
            return `<div class="example-item"><code>${esc(example)}</code></div>`;
          }

          return `
            <div class="example-item">
              <code>${esc(example.code || example)}</code>
              ${example.description ? `<p>${esc(example.description)}</p>` : ""}
            </div>
          `;
        }).join("")}
      </div>
    `;
  }

  function renderFunctionCard(fn) {
    return `
      <div class="function-item">
        <h2 id="${esc(fn.name)}">${esc(fn.name)}</h2>
        <p class="function-sig"><code>${esc(fn.signature)}</code></p>
        <p class="function-desc">${esc(fn.description || "")}</p>
        ${renderParameters(fn)}
        ${renderExamples(fn)}
        ${renderFunctionVideos(fn)}
      </div>
    `;
  }

  function renderCategoryPage(category) {
    const meta = categoryMeta(category.id, category);
    document.title = `Psych Engine - ${meta.title}`;

    return `
      <article class="card section-card page-route-hero" id="page-top">
        <p class="eyebrow">Psych Engine</p>
        <h1>${esc(meta.title)}</h1>
        <p>${esc(meta.summary)}</p>
        <div class="page-route-meta">
          <span class="chip">${category.functions.length} ${esc(ui.functionCount)}</span>
          <span class="chip">${esc(ui.folderRoute)}</span>
          <span class="chip">${esc(ui.sourcePreset)}</span>
        </div>
      </article>

      <section class="page-route-content">
        <article class="card section-card">
          <h2>${esc(ui.overview)}</h2>
          <p>${esc(ui.routeNoteCategory)}</p>
        </article>

        <article class="card section-card">
          <h2>${esc(ui.functions)}</h2>
          <div class="function-list">
            ${category.functions.map(renderFunctionCard).join("")}
          </div>
        </article>
      </section>
    `;
  }

  function renderVariablesPage() {
    const page = specialPreset.variables || { sections: [] };
    document.title = `Psych Engine - ${ui.variablesTitle}`;

    return `
      <article class="card section-card page-route-hero">
        <p class="eyebrow">Psych Engine</p>
        <h1>${esc(ui.variablesTitle)}</h1>
        <p>${esc(ui.variablesIntro)}</p>
        <div class="page-route-meta">
          <span class="chip">${page.sections.length} ${esc(ui.overview)}</span>
          <span class="chip">${esc(ui.sourcePreset)}</span>
        </div>
      </article>

      <section class="page-route-content">
        <article class="card section-card">
          <h2>${esc(ui.overview)}</h2>
          <p>${esc(ui.routeNoteSpecial)}</p>
        </article>
        ${page.sections.map((section) => `
          <article class="card section-card">
            <h2>${esc(text(section.title))}</h2>
            <ul class="psych-list">
              ${section.items.map((item) => `
                <li><span class="code-pill">${esc(item.name)}</span> - ${esc(text(item.description))}</li>
              `).join("")}
            </ul>
          </article>
        `).join("")}
      </section>
    `;
  }

  function renderSnippetsPage() {
    const page = specialPreset.snippets || { groups: [] };
    document.title = `Psych Engine - ${ui.snippetsTitle}`;

    return `
      <article class="card section-card page-route-hero">
        <p class="eyebrow">Psych Engine</p>
        <h1>${esc(ui.snippetsTitle)}</h1>
        <p>${esc(ui.snippetsIntro)}</p>
        <div class="page-route-meta">
          <span class="chip">${page.groups.length} ${esc(ui.overview)}</span>
          <span class="chip">${esc(ui.sourcePreset)}</span>
        </div>
      </article>

      <section class="page-route-content">
        <article class="card section-card">
          <h2>${esc(ui.overview)}</h2>
          <p>${esc(ui.routeNoteSpecial)}</p>
        </article>
        ${page.groups.map((group) => `
          <article class="card section-card">
            <h2>${esc(text(group.title))}</h2>
            <div class="page-links">
              ${group.links.map((link) => `
                <a href="${esc(link.href)}" target="_blank" rel="noreferrer">
                  ${esc(text(link.label))}
                  <small>${esc(ui.openReference)}</small>
                </a>
              `).join("")}
            </div>
          </article>
        `).join("")}
      </section>
    `;
  }

  function renderNotFound() {
    document.title = `Psych Engine - ${ui.pageNotFound}`;
    return `
      <article class="card section-card page-route-hero">
        <p class="eyebrow">Psych Engine</p>
        <h1>${esc(ui.pageNotFound)}</h1>
        <p>${esc(ui.pageNotFoundBody)}</p>
      </article>
    `;
  }

  function renderPage() {
    const content = document.getElementById("pageContent");
    if (!content) return;

    const category = categories.find((item) => item.id === pageId);

    if (category) {
      content.innerHTML = renderCategoryPage(category);
    } else if (pageId === "variables") {
      content.innerHTML = renderVariablesPage();
    } else if (pageId === "snippets") {
      content.innerHTML = renderSnippetsPage();
    } else {
      content.innerHTML = renderNotFound();
    }
  }

  renderTopbarText();
  renderShellText();
  renderLanguageSwitch();
  renderNav();
  renderPage();

  document.getElementById("pageSearch")?.addEventListener("input", renderNav);
})();
