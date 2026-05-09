// Centralized data loading helpers. All static data is bundled at build time.
import { getCollection, type CollectionEntry } from 'astro:content';
import siteData from '../data/site.json';
import collectionsData from '../data/collections.json';
import filtersData from '../data/filters.json';
import i18nData from '../data/i18n.json';

export type Locale = 'ro' | 'ru';
export const LOCALES: Locale[] = ['ro', 'ru'];
export const DEFAULT_LOCALE: Locale = 'ro';

export type Bilingual = { ro: string; ru: string };

export const site = siteData as {
  name: string;
  tagline: Bilingual;
  phone: string;
  email: string;
  address: Bilingual;
};

export const collections = collectionsData as Array<{
  id: string;
  name: Bilingual;
  description: Bilingual;
}>;

export const filters = filtersData as {
  rooms: Array<{ id: string; name: Bilingual }>;
  finishes: Array<{ id: string; name: Bilingual }>;
  materials: Array<{ id: string; name: Bilingual }>;
  colors: Array<{ id: string; hex: string; name: Bilingual }>;
};

export const i18n = i18nData as Record<Locale, any>;

export type Product = CollectionEntry<'products'>;

export async function getProducts(): Promise<Product[]> {
  return getCollection('products');
}

export function getCollectionById(id: string) {
  return collections.find((c) => c.id === id);
}

export function getRoomById(id: string) {
  return filters.rooms.find((r) => r.id === id);
}

export function getFinishById(id: string) {
  return filters.finishes.find((f) => f.id === id);
}

export function getMaterialById(id: string) {
  return filters.materials.find((m) => m.id === id);
}

export function getColorById(id: string) {
  return filters.colors.find((c) => c.id === id);
}
