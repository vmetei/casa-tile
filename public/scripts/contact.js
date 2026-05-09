// Contact form: client-side handling.
// In production, replace the simulated success with a fetch() call to a backend endpoint
// (e.g. a Cloudflare Worker, Formspree, or your own API).
(function () {
  'use strict';
  const form = document.getElementById('contact-form');
  if (!form) return;
  const success = form.querySelector('[data-form-success]');

  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (!form.checkValidity()) { form.reportValidity(); return; }
    // Simulated submission
    const btn = form.querySelector('button[type="submit"]');
    btn.disabled = true;
    setTimeout(() => {
      success.setAttribute('data-shown', 'true');
      form.reset();
      btn.disabled = false;
    }, 400);
  });

  // If product slug is in query string, prefill the message.
  const params = new URLSearchParams(window.location.search);
  const product = params.get('product');
  if (product) {
    const msg = form.querySelector('[name="message"]');
    if (msg && !msg.value) msg.value = `Sunt interesat de produsul: ${product}\n`;
  }
})();
