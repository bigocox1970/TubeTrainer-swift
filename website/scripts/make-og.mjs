// Renders the 1200x630 Open Graph image to public/og.png using sharp.
// Composites the real app icon. Run: node scripts/make-og.mjs
import sharp from 'sharp';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const pub = join(__dirname, '..', 'public');
const out = join(pub, 'og.png');

const ICON = 84;
const ICON_X = 80;
const ICON_Y = 110;

const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg width="1200" height="630" viewBox="0 0 1200 630" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="glow" cx="26%" cy="16%" r="62%">
      <stop offset="0%" stop-color="#f5322e" stop-opacity="0.28"/>
      <stop offset="60%" stop-color="#f5322e" stop-opacity="0"/>
    </radialGradient>
  </defs>
  <rect width="1200" height="630" fill="#0a0a0b"/>
  <rect width="1200" height="630" fill="url(#glow)"/>

  <text x="${ICON_X + ICON + 22}" y="${ICON_Y + 54}" font-family="Helvetica, Arial, sans-serif" font-size="40" font-weight="800" letter-spacing="-1.2">
    <tspan fill="#f7f7f5">Tube</tspan><tspan fill="#f5322e">Trainer</tspan>
  </text>

  <g font-family="Helvetica, Arial, sans-serif" font-weight="800" fill="#f7f7f5" letter-spacing="-2">
    <text x="80" y="322" font-size="70">The best coaching on</text>
    <text x="80" y="399" font-size="70">YouTube, beside your</text>
    <text x="80" y="476" font-size="70">workout.</text>
  </g>

  <text x="80" y="546" font-family="Helvetica, Arial, sans-serif" font-size="27" fill="#9a9aa2">
    Your coaches. Your exercises. Your progress. Free on iPhone.
  </text>

  <g transform="translate(944,104)">
    <rect x="0" y="0" width="180" height="52" rx="26" fill="#f5322e"/>
    <text x="90" y="34" text-anchor="middle" font-family="Helvetica, Arial, sans-serif" font-size="24" font-weight="700" fill="#fff">Free · iPhone</text>
  </g>
</svg>`;

const icon = await sharp(join(pub, 'icon-512.png'))
  .resize(ICON, ICON)
  .png()
  .toBuffer();

await sharp(Buffer.from(svg))
  .composite([{ input: icon, left: ICON_X, top: ICON_Y }])
  .png()
  .toFile(out);

console.log('Wrote', out);
