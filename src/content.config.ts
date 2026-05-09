import { defineCollection, z } from 'astro:content';
import { file } from 'astro/loaders';

// Bilingual text helper (RO + RU). Reused across product, collection, filter schemas.
const bilingual = z.object({ ro: z.string(), ru: z.string() });

// Product schema. Adding a new category later (sinks, paint, etc.) will mean
// adding a new collection here with its own attribute schema.
const products = defineCollection({
  loader: file('src/data/products.json'),
  schema: z.object({
    name: bilingual,
    collection: z.string(),
    pattern: z.enum(['marble', 'wood', 'concrete', 'terrazzo', 'subway', 'hexagon', 'stone', 'decorative']),
    baseColor: z.string().regex(/^#[0-9a-fA-F]{6}$/),
    accentColor: z.string().regex(/^#[0-9a-fA-F]{6}$/),
    color: z.string(),
    size: z.string(),
    rooms: z.array(z.string()).nonempty(),
    finish: z.string(),
    material: z.string(),
    price: z.number().positive(),
    thickness: z.number().positive(),
    waterAbsorption: z.string(),
    frostResistant: z.boolean(),
    stock: z.boolean(),
    featured: z.boolean(),
  }),
});

export const collections = { products };
