// Renders the iOS app icon and launch images from the Piston Forge brand mark.
//
// The mark is the same circle, bar, dot and rod as the boot screen in index.html.
// Rendering uses the "playwright" package already in devDependencies. Output files
// keep their existing names (taken from ios/App/App/Assets.xcassets/*/Contents.json)
// and their existing pixel sizes, so the catalogs stay valid.
//
// Every PNG written is opaque RGB (colour type 2). App Store upload rejects an app
// icon that carries an alpha channel, so an RGBA screenshot is flattened here.
//
// Run from the project root: node scripts/make-icons.mjs

import { chromium } from 'playwright';
import { deflateSync, inflateSync } from 'node:zlib';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const CATALOG = join(ROOT, 'ios/App/App/Assets.xcassets');
const BG = '#080b0c';
const AMBER = '#ffb23e';

// The mark's artwork spans 2.2 to 37.8 of its 40-unit viewBox (the ring plus its stroke).
// Sizes below are for the visible artwork, so the SVG box is scaled up by 40 / 35.6.
const ART_SPAN = 35.6;
const VIEWBOX = 40;

const ICON_MARK_RATIO = 0.62; // visible mark as a share of the canvas width
const LAUNCH_MARK_RATIO = 0.18;

const PNG_SIG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

function readPngSize(file) {
  const head = readFileSync(file).subarray(0, 24);
  if (!head.subarray(0, 8).equals(PNG_SIG)) throw new Error(`${file} is not a PNG`);
  return { width: head.readUInt32BE(16), height: head.readUInt32BE(20) };
}

function catalogFilenames(setDir) {
  const contents = JSON.parse(readFileSync(join(setDir, 'Contents.json'), 'utf8'));
  return [...new Set(contents.images.map((image) => image.filename).filter(Boolean))];
}

function markHtml(size, markRatio, lift) {
  const visible = size * markRatio;
  const box = Math.round((visible * VIEWBOX) / ART_SPAN);
  const background = lift
    ? `radial-gradient(circle at 50% 50%, rgba(255,178,62,0.08) 0%, rgba(255,178,62,0) 55%), ${BG}`
    : BG;
  return `<!doctype html>
<html><head><meta charset="utf-8"><style>
html, body { margin: 0; padding: 0; width: ${size}px; height: ${size}px; overflow: hidden; background: ${BG}; }
.canvas { position: absolute; left: 0; top: 0; width: ${size}px; height: ${size}px;
  background: ${background}; display: flex; align-items: center; justify-content: center; }
svg { display: block; width: ${box}px; height: ${box}px; color: ${AMBER}; overflow: visible; }
</style></head>
<body><div class="canvas">
<svg viewBox="0 0 40 40" aria-hidden="true">
  <circle cx="20" cy="20" r="16.5" fill="none" stroke="currentColor" stroke-width="2.6" />
  <path d="M20 7.2v8.1" stroke="currentColor" stroke-width="4.4" stroke-linecap="round" />
  <circle cx="24.8" cy="20.8" r="3" fill="currentColor" />
  <path d="M23.2 22.7 12.2 31.4" stroke="currentColor" stroke-width="4.4" stroke-linecap="round" />
</svg>
</div></body></html>`;
}

const CRC_TABLE = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});

