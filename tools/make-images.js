// Makes the pictures the Roku shows for b0r3d TV before the app draws anything:
//   app/images/icon_focus_fhd.png   540 x 405    the tile on the Roku home screen
//   app/images/icon_focus_hd.png    290 x 218    the same tile for HD screens
//   app/images/splash_fhd.png      1920 x 1080   shown while the app starts
//   app/images/splash_hd.png       1280 x 720    the same for HD screens
// Plain PNGs with nothing in them but the picture. Run from the repo's top folder:
//   node tools/make-images.js
'use strict';

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const NAVY = [0x0a, 0x16, 0x40];
const YELLOW = [0xff, 0xd2, 0x3f];
const WHITE = [0xff, 0xff, 0xff];

// The letters of "b0r3d TV", 5 x 7 pixels each.
const GLYPHS = {
  b: ['#....', '#....', '####.', '#...#', '#...#', '#...#', '####.'],
  '0': ['.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'],
  r: ['.....', '.....', '#.##.', '##..#', '#....', '#....', '#....'],
  '3': ['####.', '....#', '....#', '.###.', '....#', '....#', '####.'],
  d: ['....#', '....#', '.####', '#...#', '#...#', '#...#', '.####'],
  T: ['#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'],
  V: ['#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'],
};

// Rukus, loafing: the same sprite as in app/source/art.brs. A dot is clear.
const RUKUS = [
  '..k...k.........',
  '..kk.kk.........',
  '.k12121kkkkkk...',
  '.k2k1k2k212121k.',
  '.k11s11k1212121k',
  '.kkOTkkk1111111k',
  '.kVUVVUV1111111k',
  '.k111111111222kk',
  '..kkkkkkkkkkkkk.',
];
const FUR = [0x9a, 0x9a, 0xa2];
const STRIPE = [0x5c, 0x5c, 0x66];
const RUKUS_COLORS = {
  k: [0x14, 0x12, 0x1c], '1': FUR, O: FUR, T: FUR, V: FUR,
  '2': STRIPE, U: STRIPE, '3': [0xc8, 0xe0, 0x60], s: [0xe8, 0xb8, 0x90],
};

function canvas(w, h, rgb) {
  const px = Buffer.alloc(w * h * 3);
  for (let i = 0; i < w * h; i++) px.set(rgb, i * 3);
  return { w, h, px };
}

function rect(c, x, y, w, h, rgb) {
  for (let yy = Math.max(0, y); yy < Math.min(c.h, y + h); yy++) {
    for (let xx = Math.max(0, x); xx < Math.min(c.w, x + w); xx++) c.px.set(rgb, (yy * c.w + xx) * 3);
  }
}

function textWidth(str, scale) {
  return (str.length * 6 - 1) * scale;
}

function text(c, str, x, y, scale, rgb) {
  for (const ch of str) {
    GLYPHS[ch].forEach((row, r) => {
      for (let col = 0; col < row.length; col++) {
        if (row[col] === '#') rect(c, x + col * scale, y + r * scale, scale, scale, rgb);
      }
    });
    x += 6 * scale;
  }
}

function sprite(c, rows, x, y, scale) {
  rows.forEach((row, r) => {
    for (let col = 0; col < row.length; col++) {
      const rgb = RUKUS_COLORS[row[col]];
      if (rgb) rect(c, x + col * scale, y + r * scale, scale, scale, rgb);
    }
  });
}

// "b0r3d" in white with a yellow "TV" badge beside it, and Rukus underneath, centred.
function picture(w, h, s) {
  const c = canvas(w, h, NAVY);
  const logoW = textWidth('b0r3d', s.logo);
  const logoH = 7 * s.logo;
  const badgeW = textWidth('TV', s.badge) + 2 * s.pad;
  const badgeH = 7 * s.badge + 2 * s.pad;
  const rukusW = 16 * s.rukus;
  const rukusH = 9 * s.rukus;
  const top = Math.round((h - (logoH + s.gap + rukusH)) / 2);
  const left = Math.round((w - (logoW + s.space + badgeW)) / 2);
  text(c, 'b0r3d', left, top, s.logo, WHITE);
  const bx = left + logoW + s.space;
  const by = top + Math.round((logoH - badgeH) / 2);
  rect(c, bx, by, badgeW, badgeH, YELLOW);
  text(c, 'TV', bx + s.pad, by + s.pad, s.badge, NAVY);
  sprite(c, RUKUS, Math.round((w - rukusW) / 2), top + logoH + s.gap, s.rukus);
  return c;
}

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let v = n;
    for (let k = 0; k < 8; k++) v = v & 1 ? 0xedb88320 ^ (v >>> 1) : v >>> 1;
    t[n] = v >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let v = 0xffffffff;
  for (const b of buf) v = CRC_TABLE[(v ^ b) & 0xff] ^ (v >>> 8);
  return (v ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

// An 8-bit RGB PNG: the header, the pixels and the end, nothing else.
function png(c) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(c.w, 0);
  ihdr.writeUInt32BE(c.h, 4);
  ihdr[8] = 8;
  ihdr[9] = 2;
  const stride = c.w * 3;
  const raw = Buffer.alloc((stride + 1) * c.h);
  for (let y = 0; y < c.h; y++) c.px.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

const OUT = path.join(__dirname, '..', 'app', 'images');
const PICTURES = [
  ['icon_focus_fhd.png', 540, 405, { logo: 12, badge: 7, pad: 12, space: 18, gap: 50, rukus: 9 }],
  ['icon_focus_hd.png', 290, 218, { logo: 6, badge: 4, pad: 6, space: 9, gap: 26, rukus: 5 }],
  ['splash_fhd.png', 1920, 1080, { logo: 20, badge: 12, pad: 20, space: 30, gap: 90, rukus: 14 }],
  ['splash_hd.png', 1280, 720, { logo: 13, badge: 8, pad: 13, space: 20, gap: 60, rukus: 9 }],
];

fs.mkdirSync(OUT, { recursive: true });
for (const [name, w, h, sizes] of PICTURES) {
  const data = png(picture(w, h, sizes));
  fs.writeFileSync(path.join(OUT, name), data);
  console.log(name + ': ' + w + ' x ' + h + ', ' + data.length + ' bytes');
}
