// Makes the pictures the RGB LED lights look is drawn from, in app/images/rgb/. Sizes are for a
// 1920 x 1080 screen; on a 1280 x 720 one the app draws them two thirds the size.
//   tv-glow.png          680 x 500  the wall round the guide's TV with the light cut out of it,
//                                   at half size (drawn twice the size over the LED colours)
//   panel-glow.png       884 x 604  the same round the panel the Settings pages sit on
//   row-light.png        320 x 36   the focused row's LED bar and its wash on the wall (half size)
//   panel-row-light.png  380 x 32   the same on the panel
//   badge.png             58 x 40   the white "TV" badge beside "b0r3d"
//   cap.png               25 x 40   a remote key's outline, drawn in three slices to any width
//   star.png              24 x 24   the options key's star, for the key on the hint bar
//   arrow-r.png, arrow-l.png  11 x 16  the arrows beside a setting that Left and Right change
//   <way>-h.png         2048 x 1    a colourway's loop of LED colours, twice over, and the same
//   <way>-hr.png        2048 x 1    backwards; -v and -vr are the two standing up (1 x 2048),
//   <way>-v.png, <way>-vr.png       for the colourways rainbow, neon and aurora
// No picture is over 2048 pixels on a side, the most a Roku picture may be.
// How the light works: the colours are drawn first, then the glow picture on top. Where the
// light is strong the picture is see-through, so the LED colour shows; further out it turns into
// the plain wall. Its colour is lifted near the edge, which adds a white-hot core.
// Plain PNGs, no other files needed. Run from the repo's top folder:
//   node tools/make-rgb-light.js
'use strict';

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const OUT = path.join(__dirname, '..', 'app', 'images', 'rgb');

// ---- colour

const clamp01 = (v) => (v < 0 ? 0 : v > 1 ? 1 : v);
function hex(h) {
  h = h.replace('#', '');
  return [0, 2, 4].map((i) => parseInt(h.slice(i, i + 2), 16));
}
const toLin = (c) => {
  c /= 255;
  return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
};
const toSrgb = (c) => {
  c = clamp01(c);
  return 255 * (c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055);
};
function oklab(rgb) {
  const [r, g, b] = rgb.map(toLin);
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [
    0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s,
  ];
}
function fromOklab([L, A, B]) {
  const l = Math.pow(L + 0.3963377774 * A + 0.2158037573 * B, 3);
  const m = Math.pow(L - 0.1055613458 * A - 0.0638541728 * B, 3);
  const s = Math.pow(L - 0.0894841775 * A - 1.291485548 * B, 3);
  return [
    toSrgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
    toSrgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
    toSrgb(-0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s),
  ];
}
// A closed loop through the colours, smooth (a periodic Catmull-Rom curve in OKLab, so the
// colours between the stops stay bright). u wraps at 1.
function loop(stops) {
  const P = stops.map((s) => oklab(hex(s)));
  const n = P.length;
  return (u) => {
    u = ((u % 1) + 1) % 1;
    const x = u * n;
    const i = Math.floor(x);
    const t = x - i;
    const t2 = t * t;
    const t3 = t2 * t;
    const p0 = P[(i - 1 + n) % n];
    const p1 = P[i % n];
    const p2 = P[(i + 1) % n];
    const p3 = P[(i + 2) % n];
    return fromOklab([0, 1, 2].map((k) => 0.5 * (2 * p1[k] + (-p0[k] + p2[k]) * t +
      (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3)));
  };
}

// The colourways. Each is a loop of LED colours laid once round the lit thing's edge. Colour
// cycle uses the rainbow's loop, one colour at a time, so it has no pictures of its own.
const WAYS = {
  rainbow: loop(['#FF3346', '#FF7424', '#FFBE2A', '#C9F53A', '#3EF07A', '#1FE8C6',
    '#22C4FF', '#2F7DFF', '#5A50FF', '#9A47FF', '#E040EE', '#FF3398']),
  neon: loop(['#FF2FD2', '#C23BFF', '#7449FF', '#3C7CFF', '#20D6FF', '#3C7CFF', '#7449FF', '#C23BFF']),
  aurora: loop(['#3BFF84', '#45FF6E', '#2CF7A6', '#1ED9C8', '#7258FF', '#1ED9C8', '#2CF7A6']),
};
// the ring pictures' pixels for one time round. Twice over that's 2048, the biggest a Roku
// picture may be on either side.
const LOOP_PX = 1024;

const WALL = hex('#111216');
const PANEL = hex('#0B0C0F');

// ---- the light on the wall

const GLOW_TV = {
  reach: 260, // how far the light reaches onto the wall
  peak: 0.85,
  maxI: 0.92, // its strength right at the edge
  w1: 0.3,
  l1: 30,
  l2: 120, // a tight halo plus a long soft tail
  bottomGain: 0.38, // below the lit thing the light thins out, so the text there stays clean
  bottomFade: 90,
  cornerDip: 0.25, // fewer LEDs reach a corner, so it's a little dimmer further out
  cornerFade: 90,
  hot: 0.13,
  hotLen: 18, // a white-hot core right behind the edge
};
const GLOW_PANEL = Object.assign({}, GLOW_TV, { peak: 0.78 });

function falloff(d, P) {
  const u = d / P.reach;
  if (u >= 1) return 0;
  const win = 1 - u * u;
  return (P.w1 * Math.exp(-d / P.l1) + (1 - P.w1) * Math.exp(-d / P.l2)) * win * win;
}

// The light the wall gets at (px, py), measured from the lit thing's top left corner: how much
// LED colour, and how much white on top.
function lightAt(px, py, W, H, P) {
  const ox = px < 0 ? -px : px > W ? px - W : 0;
  const oyT = py < 0 ? -py : 0;
  const oyB = py > H ? py - H : 0;
  const oy = oyT + oyB;
  if (ox === 0 && oy === 0) return [P.peak, P.hot];
  let kB = 1;
  if (oyB > 0) {
    const u = clamp01(oyB / P.bottomFade);
    kB = 1 - (1 - P.bottomGain) * u * u * (3 - 2 * u);
  }
  const d = Math.hypot(ox, oy);
  let A = 1;
  if (ox > 0 && oy > 0) {
    const s = (2 * ox * oy) / (d * d);
    const u = clamp01(d / P.cornerFade);
    A = 1 - P.cornerDip * s * s * u * u * (3 - 2 * u);
  }
  return [P.peak * A * kB * falloff(d, P), P.hot * A * kB * Math.exp(-d / P.hotLen)];
}

// The glow picture at half size: the wall with the light cut out of its see-through-ness, its
// colour lifted where the core is hot. Drawn over colour C it leaves
// wall x (1 - I) + C x I + white x hot. The outermost 2 pixels are plain wall, so smooth
// scaling never lets colour bleed out at the picture's edge.
function glowPicture(W, H, P, base) {
  const G = P.reach;
  const w = W / 2 + G;
  const h = H / 2 + G;
  const wall = base.map((v) => v / 255);
  const px = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const k = (y * w + x) * 4;
      if (x < 2 || y < 2 || x >= w - 2 || y >= h - 2) {
        px[k] = base[0];
        px[k + 1] = base[1];
        px[k + 2] = base[2];
        px[k + 3] = 255;
        continue;
      }
      let [I, hot] = lightAt(x * 2 + 1 - G, y * 2 + 1 - G, W, H, P);
      I = Math.min(I, P.maxI);
      const a = 1 - I;
      const rgb = wall.map((c) => Math.round(255 * Math.min(1, c + hot / a)));
      px[k] = rgb[0];
      px[k + 1] = rgb[1];
      px[k + 2] = rgb[2];
      px[k + 3] = Math.round(255 * clamp01(a));
    }
  }
  return { w, h, px };
}