function crc32(buf) {
  let c = 0xffffffff;
  for (const byte of buf) c = CRC_TABLE[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([length, body, crc]);
}

function paeth(a, b, c) {
  const p = a + b - c;
  const pa = Math.abs(p - a);
  const pb = Math.abs(p - b);
  const pc = Math.abs(p - c);
  if (pa <= pb && pa <= pc) return a;
  return pb <= pc ? b : c;
}

// Returns an opaque RGB (colour type 2) version of a PNG. Throws if any pixel is not opaque.
function toOpaqueRgbPng(buf) {
  if (!buf.subarray(0, 8).equals(PNG_SIG)) throw new Error('screenshot is not a PNG');
  const chunks = [];
  for (let pos = 8; pos < buf.length; ) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    chunks.push({ type, data: buf.subarray(pos + 8, pos + 8 + len) });
    pos += 12 + len;
    if (type === 'IEND') break;
  }
  const ihdr = chunks.find((c) => c.type === 'IHDR').data;
  const width = ihdr.readUInt32BE(0);
  const height = ihdr.readUInt32BE(4);
  const bitDepth = ihdr[8];
  const colorType = ihdr[9];
  const interlace = ihdr[12];
  if (colorType === 2 && bitDepth === 8 && interlace === 0) return buf;
  if (colorType !== 6 || bitDepth !== 8 || interlace !== 0) {
    throw new Error(`unsupported screenshot PNG: colour type ${colorType}, depth ${bitDepth}, interlace ${interlace}`);
  }

  const raw = inflateSync(Buffer.concat(chunks.filter((c) => c.type === 'IDAT').map((c) => c.data)));
  const bpp = 4;
  const stride = width * bpp;
  const pixels = Buffer.alloc(height * stride);
  const zeroRow = Buffer.alloc(stride);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const src = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
    const row = pixels.subarray(y * stride, (y + 1) * stride);
    const up = y > 0 ? pixels.subarray((y - 1) * stride, y * stride) : zeroRow;
    for (let x = 0; x < stride; x++) {
      const left = x >= bpp ? row[x - bpp] : 0;
      const above = up[x];
      const upLeft = x >= bpp ? up[x - bpp] : 0;
      let predictor;
      switch (filter) {
        case 0: predictor = 0; break;
        case 1: predictor = left; break;
        case 2: predictor = above; break;
        case 3: predictor = (left + above) >> 1; break;
        case 4: predictor = paeth(left, above, upLeft); break;
        default: throw new Error(`bad PNG filter type ${filter} on row ${y}`);
      }
      row[x] = (src[x] + predictor) & 0xff;
    }
  }

  const rowBytes = width * 3 + 1;
  const rgb = Buffer.alloc(height * rowBytes);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const s = y * stride + x * 4;
      if (pixels[s + 3] !== 255) {
        throw new Error(`pixel ${x},${y} is not opaque (alpha ${pixels[s + 3]})`);
      }
      const d = y * rowBytes + 1 + x * 3;
      rgb[d] = pixels[s];
      rgb[d + 1] = pixels[s + 1];
      rgb[d + 2] = pixels[s + 2];
    }
  }

  const newHeader = Buffer.from(ihdr);
  newHeader[9] = 2;
  const keep = new Set(['pHYs', 'sRGB', 'gAMA', 'cHRM', 'iCCP']);
  return Buffer.concat([
    PNG_SIG,
    pngChunk('IHDR', newHeader),
    ...chunks.filter((c) => keep.has(c.type)).map((c) => pngChunk(c.type, c.data)),
    pngChunk('IDAT', deflateSync(rgb)),
    pngChunk('IEND', Buffer.alloc(0)),
  ]);
}

const iconDir = join(CATALOG, 'AppIcon.appiconset');
const splashDir = join(CATALOG, 'Splash.imageset');

const jobs = [];
for (const filename of catalogFilenames(iconDir)) {
  const path = join(iconDir, filename);
  const { width, height } = readPngSize(path);
  if (width !== height) throw new Error(`${filename} is not square (${width}x${height})`);
  jobs.push({ path, size: width, markRatio: ICON_MARK_RATIO, lift: true });
}
for (const filename of catalogFilenames(splashDir)) {
  const path = join(splashDir, filename);
  const { width, height } = readPngSize(path);
  if (width !== height) throw new Error(`${filename} is not square (${width}x${height})`);
  jobs.push({ path, size: width, markRatio: LAUNCH_MARK_RATIO, lift: false });
}

const browser = await chromium.launch();
try {
  const cache = new Map();
  for (const job of jobs) {
    const key = `${job.size}:${job.markRatio}:${job.lift}`;
    if (!cache.has(key)) {
      const page = await browser.newPage({
        viewport: { width: job.size, height: job.size },
        deviceScaleFactor: 1,
      });
      await page.setContent(markHtml(job.size, job.markRatio, job.lift), { waitUntil: 'load' });
      const shot = await page.screenshot({ type: 'png', omitBackground: false, fullPage: false });
      await page.close();
      cache.set(key, toOpaqueRgbPng(shot));
    }
    writeFileSync(job.path, cache.get(key));
    const written = readPngSize(job.path);
    console.log(`wrote ${job.path} ${written.width}x${written.height}`);
  }
} finally {
  await browser.close();
}
