import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://casa-tile.metei1997vasile.workers.dev',
  trailingSlash: 'ignore',
  i18n: {
    defaultLocale: 'ro',
    locales: ['ro', 'ru'],
    routing: {
      prefixDefaultLocale: false,
    },
  },
  integrations: [
    sitemap({
      i18n: {
        defaultLocale: 'ro',
        locales: { ro: 'ro-RO', ru: 'ru-RU' },
      },
    }),
  ],
  build: {
    format: 'directory',
  },
});
