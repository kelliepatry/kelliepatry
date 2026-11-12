// Rasterize assets/body plates to 1080x1350 PNG and the flipbook frames to MP4 and GIF.
// Run from the repository root after build-body-plates.py: node scripts/rasterize-body-plates.cjs
// Set SPACE_MONO to a local SpaceMono-Regular.ttf for the caption face; otherwise the
// browser's monospace is used and the caption will not match the studio face.
const { chromium } = require('playwright');
const { readdirSync, readFileSync, existsSync, mkdirSync } = require('node:fs');
const { join, resolve } = require('node:path');
const { execFileSync } = require('node:child_process');

const dir = resolve('assets/body');
const frames = join(dir, 'frames');
const font = process.env.SPACE_MONO;
const face = font && existsSync(font)
  ? `<style>@font-face{font-family:'Space Mono';src:url('data:font/ttf;base64,${readFileSync(font).toString('base64')}')}</style>`
  : '';
if (!face) console.warn('SPACE_MONO not set: captions fall back to the browser monospace');

async function shoot(page, svgPath, pngPath) {
  await page.setContent(`<html><head>${face}</head><body style="margin:0">${readFileSync(svgPath, 'utf8')}</body></html>`);
  await page.evaluate(() => document.fonts.ready);
  await page.locator('svg').screenshot({ path: pngPath });
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1080, height: 1350 }, deviceScaleFactor: 1 });
  for (const f of readdirSync(dir).filter((f) => f.endsWith('.svg'))) {
    await shoot(page, join(dir, f), join(dir, f.replace(/\.svg$/, '.png')));
    console.log('wrote', f.replace(/\.svg$/, '.png'));
  }
  if (existsSync(frames)) {
    const list = readdirSync(frames).filter((f) => f.endsWith('.svg')).sort();
    for (const f of list) await shoot(page, join(frames, f), join(frames, f.replace(/\.svg$/, '.png')));
    const src = join(frames, 'frame-%03d.png');
    execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', '8', '-i', src, '-c:v', 'libx264',
      '-pix_fmt', 'yuv420p', '-vf', 'loop=2:24:0', '-movflags', '+faststart', join(dir, 'flipbook-hand-sink.mp4')]);
    execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', '8', '-i', src, '-vf',
      'scale=540:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=48[p];[b][p]paletteuse=dither=none',
      '-loop', '0', join(dir, 'flipbook-hand-sink.gif')]);
    console.log('wrote flipbook-hand-sink.mp4 and .gif from', list.length, 'frames');
  }
  await browser.close();
})();
