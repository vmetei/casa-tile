// Catalog filtering, sorting and result count.
// Reads product attributes from `data-*` attributes on each .product-card,
// so this works without any framework or pre-loaded JSON.
(function () {
  'use strict';

  const grid = document.querySelector('[data-product-grid]');
  if (!grid) return;

  const cards = Array.from(grid.querySelectorAll('.product-card'));
  const resultCount = document.querySelector('[data-result-count]');
  const noResults = document.querySelector('[data-no-results]');
  const sortSelect = document.querySelector('[data-sort]');
  const filtersPanel = document.querySelector('[data-filters]');
  const showFiltersBtn = document.querySelector('[data-show-filters]');
  const closeFiltersBtn = document.querySelector('[data-close-filters]');
  const clearBtn = document.querySelector('[data-clear-filters]');
  const minPrice = document.querySelector('[data-min-price]');
  const maxPrice = document.querySelector('[data-max-price]');

  function parseList(s) { return (s || '').split(',').map(x => x.trim()).filter(Boolean); }

  // Parse each card's attributes once into a model.
  const items = cards.map((el) => ({
    el,
    collection: el.dataset.collection,
    color: el.dataset.color,
    size: el.dataset.size,
    finish: el.dataset.finish,
    material: el.dataset.material,
    rooms: parseList(el.dataset.rooms),
    price: parseFloat(el.dataset.price) || 0,
    name: el.dataset.name || el.querySelector('.name')?.textContent || '',
    stock: el.dataset.stock === 'true',
    featured: el.dataset.featured === 'true',
    order: parseInt(el.dataset.order || '0', 10),
  }));

  function getCheckedValues(group) {
    return Array.from(document.querySelectorAll(`input[data-filter="${group}"]:checked`))
      .map(i => i.value);
  }

  function passes(item) {
    const groups = ['collection', 'color', 'size', 'finish', 'material'];
    for (const g of groups) {
      const sel = getCheckedValues(g);
      if (sel.length && !sel.includes(item[g])) return false;
    }
    const rooms = getCheckedValues('room');
    if (rooms.length && !rooms.some(r => item.rooms.includes(r))) return false;

    const min = parseFloat(minPrice?.value);
    const max = parseFloat(maxPrice?.value);
    if (!isNaN(min) && item.price < min) return false;
    if (!isNaN(max) && item.price > max) return false;

    return true;
  }

  function sortItems(arr) {
    const v = sortSelect?.value || 'newest';
    const sorted = arr.slice();
    switch (v) {
      case 'price-asc':  sorted.sort((a, b) => a.price - b.price); break;
      case 'price-desc': sorted.sort((a, b) => b.price - a.price); break;
      case 'name-asc':   sorted.sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' })); break;
      default:           sorted.sort((a, b) => (b.featured - a.featured) || (a.order - b.order)); break;
    }
    return sorted;
  }

  function update() {
    const visible = items.filter(passes);
    const ordered = sortItems(visible);

    // Re-append in sorted order; Hide non-passing.
    items.forEach((it) => { it.el.hidden = true; });
    ordered.forEach((it) => {
      it.el.hidden = false;
      grid.appendChild(it.el);
    });

    if (resultCount) {
      const tmpl = resultCount.dataset.template || '{count}';
      resultCount.innerHTML = tmpl.replace('{count}', `<strong>${ordered.length}</strong>`);
    }
    if (noResults) noResults.hidden = ordered.length !== 0;
    grid.hidden = ordered.length === 0;
  }

  // Wire up checkboxes, color swatches, sort, price.
  document.querySelectorAll('input[data-filter]').forEach((el) => {
    el.addEventListener('change', update);
  });
  if (sortSelect) sortSelect.addEventListener('change', update);
  if (minPrice) minPrice.addEventListener('input', debounce(update, 200));
  if (maxPrice) maxPrice.addEventListener('input', debounce(update, 200));

  // Filter group collapse toggles.
  document.querySelectorAll('.filter-group-title').forEach((btn) => {
    btn.addEventListener('click', () => {
      const group = btn.closest('.filter-group');
      const collapsed = group.getAttribute('data-collapsed') === 'true';
      group.setAttribute('data-collapsed', collapsed ? 'false' : 'true');
    });
  });

  // Mobile filter open/close.
  if (showFiltersBtn && filtersPanel) {
    showFiltersBtn.addEventListener('click', () => {
      filtersPanel.setAttribute('data-open', 'true');
      document.body.classList.add('filters-open');
    });
  }
  if (closeFiltersBtn && filtersPanel) {
    closeFiltersBtn.addEventListener('click', () => {
      filtersPanel.setAttribute('data-open', 'false');
      document.body.classList.remove('filters-open');
    });
  }

  // Clear all filters.
  if (clearBtn) {
    clearBtn.addEventListener('click', () => {
      document.querySelectorAll('input[data-filter]').forEach((i) => { i.checked = false; });
      if (minPrice) minPrice.value = '';
      if (maxPrice) maxPrice.value = '';
      if (sortSelect) sortSelect.value = 'newest';
      update();
    });
  }

  function debounce(fn, ms) {
    let t; return function () { clearTimeout(t); t = setTimeout(() => fn.apply(this, arguments), ms); };
  }

  // Initial layout (apply default sort).
  update();
})();
