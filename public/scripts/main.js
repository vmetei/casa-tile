// Header: mobile menu toggle and language switcher behavior.
(function () {
  'use strict';

  const menuBtn = document.querySelector('[data-menu-toggle]');
  const mobileMenu = document.querySelector('[data-mobile-menu]');
  if (menuBtn && mobileMenu) {
    menuBtn.addEventListener('click', () => {
      const open = mobileMenu.getAttribute('data-open') === 'true';
      mobileMenu.setAttribute('data-open', open ? 'false' : 'true');
      menuBtn.setAttribute('aria-expanded', open ? 'false' : 'true');
    });
  }

  // Language switcher: navigate to the equivalent path in the other locale.
  const langBtn = document.querySelector('[data-lang-switch]');
  if (langBtn) {
    langBtn.addEventListener('click', () => {
      const target = langBtn.getAttribute('data-target');
      if (target) window.location.href = target;
    });
  }

  // Mark active nav link.
  const path = window.location.pathname.replace(/\/index\.html$/, '/').replace(/\/$/, '');
  document.querySelectorAll('[data-nav-link]').forEach((a) => {
    const href = a.getAttribute('href').replace(/\/index\.html$/, '/').replace(/\/$/, '');
    if (href === path || (href !== '' && path.startsWith(href + '/'))) {
      a.setAttribute('aria-current', 'page');
    }
  });
})();
