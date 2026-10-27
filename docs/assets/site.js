(function () {
  const root = document.documentElement;
  const key = "plus-engine-theme";
  const spanish = root.lang === "es";
  const scriptUrl = document.currentScript?.src || location.href;
  const siteRoot = new URL("../", scriptUrl);

  function systemTheme() {
    return matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function savedTheme() {
    try { return localStorage.getItem(key) || "auto"; }
    catch (_) { return "auto"; }
  }

  function applyTheme(value) {
    root.dataset.theme = value === "auto" ? systemTheme() : value;
    const button = document.getElementById("themeToggle");
    if (!button) return;
    const labels = spanish
      ? { auto: "Tema: auto", dark: "Tema: oscuro", light: "Tema: claro" }
      : { auto: "Theme: auto", dark: "Theme: dark", light: "Theme: light" };
    button.textContent = labels[value];
    button.dataset.mode = value;
    button.title = spanish ? "Cambiar tema" : "Change theme";
  }

  function cycleTheme() {
    const current = savedTheme();
    const next = current === "auto" ? "dark" : current === "dark" ? "light" : "auto";
    try { localStorage.setItem(key, next); } catch (_) {}
    applyTheme(next);
  }

  function cleanIndexUrl() {
    const { pathname, search, hash } = location;
    if (pathname.endsWith("/index.html")) {
      history.replaceState({}, "", `${pathname.slice(0, -10)}${search}${hash}`);
    }
  }

  function buildMobileNavigation() {
    const sidebar = document.querySelector(".psych-sidebar, .docs-layout > .sidebar");
    const actions = document.querySelector(".top-actions");
    if (!sidebar || !actions) return;

    const toggle = document.createElement("button");
    toggle.className = "menu-toggle";
    toggle.type = "button";
    toggle.textContent = spanish ? "Menú" : "Menu";
    toggle.setAttribute("aria-controls", sidebar.id || "docsNavigation");
    toggle.setAttribute("aria-expanded", "false");
    if (!sidebar.id) sidebar.id = "docsNavigation";

    const scrim = document.createElement("button");
    scrim.className = "nav-scrim";
    scrim.type = "button";
    scrim.tabIndex = -1;
    scrim.setAttribute("aria-label", spanish ? "Cerrar menú" : "Close menu");
    document.body.append(scrim);
    actions.prepend(toggle);

    const close = () => {
      document.body.classList.remove("nav-open");
      toggle.setAttribute("aria-expanded", "false");
    };
    toggle.addEventListener("click", () => {
      const open = document.body.classList.toggle("nav-open");
      toggle.setAttribute("aria-expanded", String(open));
    });
    scrim.addEventListener("click", close);
    sidebar.addEventListener("click", (event) => {
      if (event.target.closest("a")) close();
    });
    addEventListener("keydown", (event) => { if (event.key === "Escape") close(); });
    matchMedia("(min-width: 981px)").addEventListener("change", close);
  }

  function addCommunityLink() {
    const actions = document.querySelector(".top-actions");
    const theme = document.getElementById("themeToggle");
    if (!actions || actions.querySelector("[data-community-link]")) return;
    const link = document.createElement("a");
    link.className = "text-link";
    link.dataset.communityLink = "true";
    link.textContent = spanish ? "Porters" : "Community ports";
    link.href = new URL(spanish ? "es/community/" : "community/", siteRoot).href;
    actions.insertBefore(link, theme);
  }

  function addVisitorCounter() {
    if (document.querySelector(".site-counter")) return;
    const footer = document.createElement("footer");
    footer.className = "site-counter";
    footer.setAttribute("aria-label", spanish ? "Contador de visitas" : "Visitor counter");
    const image = document.createElement("img");
    image.src = "https://count.getloli.com/@psych-plus-page?theme=booru-lisu&padding=7&offset=0&align=top&scale=1&pixelated=1&darkmode=auto&prefix=0";
    image.alt = spanish ? "Contador de visitas de la documentación" : "Documentation visitor counter";
    image.loading = "lazy";
    footer.append(image);
    document.body.append(footer);
  }

  applyTheme(savedTheme());
  cleanIndexUrl();
  addCommunityLink();
  buildMobileNavigation();
  addVisitorCounter();
  document.getElementById("themeToggle")?.addEventListener("click", cycleTheme);
  matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
    if (savedTheme() === "auto") applyTheme("auto");
  });
})();
