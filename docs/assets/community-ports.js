(async function () {
  const container = document.getElementById("portsGrid");
  const porterFilter = document.getElementById("porterFilter");
  const sortFilter = document.getElementById("videoSort");
  const status = document.getElementById("portsStatus");
  const loadMore = document.getElementById("loadMorePorts");
  const hero = {
    root: document.getElementById("communityHero"),
    image: document.getElementById("communityHeroImage"),
    eyebrow: document.getElementById("communityHeroEyebrow"),
    title: document.getElementById("communityHeroTitle"),
    description: document.getElementById("communityHeroDescription"),
    link: document.getElementById("communityHeroLink")
  };
  if (!container) return;

  const spanish = document.documentElement.lang === "es";
  const locale = spanish ? "es" : "en";
  const dataUrl = new URL("../data/ports.json", document.currentScript.src);
  const siteRoot = new URL("../", dataUrl);
  const pageSize = 10;
  let visibleCount = pageSize;

  const heroDefault = {
    image: hero.image?.src || "",
    eyebrow: hero.eyebrow?.textContent || "",
    title: hero.title?.textContent || "",
    description: hero.description?.textContent || ""
  };

  function escapeHtml(value) {
    return String(value ?? "").replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#39;");
  }

  function formatViews(value) {
    return new Intl.NumberFormat(locale, { notation: "compact", maximumFractionDigits: 1 }).format(Number(value) || 0);
  }

  function formatDate(value) {
    if (!value) return "";
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return "";
    return new Intl.DateTimeFormat(locale, { dateStyle: "medium" }).format(date);
  }

  function videoCard(video, porter) {
    const title = escapeHtml(video.title);
    const watchUrl = "https://www.youtube.com/watch?v=" + encodeURIComponent(video.id);
    const date = formatDate(video.publishedAt);
    return [
      '<article class="community-video-card">',
      '<button class="video-poster" type="button" data-video-id="' + escapeHtml(video.id) + '" data-video-title="' + title + '" aria-label="' + (spanish ? "Reproducir" : "Play") + ": " + title + '">',
      '<img src="https://i.ytimg.com/vi/' + encodeURIComponent(video.id) + '/hqdefault.jpg" alt="" loading="lazy" />',
      '<span class="video-play" aria-hidden="true">▶</span></button>',
      '<div class="community-video-copy"><h2>' + title + "</h2>",
      '<p class="video-stats">' + formatViews(video.views) + " " + (spanish ? "visualizaciones" : "views") + (date ? " · " + escapeHtml(date) : "") + "</p>",
      '<a class="video-watch-link" href="' + watchUrl + '" target="_blank" rel="noreferrer">' + (spanish ? "Ver en YouTube" : "Watch on YouTube") + " →</a>",
      "</div></article>"
    ].join("");
  }

  function activatePlayers() {
    container.querySelectorAll(".video-poster").forEach((button) => {
      button.addEventListener("click", () => {
        const iframe = document.createElement("iframe");
        iframe.src = "https://www.youtube-nocookie.com/embed/" + encodeURIComponent(button.dataset.videoId) + "?autoplay=1";
        iframe.title = button.dataset.videoTitle;
        iframe.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share";
        iframe.allowFullscreen = true;
        iframe.referrerPolicy = "strict-origin-when-cross-origin";
        button.replaceWith(iframe);
      }, { once: true });
    });
  }

  function updateHero(porter) {
    if (!hero.root) return;
    if (!porter) {
      hero.root.classList.remove("is-porter");
      if (hero.image) {
        hero.image.src = heroDefault.image;
        hero.image.alt = "Psych Engine";
      }
      if (hero.eyebrow) hero.eyebrow.textContent = heroDefault.eyebrow;
      if (hero.title) hero.title.textContent = heroDefault.title;
      if (hero.description) hero.description.textContent = heroDefault.description;
      if (hero.link) hero.link.hidden = true;
      return;
    }

    hero.root.classList.add("is-porter");
    if (hero.image) {
      hero.image.src = new URL(porter.avatar, siteRoot).href;
      hero.image.alt = porter.name;
    }
    if (hero.eyebrow) hero.eyebrow.textContent = spanish ? "Porter seleccionado" : "Selected porter";
    if (hero.title) hero.title.textContent = porter.name;
    if (hero.description) hero.description.textContent = porter.description;
    if (hero.link) {
      hero.link.href = porter.url;
      hero.link.textContent = (spanish ? "Abrir canal" : "Open channel") + " →";
      hero.link.hidden = false;
    }
  }

  try {
    const response = await fetch(dataUrl, { cache: "no-cache" });
    if (!response.ok) throw new Error("HTTP " + response.status);
    const data = await response.json();
    const porters = Array.isArray(data.porters) ? data.porters : [];
    const porterMap = new Map(porters.map((porter) => [porter.id, porter]));
    const videos = Array.isArray(data.videos) ? data.videos : [];

    porters.forEach((porter) => {
      const option = document.createElement("option");
      option.value = porter.id;
      option.textContent = porter.name;
      porterFilter?.append(option);
    });

    function selectedVideos() {
      const selected = porterFilter?.value || "";
      const filtered = selected ? videos.filter((video) => video.porter === selected) : [...videos];
      const sort = sortFilter?.value || "recent";
      filtered.sort((left, right) => {
        if (sort === "popular") return (right.views || 0) - (left.views || 0);
        const leftDate = left.publishedAt ? new Date(left.publishedAt).getTime() : 0;
        const rightDate = right.publishedAt ? new Date(right.publishedAt).getTime() : 0;
        if (leftDate !== rightDate) return rightDate - leftDate;
        return (left.recentRank || 0) - (right.recentRank || 0);
      });
      return filtered;
    }

    function render() {
      const selected = porterFilter?.value || "";
      const porter = porterMap.get(selected);
      const filtered = selectedVideos();
      const visible = filtered.slice(0, visibleCount);

      updateHero(porter);
      container.innerHTML = visible.map((video) => videoCard(video, porterMap.get(video.porter))).join("");
      if (status) status.textContent = spanish
        ? visible.length + " de " + filtered.length + " videos"
        : visible.length + " of " + filtered.length + " videos";
      if (loadMore) {
        loadMore.hidden = visible.length >= filtered.length;
        const remaining = Math.min(pageSize, filtered.length - visible.length);
        loadMore.textContent = spanish ? "Cargar " + remaining + " más" : "Load " + remaining + " more";
      }
      activatePlayers();
    }

    function resetAndRender() {
      visibleCount = pageSize;
      render();
    }

    porterFilter?.addEventListener("change", resetAndRender);
    sortFilter?.addEventListener("change", resetAndRender);
    loadMore?.addEventListener("click", () => {
      visibleCount += pageSize;
      render();
      loadMore?.focus();
    });
    render();
  } catch (error) {
    console.error("Could not load community ports", error);
    container.innerHTML = '<div class="inline-note">' + (spanish ? "No se pudo cargar el catálogo." : "The catalog could not be loaded.") + "</div>";
  }
})();
