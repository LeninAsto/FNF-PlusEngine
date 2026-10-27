(async function () {
  const container = document.getElementById("portsGrid");
  const filter = document.getElementById("porterFilter");
  const status = document.getElementById("portsStatus");
  if (!container) return;

  const spanish = document.documentElement.lang === "es";
  const dataUrl = new URL("../data/ports.json", document.currentScript.src);

  function escapeHtml(value) {
    return String(value ?? "").replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#39;");
  }

  try {
    const response = await fetch(dataUrl, { cache: "no-cache" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    const data = await response.json();
    const videos = Array.isArray(data.videos) ? data.videos : [];
    const porters = [...new Set(videos.map((video) => video.porter))].sort();

    for (const porter of porters) {
      const option = document.createElement("option");
      option.value = porter;
      option.textContent = porter;
      filter?.append(option);
    }

    function render() {
      const selected = filter?.value || "";
      const visible = selected ? videos.filter((video) => video.porter === selected) : videos;
      container.innerHTML = visible.map((video) => `
        <article class="card port-card">
          <div class="port-video">
            <iframe src="https://www.youtube-nocookie.com/embed/${encodeURIComponent(video.id)}" title="${escapeHtml(video.title)}" loading="lazy" referrerpolicy="strict-origin-when-cross-origin" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>
          </div>
          <div class="port-card-body">
            <h2>${escapeHtml(video.title)}</h2>
            <p><a href="${escapeHtml(video.porterUrl)}" target="_blank" rel="noreferrer">${escapeHtml(video.porter)}</a> · ${escapeHtml(video.engine)}</p>
            <div class="chip-row">${(video.platforms || []).map((platform) => `<span class="chip">${escapeHtml(platform)}</span>`).join("")}</div>
            ${video.verifiedPlus ? "" : `<p class="compatibility-state">${spanish ? "Compatibilidad con Plus Engine no verificada." : "Plus Engine compatibility has not been verified."}</p>`}
            <a class="reference-link" href="${escapeHtml(video.url)}" target="_blank" rel="noreferrer">${spanish ? "Abrir en YouTube" : "Open on YouTube"} →</a>
          </div>
        </article>
      `).join("");
      if (status) status.textContent = spanish ? `${visible.length} videos mostrados` : `${visible.length} videos shown`;
    }

    filter?.addEventListener("change", render);
    render();
  } catch (error) {
    console.error("Could not load community ports", error);
    container.innerHTML = `<div class="inline-note">${spanish ? "No se pudieron cargar los videos." : "The videos could not be loaded."}</div>`;
  }
})();
