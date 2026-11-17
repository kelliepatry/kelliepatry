// Rasterize the SVG masters in assets/record to PNG at 1.25x (2000 px wide).
// Run from the repository root after build-record-figures.py: node scripts/rasterize-figures.cjs
const { chromium } = require('playwright');
const { readdirSync, readFileSync } = require('node:fs');
const { join, resolve } = require('node:path');

const dir = resolve('assets/record');
(async () => {
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1600, height: 820 }, deviceScaleFactor: 1.25 });
for (const f of readdirSync(dir).filter((f) => f.endsWith('.svg'))) {
  const svg = readFileSync(join(dir, f), 'utf8');
  await page.setContent(`<html><body style="margin:0">${svg}</body></html>`);
  await page.locator('svg').screenshot({ path: join(dir, f.replace(/\.svg$/, '.png')) });
  console.log('wrote', f.replace(/\.svg$/, '.png'));
}
await browser.close();
})();
