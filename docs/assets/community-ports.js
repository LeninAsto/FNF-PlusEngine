(async function () {
  const container = document.getElementById("portsGrid");
  const filter = document.getElementById("porterFilter");
  const status = document.getElementById("portsStatus");
  if (!container) return;

  const spanish = document.documentElement.lang === "es";
  const dataUrl = new URL("../data/ports.json", document.currentScript.src);
  const siteRoot = new URL("../", dataUrl);

  function escapeHtml(value) {
    return String(value ?? "").replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#39;");
  }

  function videoCard(video) {
    const title = escapeHtml(video.title);
    const watchUrl = `https://www.youtube.com/watch?v=${encodeURIComponent(video.id)}`;
    return `<article class="community-video-card">
      <button class="video-poster" type="button" data-video-id="${escapeHtml(video.id)}" data-video-title="${title}" aria-label="${spanish ? "Reproducir" : "Play"}: ${title}">
        <img src="https://i.ytimg.com/vi/${encodeURIComponent(video.id)}/hqdefault.jpg" alt="" loading="lazy" />
        <span class="video-play" aria-hidden="true">▶</span>
      </button>
      <div class="community-video-copy"><h3>${title}</h3><a href="${watchUrl}" target="_blank" rel="noreferrer">${spanish ? "Ver en YouTube" : "Watch on YouTube"} →</a></div>
    </article>`;
  }

  function porterCard(porter, videos) {
    const avatar = new URL(porter.avatar, siteRoot).href;
    return `<article class="card porter-profile" id="porter-${escapeHtml(porter.id)}">
      <header class="porter-banner">
        <img class="porter-avatar" src="${escapeHtml(avatar)}" alt="${escapeHtml(porter.name)}" loading="lazy" />
        <div class="porter-summary"><p class="eyebrow">YouTube porter</p><h2>${escapeHtml(porter.name)}</h2><a class="porter-handle" href="${escapeHtml(porter.url)}" target="_blank" rel="noreferrer">${escapeHtml(porter.handle)}</a><p>${escapeHtml(porter.description)}</p></div>
        <a class="youtube-channel-link" href="${escapeHtml(porter.url)}" target="_blank" rel="noreferrer"><span aria-hidden="true">▶</span> ${spanish ? "Abrir canal" : "Open channel"}</a>
      </header>
      <div class="porter-videos">${videos.map(videoCard).join("")}</div>
    </article>`;
  }

  function activatePlayers() {
    container.querySelectorAll(".video-poster").forEach((button) => {
      button.addEventListener("click", () => {
        const iframe = document.createElement("iframe");
        iframe.src = `https://www.youtube-nocookie.com/embed/${encodeURIComponent(button.dataset.videoId)}?autoplay=1`;
        iframe.title = button.dataset.videoTitle;
        iframe.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share";
        iframe.allowFullscreen = true;
        iframe.referrerPolicy = "strict-origin-when-cross-origin";
        button.replaceWith(iframe);
      }, { once: true });
    });
  }

  try {
    const response = await fetch(dataUrl, { cache: "no-cache" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    const porters = Array.isArray(data.porters) ? data.porters : [];
    const videos = Array.isArray(data.videos) ? data.videos : [];

    porters.forEach((porter) => {
      const option = document.createElement("option");
      option.value = porter.id;
      option.textContent = porter.name;
      filter?.append(option);
    });

    function render() {
      const selected = filter?.value || "";
      const visible = selected ? porters.filter((porter) => porter.id === selected) : porters;
      container.innerHTML = visible.map((porter) => porterCard(porter, videos.filter((video) => video.porter === porter.id))).join("");
      const visibleVideos = videos.filter((video) => visible.some((porter) => porter.id === video.porter)).length;
      if (status) status.textContent = `${visible.length} porters · ${visibleVideos} videos`;
      activatePlayers();
    }

    filter?.addEventListener("change", render);
    render();
  } catch (error) {
    console.error("Could not load community ports", error);
    container.innerHTML = `<div class="inline-note">${spanish ? "No se pudieron cargar los perfiles." : "The profiles could not be loaded."}</div>`;
  }
})();
