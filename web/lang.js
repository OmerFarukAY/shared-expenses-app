/**
 * Denk Legal & Web Portal — Multi-Language Engine (EN, TR, ES, FR, IT)
 * Bulletproof DOM switching with inline display controls and zero style-cache reliance.
 */
const I18N_NAV = {
  en: { privacy: "Privacy Policy", terms: "Terms of Service", delete: "Delete Account", copy: "© 2026 Denk • Developer: Ömer Faruk Ay" },
  tr: { privacy: "Gizlilik Politikası", terms: "Kullanım Koşulları", delete: "Hesap Silme", copy: "© 2026 Denk • Geliştirici: Ömer Faruk Ay" },
  es: { privacy: "Política de Privacidad", terms: "Términos de Servicio", delete: "Eliminar Cuenta", copy: "© 2026 Denk • Desarrollador: Ömer Faruk Ay" },
  fr: { privacy: "Politique de Confidentialité", terms: "Conditions d'Utilisation", delete: "Supprimer le Compte", copy: "© 2026 Denk • Développeur : Ömer Faruk Ay" },
  it: { privacy: "Informativa sulla Privacy", terms: "Termini di Servizio", delete: "Elimina Account", copy: "© 2026 Denk • Sviluppatore: Ömer Faruk Ay" }
};

const SUPPORTED_LANGS = ["en", "tr", "es", "fr", "it"];

function getSavedLanguage() {
  try {
    const urlParams = new URLSearchParams(window.location.search);
    const param = (urlParams.get("lang") || "").toLowerCase();
    if (SUPPORTED_LANGS.includes(param)) return param;

    const stored = localStorage.getItem("denk_lang");
    if (SUPPORTED_LANGS.includes(stored)) return stored;

    const nav = (navigator.language || "").toLowerCase();
    for (const l of SUPPORTED_LANGS) {
      if (nav.startsWith(l)) return l;
    }
  } catch (e) {
    // fallback
  }
  return "en";
}

function setLanguage(lang) {
  if (!SUPPORTED_LANGS.includes(lang)) lang = "en";
  try {
    localStorage.setItem("denk_lang", lang);
  } catch (e) {}

  document.documentElement.lang = lang;
  if (document.body) {
    document.body.setAttribute("data-lang", lang);
  }

  // 1. Sync dropdown selector
  const selector = document.getElementById("lang-selector");
  if (selector && selector.value !== lang) {
    selector.value = lang;
  }

  // 2. Update navigation and footer labels
  const navData = I18N_NAV[lang] || I18N_NAV.en;
  const navP = document.getElementById("nav-privacy");
  if (navP) navP.textContent = navData.privacy;
  const navT = document.getElementById("nav-terms");
  if (navT) navT.textContent = navData.terms;
  const navD = document.getElementById("nav-delete");
  if (navD) navD.textContent = navData.delete;
  const footP = document.getElementById("foot-privacy");
  if (footP) footP.textContent = navData.privacy;
  const footT = document.getElementById("foot-terms");
  if (footT) footT.textContent = navData.terms;
  const footD = document.getElementById("foot-delete");
  if (footD) footD.textContent = navData.delete;
  const footC = document.getElementById("foot-copy");
  if (footC) footC.textContent = navData.copy;

  // 3. Switch main article contents
  const contents = document.querySelectorAll(".lang-content");
  contents.forEach(el => {
    el.style.display = "none";
  });
  const activeContent = document.getElementById("content-" + lang);
  if (activeContent) {
    activeContent.style.display = "block";
  } else {
    const fallback = document.getElementById("content-en");
    if (fallback) fallback.style.display = "block";
  }

  // 4. Update interactive deletion form if present
  if (typeof updateDeletionForm === "function") {
    updateDeletionForm(lang);
  }
}

window.setLanguage = setLanguage;
window.getSavedLanguage = getSavedLanguage;

// Run immediately upon script load and on DOMContentLoaded
(function init() {
  const current = getSavedLanguage();
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => setLanguage(current));
  } else {
    setLanguage(current);
  }
})();