// ---- the focused row's light: a short LED bar with a hot core, a bloom round it and a soft
// wash of its light across the row, at half size (o's numbers are full size)

const ROW = { barX: 16, barW: 8, barH: 44, coreH: 15, soft: 19, wash: 0.48, mix: 0.6, l1: 70, l2: 190, bloom: 0.6, bloomLen: 6, hot: 0.55 };
const PANEL_ROW = Object.assign({}, ROW, { barH: 40, coreH: 21, wash: 0.3 });

function rowLight(fw, fh, base, o) {
  const w = fw / 2;
  const h = fh / 2;
  const wall = base.map((v) => v / 255);
  const span = fw - o.barX - o.barW;
  const px = Buffer.alloc(w * h * 4);
  for (let hy = 0; hy < h; hy++) {
    for (let hx = 0; hx < w; hx++) {
      const x = hx * 2 + 1;
      const y = hy * 2 + 1;
      const cy = fh / 2;
      const qx = Math.abs(x - (o.barX + o.barW / 2));
      const qy = Math.abs(y - cy) - (o.barH / 2 - o.barW / 2);
      const dBar = Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - o.barW / 2;
      const cover = clamp01(0.5 - dBar / 2);
      const inner = clamp01(-dBar / (o.barW / 2));
      const dx = Math.max(0, x - (o.barX + o.barW));
      const vy = Math.abs(y - cy);
      let v = vy < o.coreH ? 1 : clamp01(1 - (vy - o.coreH) / o.soft);
      v = v * v * (3 - 2 * v);
      const tail = clamp01(1 - dx / span);
      const behind = x < o.barX ? Math.exp(-(o.barX - x) / 4) : 1;
      const wash = o.wash * (o.mix * Math.exp(-dx / o.l1) + (1 - o.mix) * Math.exp(-dx / o.l2)) * v * tail * tail * behind;
      const bloom = dBar > 0 ? o.bloom * Math.exp(-dBar / o.bloomLen) : 0;
      let I = 1 - (1 - wash) * (1 - bloom) * (1 - cover * 0.96);
      I = Math.min(I, 0.96);
      const hot = cover * o.hot * Math.pow(inner, 0.6);
      const a = 1 - I;
      const k = (hy * w + hx) * 4;
      const rgb = wall.map((c) => Math.round(255 * Math.min(1, c + hot / a)));
      // the outermost pixel is plain surface, so smooth scaling never shows the colour under it
      const edge = hx === 0 || hy === 0 || hx === w - 1 || hy === h - 1;
      px[k] = edge ? base[0] : rgb[0];
      px[k + 1] = edge ? base[1] : rgb[1];
      px[k + 2] = edge ? base[2] : rgb[2];
      px[k + 3] = edge ? 255 : Math.round(255 * clamp01(a));
    }
  }
  return { w, h, px };
}

