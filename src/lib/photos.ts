// Build-time photo discovery via Vite's `import.meta.glob`.
//
// Drop a real product photo at `src/assets/products/<id>.<jpg|jpeg|png|webp>`
// and Astro's image pipeline will pick it up automatically: WebP conversion,
// responsive srcset variants, hashed filenames for indefinite caching, and
// proper width/height on the rendered <img> to prevent layout shift.
//
// If no real photo exists, the helper signals so the component can render the
// generated SVG pattern at `/products/<id>.svg` with a "Photo unavailable"
// badge — preventing customers from mistaking the placeholder for the real
// material.
import type { ImageMetadata } from 'astro';

// Eagerly import every file matching the glob. `eager: true` resolves at build
// time so we end up with a Record<path, module> we can look up by slug.
const photoModules = import.meta.glob<{ default: ImageMetadata }>(
  '/src/assets/products/*.{jpg,jpeg,png,webp,JPG,JPEG,PNG,WEBP}',
  { eager: true }
);

// Index by slug (filename without extension), keyed once per build.
const photosBySlug: Record<string, ImageMetadata> = {};
for (const [path, mod] of Object.entries(photoModules)) {
  const filename = path.split('/').pop()!;            // e.g. "carrara-white-60x60.jpg"
  const slug = filename.replace(/\.[^.]+$/, '').toLowerCase();
  photosBySlug[slug] = mod.default;
}

export type ProductImage =
  | { isPhoto: true; metadata: ImageMetadata }
  | { isPhoto: false; src: string };

/**
 * Resolve the best image source for a product:
 * - real photo (ImageMetadata for the <Image> pipeline), or
 * - SVG pattern fallback (raw URL string).
 */
export function getProductImage(slug: string): ProductImage {
  const metadata = photosBySlug[slug.toLowerCase()];
  if (metadata) return { isPhoto: true, metadata };
  return { isPhoto: false, src: `/products/${slug}.svg` };
}

/** True if a real photo file is present for this product. */
export function hasPhoto(slug: string): boolean {
  return Boolean(photosBySlug[slug.toLowerCase()]);
}
