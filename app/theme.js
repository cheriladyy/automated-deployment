// Dark mode. <head> içinde yüklenir ki tema sayfa çizilmeden önce ayarlansın
// (yoksa koyu temada sayfa önce beyaz görünüp sonra kararır).
// Seçim localStorage'da "theme" anahtarıyla saklanır; seçim yoksa sistem ayarı kullanılır.
(function () {
  var STORAGE_KEY = "theme";
  var systemDark = window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)") : null;

  function storedTheme() {
    try {
      var value = localStorage.getItem(STORAGE_KEY);
      return value === "dark" || value === "light" ? value : null;
    } catch (error) {
      return null; // localStorage kapalı olabilir (ör. gizli sekme)
    }
  }

  function systemTheme() {
    return systemDark && systemDark.matches ? "dark" : "light";
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
  }

  applyTheme(storedTheme() || systemTheme());

  // Kullanıcı elle seçim yapmadıysa sistem teması değişince sayfa da değişsin.
  if (systemDark && systemDark.addEventListener) {
    systemDark.addEventListener("change", function () {
      if (!storedTheme()) applyTheme(systemTheme());
    });
  }

  window.toggleTheme = function () {
    var next = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
    applyTheme(next);
    try {
      localStorage.setItem(STORAGE_KEY, next);
    } catch (error) {
      // Saklanamazsa tema yalnızca bu sayfa için geçerli olur.
    }
  };
})();