// ---- small shapes

function sdRoundRect(px, py, w, h, r) {
  const qx = Math.abs(px - w / 2) - (w / 2 - r);
  const qy = Math.abs(py - h / 2) - (h / 2 - r);
  return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r;
}

function shape(w, h, fn) {
  const px = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const [r, g, b, a] = fn(x + 0.5, y + 0.5);
      const k = (y * w + x) * 4;
      px[k] = r;
      px[k + 1] = g;
      px[k + 2] = b;
      px[k + 3] = Math.round(255 * clamp01(a));
    }
  }
  return { w, h, px };
}

// the "TV" badge: a white rounded rectangle; the app writes "TV" on it in the wall's colour
const badge = () => shape(58, 40, (x, y) => [255, 255, 255, clamp01(0.5 - sdRoundRect(x, y, 58, 40, 7))]);

// a key on the remote: a thin rounded outline round a faint fill. The app draws its left 12
// columns, the middle column stretched, then its right 12 columns.
const cap = () => shape(25, 40, (x, y) => {
  const d = sdRoundRect(x, y, 25, 40, 8);
  const ring = clamp01(0.5 - d) - clamp01(0.5 - (d + 2));
  const fill = clamp01(0.5 - (d + 2)) * 0.06;
  return [255, 255, 255, Math.max(ring * 0.42, fill)];
});

// the remote's options key: three bars through the middle, like the app's DrawStar
const star = () => shape(24, 24, (x, y) => {
  let a = 0;
  for (const deg of [90, 30, 150]) {
    const r = (deg * Math.PI) / 180;
    const dx = x - 12;
    const dy = y - 12;
    const along = Math.abs(dx * Math.cos(r) - dy * Math.sin(r));
    const across = Math.abs(dx * Math.sin(r) + dy * Math.cos(r));
    a = Math.max(a, clamp01(9.5 - along) * clamp01(2.1 - across));
  }
  return [255, 255, 255, a];
});

// the small solid arrows either side of a setting that Left and Right change
const arrow = (pointsRight) => shape(11, 16, (x, y) => {
  const u = pointsRight ? x : 11 - x;
  const half = 8 * (1 - u / 11);
  return [255, 255, 255, clamp01(half - Math.abs(y - 8) + 0.5)];
});

// a colourway's loop, twice over (so any stretch of one time round fits without wrapping)
function ring(pal, backwards, standing) {
  const n = 2 * LOOP_PX;
  const w = standing ? 1 : n;
  const h = standing ? n : 1;
  const px = Buffer.alloc(n * 4);
  for (let i = 0; i < n; i++) {
    const u = (i + 0.5) / LOOP_PX;
    const rgb = pal(backwards ? -u : u);
    px[i * 4] = Math.round(rgb[0]);
    px[i * 4 + 1] = Math.round(rgb[1]);
    px[i * 4 + 2] = Math.round(rgb[2]);
    px[i * 4 + 3] = 255;
  }
  return { w, h, px };
}

// ---- PNG

const CRC = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = CRC[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}
// RGBA, 8 bits a channel
function png(c) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(c.w, 0);
  ihdr.writeUInt32BE(c.h, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  const stride = c.w * 4;
  const raw = Buffer.alloc((stride + 1) * c.h);
  for (let y = 0; y < c.h; y++) c.px.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

// ---- out

const PICTURES = [
  ['tv-glow.png', () => glowPicture(840, 480, GLOW_TV, WALL)],
  ['panel-glow.png', () => glowPicture(1248, 688, GLOW_PANEL, WALL)],
  ['row-light.png', () => rowLight(640, 72, WALL, ROW)],
  ['panel-row-light.png', () => rowLight(760, 64, PANEL, PANEL_ROW)],
  ['badge.png', badge],
  ['cap.png', cap],
  ['star.png', star],
  ['arrow-r.png', () => arrow(true)],
  ['arrow-l.png', () => arrow(false)],
];
for (const [name, pal] of Object.entries(WAYS)) {
  PICTURES.push([name + '-h.png', () => ring(pal, false, false)]);
  PICTURES.push([name + '-hr.png', () => ring(pal, true, false)]);
  PICTURES.push([name + '-v.png', () => ring(pal, false, true)]);
  PICTURES.push([name + '-vr.png', () => ring(pal, true, true)]);
}

fs.mkdirSync(OUT, { recursive: true });
let total = 0;
for (const [name, make] of PICTURES) {
  const c = make();
  const data = png(c);
  fs.writeFileSync(path.join(OUT, name), data);
  total += data.length;
  console.log(name + ': ' + c.w + ' x ' + c.h + ', ' + data.length + ' bytes');
}
console.log('all: ' + total + ' bytes');
