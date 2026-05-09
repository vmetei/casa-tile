# Casa Tile

A bilingual (RO + RU) static product catalog for ceramic and floor tiles, built with [Astro](https://astro.build).

## What's here

- **30 sample products** across 8 collections (marble, wood, concrete, terrazzo, subway, hexagon, stone, decorative)
- **Auto-generated SVG product images** (parametric, deterministic per product, served as static `/products/<slug>.svg`)
- **Filterable catalog** — collection, color, size, room, finish, material, price range
- **Sortable** — newest, price asc/desc, name
- **Fully responsive** — mobile (375px) → desktop
- **SEO-optimized** — server-rendered HTML, per-page meta tags, OpenGraph, Twitter cards, JSON-LD structured data (`Store` on home, `Product` on product pages, `ItemList` on catalog), `sitemap-index.xml` with hreflang alternates, `robots.txt`
- **Bilingual** — Romanian (default) at `/`, Russian at `/ru/`

## Tech stack

- **[Astro](https://astro.build)** v5 — SSG, content collections with type-safe Zod schemas
- **TypeScript** — type safety across data, paths, components
- **Vanilla CSS** — design tokens + components, no framework
- **Vanilla JS** — catalog filtering and contact form, no framework
- Output is **static HTML** — same SEO profile, same free-host deployment as before

Page weights (production build): home ~16 KB, catalog ~46 KB (30 cards inlined for filtering), product detail ~12 KB.

## Project layout

```
src/
├── content.config.ts      # Zod schema for product Content Collection
├── data/
│   ├── site.json          # site name, contact info
│   ├── collections.json   # collection definitions
│   ├── filters.json       # rooms, finishes, materials, colors
│   ├── products.json      # 30 products (the Content Collection source)
│   └── i18n.json          # all UI strings, RO + RU
├── components/
│   ├── BaseLayout.astro   # <html>, <head>, header, footer wrapper
│   ├── Header.astro
│   ├── Footer.astro
│   ├── ProductCard.astro
│   ├── FilterPanel.astro
│   └── pages/             # full page bodies, called from route files
│       ├── HomePage.astro
│       ├── CatalogPage.astro
│       ├── AboutPage.astro
│       ├── ContactPage.astro
│       └── ProductPage.astro
├── pages/
│   ├── index.astro        # /
│   ├── catalog.astro      # /catalog/
│   ├── about.astro        # /about/
│   ├── contact.astro      # /contact/
│   ├── pages/[slug].astro # /pages/<slug>/  (dynamic, one per product)
│   ├── ru/                # mirror under /ru/
│   └── products/[slug].svg.ts  # /products/<slug>.svg endpoints (build-time)
├── lib/
│   ├── data.ts            # content collection helpers, type-safe lookups
│   ├── paths.ts           # URL builders for both locales
│   └── tile-svg.ts        # parametric SVG generator (8 patterns)
└── styles/
    └── global.css

public/
├── favicon.svg
├── robots.txt
└── scripts/
    ├── main.js            # header, mobile menu, language switcher
    ├── catalog.js         # client-side filtering & sorting
    └── contact.js         # form handler

astro.config.mjs           # Astro config: site URL, i18n, sitemap integration
package.json
tsconfig.json
```

## Development

```bash
npm install
npm run dev          # http://localhost:4321/  (HMR, type checks)
npm run build        # output to dist/
npm run preview      # serve dist/ locally
```

Astro's dev server auto-reloads on file changes. The Content Collection schema (`src/content.config.ts`) gives TypeScript autocomplete and validation when editing `src/data/products.json`.

## Editing content

- **Products:** edit `src/data/products.json` (Zod-validated — schema mismatches fail the dev server immediately). Each entry needs `id` (URL slug), `name.ro` / `name.ru`, `collection`, `pattern` (`marble` / `wood` / `concrete` / `terrazzo` / `subway` / `hexagon` / `stone` / `decorative`), `baseColor` / `accentColor` (hex), and stock/spec fields.
- **UI strings:** edit `src/data/i18n.json` (RO + RU side by side).
- **Collections / rooms / finishes / materials / colors:** edit `src/data/collections.json` and `src/data/filters.json`.
- **Real photos instead of SVGs:** the SVG endpoint is at [src/pages/products/[slug].svg.ts](src/pages/products/[slug].svg.ts) — replace it with a static `public/products/*.jpg` and update `svgPath` in [src/lib/paths.ts](src/lib/paths.ts).

## Adding a new product category (e.g. sinks)

This is the killer feature of moving to Astro. The pattern:

1. Add a new collection to [src/content.config.ts](src/content.config.ts) — e.g. `const sinks = defineCollection({ loader: file('src/data/sinks.json'), schema: z.object({ ... }) })`. Define whatever attributes sinks need (basin count, mounting type) — they don't have to match tile attributes.
2. Add the data file `src/data/sinks.json`.
3. Either reuse the catalog UI by joining product types, or add a new route `src/pages/sinks/[slug].astro`.

Zod will type-check everything at build time.

## Deploy (free)

Output is static HTML. Any of these hosts works free with auto HTTPS:

- **Cloudflare Pages** *(recommended)* — connect GitHub repo, build command `npm run build`, output directory `dist`, free unlimited bandwidth.
- **Netlify** — same setup, drag-and-drop ZIP also works.
- **Vercel** — same.
- **GitHub Pages** — works but the URL has a path segment (`/<repo>/`) which would break absolute paths; less convenient.

Set `site` in [astro.config.mjs](astro.config.mjs) to your real (or chosen subdomain) URL — it's used for canonical tags, OG metadata, and the sitemap.

## What's not included

- Cart / checkout (catalog is browse + inquiry only; product pages link to `/contact/?product=<slug>`).
- Real backend for the contact form — `public/scripts/contact.js` simulates success. To make it real, swap in a `fetch()` to Formspree, a Cloudflare Worker, or your own endpoint.
- Headless CMS — easy to add later (Decap, Sanity, Storyblok all have official Astro integrations) without changing the output format.
