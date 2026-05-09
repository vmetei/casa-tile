// URL helpers for both locales. All page URLs use trailing-slash form.
import type { Locale } from './data';

const PREFIX: Record<Locale, string> = { ro: '', ru: '/ru' };

export function homePath(locale: Locale): string {
  return locale === 'ro' ? '/' : '/ru/';
}

export function catalogPath(locale: Locale): string {
  return `${PREFIX[locale]}/catalog/`;
}

export function aboutPath(locale: Locale): string {
  return `${PREFIX[locale]}/about/`;
}

export function contactPath(locale: Locale): string {
  return `${PREFIX[locale]}/contact/`;
}

export function productPath(locale: Locale, slug: string): string {
  return `${PREFIX[locale]}/pages/${slug}/`;
}

export function svgPath(slug: string): string {
  return `/products/${slug}.svg`;
}

export function otherLocale(locale: Locale): Locale {
  return locale === 'ro' ? 'ru' : 'ro';
}
