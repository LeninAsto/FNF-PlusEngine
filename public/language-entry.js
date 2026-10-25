(function () {
  if (window.location.pathname !== '/') return;

  const storageKey = 'plus-docs-locale';
  const saved = localStorage.getItem(storageKey);
  if (saved === 'en') return;
  if (saved === 'es-LA') {
    window.location.replace(`/es-LA/${window.location.search}${window.location.hash}`);
    return;
  }

  const preferences = navigator.languages?.length ? navigator.languages : [navigator.language];
  const useSpanish = preferences.some((tag) => tag.toLowerCase().startsWith('es'));
  if (useSpanish) window.location.replace(`/es-LA/${window.location.search}${window.location.hash}`);
})();
