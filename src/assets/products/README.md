# Product photos

Drop product photos in this folder. The build picks them up automatically and runs them through Astro's image pipeline — no code changes needed.

## How to add a photo

1. Find the product's `id` in [`src/data/products.json`](../../data/products.json) (e.g. `carrara-white-60x60`).
2. Save the photo as `<id>.jpg` in this folder.
   - Example: `carrara-white-60x60.jpg`
3. Run `npm run dev` to preview, or push to git for an auto-deploy.

Supported extensions: `.jpg`, `.jpeg`, `.png`, `.webp` (case-insensitive).

## What the build pipeline does automatically

When you drop a JPG/PNG/WebP here, Astro:

- **Converts to WebP** at multiple widths (the `widths` configured per usage — typically 300 / 600 / 900 / 1200 px).
- **Generates a `srcset`** so browsers download the smallest variant they need for the user's screen.
- **Adds hashed filenames** for indefinite caching (`carrara-white-60x60.abc123.webp`).
- **Sets `width`/`height`** on the rendered `<img>` so the browser reserves layout space before the image loads — no jank.
- **Lazy-loads** below-the-fold images.

You don't have to think about responsive image variants or cache busting — just drop in the original JPG at whatever resolution your factory supplies.

## Recommended specs

- **Aspect ratio:** **2:1 landscape** (factory standard, e.g. 1500×750). The card layout derives each product's display ratio from its `size` field (60x60 → 1:1 square, 60x120 → 2:1 landscape, 30x60 → 2:1, 20x120 → 6:1, etc.) and crops the photo with `object-fit: cover`. A 2:1 source crops cleanly into any of these target ratios.
- **Size:** **1500×750 px** is the factory standard and what the pipeline is sized for. Larger is fine — Astro downscales as needed. Smaller is not recommended (the product detail page requests up to ~1600 px wide variants for retina).
- **Format:** JPG (factory standard). Astro converts to WebP at build time.
- **Naming:** must match the product `id` exactly (lowercase, hyphens between words).

## What happens when a photo is missing

Products without a photo automatically use the generated SVG pattern as a placeholder, with a clear **"Foto indisponibilă" / "Фото отсутствует"** badge. The badge disappears the moment you drop in a real photo and rebuild.

## Tips

- You don't have to upload photos for every product at once. Add them progressively — products without a photo keep showing the labeled placeholder.
- The product `id` is also the URL slug (`/pages/<id>/`), so renaming a photo file requires renaming the product `id` in `products.json` too.
- Photos are committed to git; they go through normal `git add` / `git commit` / `git push`. Cloudflare runs `npm run build` on each push and serves the optimized variants.
- Originals can stay as JPG even though browsers receive WebP — Astro keeps the source untouched.
