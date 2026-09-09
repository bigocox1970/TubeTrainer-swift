# TubeTrainer — Website

Marketing site for TubeTrainer. **Astro**, static output (pure pre-rendered HTML
→ great SEO/indexing), same dark/light theme as the app. Deploys to **Netlify**.

## Requirements

- **Node ≥ 22.12** (Astro 7). Locally: `nvm use 22`.

## Develop

```bash
cd website
npm install
npm run dev        # http://localhost:4321
npm run build      # static output → dist/
npm run preview
```

## Deploy (Netlify)

This is a monorepo. The **root** `../netlify.toml` already points Netlify at this
folder:

```
base = "website"       # build runs here
command = "npm run build"
publish = "dist"
NODE_VERSION = "22"
```

Connect the GitHub repo to Netlify once — it reads `netlify.toml` and every push
auto-deploys the site. No dashboard config needed. Point the `tubetrainer.app`
domain at the Netlify site when ready.

The email capture on the page uses **Netlify Forms** (`name="notify"`), which work
automatically on Netlify with no backend. Submissions appear in the Netlify
dashboard under Forms.

## Assets

- **Screenshots** (`public/screenshots/`) are captured from the iOS simulator with
  sample data (populated with real coaching). To refresh them, re-run the capture
  block in the project root (see `PROJECT_STATUS.md`) and copy into
  `public/screenshots/`.
- **Logo / favicons** derive from `TubeTrainer-Icon.png` (repo root): `icon.png`,
  `apple-touch-icon.png`, `favicon-64.png`.
- **OG image** (`public/og.png`, 1200×630) is generated:
  `node scripts/make-og.mjs` (uses `sharp` + the app icon). Re-run after changing
  the tagline or icon.

## Structure

```
website/
  astro.config.mjs         # site URL + sitemap
  src/
    layouts/Base.astro      # head/SEO/OG/JSON-LD, theme toggle, header, footer
    pages/index.astro       # the landing page + section styles
    components/PhoneFrame.astro
    styles/global.css       # design tokens (mirror the app), components
  public/                   # screenshots, icons, og.png, robots.txt
  scripts/make-og.mjs       # OG image generator
```

## SEO notes

- Static HTML, one canonical page. `<title>`, description, Open Graph, Twitter
  card, `MobileApplication` JSON-LD, `sitemap-index.xml`, and `robots.txt` are all
  in place. Scroll animations degrade gracefully (content is in the HTML and a
  `<noscript>` reveals everything without JS).
