import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Static output — pure pre-rendered HTML, ideal for SEO/indexing.
export default defineConfig({
  site: 'https://tubetrainer.app',
  integrations: [sitemap()],
  build: {
    inlineStylesheets: 'auto',
  },
});
