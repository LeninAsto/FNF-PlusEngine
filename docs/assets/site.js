(function () {
  const root = document.documentElement;
  const storageKey = "lua-api-theme";

  function stripIndexHtml() {
    const { pathname, search, hash } = window.location;
    if (!pathname.endsWith("/index.html")) {
      return;
    }

    const cleanPath = pathname.slice(0, -"index.html".length);
    window.history.replaceState({}, "", `${cleanPath}${search}${hash}`);
  }

  function getSystemTheme() {
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  }

  function applyTheme(theme) {
    if (theme === "auto") {
      root.setAttribute("data-theme", getSystemTheme());
      return;
    }
    root.setAttribute("data-theme", theme);
  }

  function cycleTheme() {
    const current = localStorage.getItem(storageKey) || "auto";
    const next = current === "auto" ? "dark" : current === "dark" ? "light" : "auto";
    localStorage.setItem(storageKey, next);
    applyTheme(next);
    refreshThemeToggle(next);
  }

  function refreshThemeToggle(theme) {
    const toggle = document.getElementById("themeToggle");
    if (!toggle) {
      return;
    }

    const label = theme === "auto" ? "Theme: Auto" : theme === "dark" ? "Theme: Dark" : "Theme: Light";
    toggle.textContent = label;
    toggle.setAttribute("aria-label", `Current theme ${theme}`);
    toggle.setAttribute("aria-pressed", theme === "dark" ? "true" : "false");
  }

  async function updateVisitCounter() {
    const counter = document.querySelector("[data-visit-counter]");
    if (!counter) {
      return;
    }

    const pageKey = window.location.pathname
      .replace(/[^a-z0-9]+/gi, "-")
      .replace(/^-+|-+$/g, "")
      .toLowerCase() || "home";
    const namespace = "plus-engine-docs";
    const remoteUrl = `https://api.countapi.xyz/hit/${namespace}/${pageKey}`;

    try {
      const response = await fetch(remoteUrl, { cache: "no-store" });
      if (!response.ok) {
        throw new Error("counter request failed");
      }

      const data = await response.json();
      if (data && typeof data.value === "number") {
        counter.textContent = String(data.value);
        counter.dataset.counterSource = "remote";
        return;
      }
      throw new Error("counter response missing value");
    } catch (error) {
      const localKey = `${namespace}:${pageKey}`;
      const nextValue = Number(localStorage.getItem(localKey) || "0") + 1;
      localStorage.setItem(localKey, String(nextValue));
      counter.textContent = String(nextValue);
      counter.dataset.counterSource = "local";
    }
  }

  async function updateCloudflareUser() {
    const actions = document.querySelector(".top-actions");
    if (!actions) {
      return;
    }

    const badge = document.createElement("span");
    badge.className = "user-pill";
    badge.textContent = "Local";
    badge.title = "Cloudflare Access identity is not available in local/static preview.";
    actions.insertBefore(badge, actions.firstChild);

    try {
      const response = await fetch("/api/me", { cache: "no-store" });
      if (!response.ok) {
        return;
      }

      const user = await response.json();
      if (user && user.authenticated) {
        badge.textContent = user.email || user.id || "Cloudflare user";
        badge.title = "Verified by Cloudflare Access";
        badge.dataset.verified = "true";
      }
    } catch (error) {
      badge.dataset.offline = "true";
    }
  }

  const savedTheme = localStorage.getItem(storageKey) || "auto";
  applyTheme(savedTheme);
  stripIndexHtml();
  refreshThemeToggle(savedTheme);
  updateVisitCounter();
  updateCloudflareUser();

  const toggle = document.getElementById("themeToggle");
  if (toggle) {
    toggle.addEventListener("click", cycleTheme);
  }

  window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
    const current = localStorage.getItem(storageKey) || "auto";
    if (current === "auto") {
      applyTheme("auto");
    }
  });
})();
