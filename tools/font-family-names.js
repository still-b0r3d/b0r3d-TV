// Gives each Barlow Condensed weight its own family name on a Roku.
//
// The Medium, SemiBold and ExtraBold files carry two family names: their own ("Barlow
// Condensed Medium", name ID 1) and the shared one ("Barlow Condensed", name ID 16, with the
// weight in name ID 17). A Roku that goes by the shared name would fold the weights into one
// family and pick among them by its bold switch alone. This drops name IDs 16 and 17, so only
// each file's own family name is left. Nothing else in the files changes.
//
//   node tools/font-family-names.js app/fonts/barlow-condensed/BarlowCondensed-Medium.ttf ...
//
// The fonts are under the SIL Open Font License 1.1, which allows changed copies under the same
// license; the files' OFL.txt declares no Reserved Font Name.

const fs = require('fs');

const DROP = new Set([16, 17]);

function pad4(n) {
  return (n + 3) & ~3;
}

function checksum(buf) {
  let sum = 0;
  const padded = Buffer.alloc(pad4(buf.length));
  buf.copy(padded);
  for (let i = 0; i < padded.length; i += 4) sum = (sum + padded.readUInt32BE(i)) >>> 0;
  return sum;
}

function readTables(font) {
  const count = font.readUInt16BE(4);
  const tables = [];
  for (let i = 0; i < count; i++) {
    const rec = 12 + i * 16;
    const tag = font.toString('latin1', rec, rec + 4);
    const offset = font.readUInt32BE(rec + 8);
    const length = font.readUInt32BE(rec + 12);
    tables.push({ tag, data: Buffer.from(font.subarray(offset, offset + length)) });
  }
  return tables;
}

// A new name table (format 0) without the dropped records.
function rebuildName(name) {
  if (name.readUInt16BE(0) !== 0) throw new Error('only name table format 0 is handled');
  const count = name.readUInt16BE(2);
  const storage = name.readUInt16BE(4);
  const kept = [];
  for (let i = 0; i < count; i++) {
    const r = 6 + i * 12;
    const rec = {
      platform: name.readUInt16BE(r),
      encoding: name.readUInt16BE(r + 2),
      language: name.readUInt16BE(r + 4),
      nameId: name.readUInt16BE(r + 6),
      length: name.readUInt16BE(r + 8),
      offset: name.readUInt16BE(r + 10)
    };
    if (!DROP.has(rec.nameId)) kept.push(rec);
  }
  const strings = [];
  let at = 0;
  for (const rec of kept) {
    const text = name.subarray(storage + rec.offset, storage + rec.offset + rec.length);
    strings.push(text);
    rec.newOffset = at;
    at += text.length;
  }
  const head = Buffer.alloc(6 + kept.length * 12);
  head.writeUInt16BE(0, 0);
  head.writeUInt16BE(kept.length, 2);
  head.writeUInt16BE(head.length, 4);
  kept.forEach((rec, i) => {
    const r = 6 + i * 12;
    head.writeUInt16BE(rec.platform, r);
    head.writeUInt16BE(rec.encoding, r + 2);
    head.writeUInt16BE(rec.language, r + 4);
    head.writeUInt16BE(rec.nameId, r + 6);
    head.writeUInt16BE(rec.length, r + 8);
    head.writeUInt16BE(rec.newOffset, r + 10);
  });
  return { data: Buffer.concat([head, ...strings]), dropped: count - kept.length };
}

function rebuildFont(font, tables) {
  const count = tables.length;
  const dirLength = 12 + count * 16;
  const out = [];
  const header = Buffer.alloc(dirLength);
  font.copy(header, 0, 0, 12);
  let offset = dirLength;
  tables.forEach((t, i) => {
    if (t.tag === 'head') t.data.writeUInt32BE(0, 8); // checkSumAdjustment is set last
    const rec = 12 + i * 16;
    header.write(t.tag, rec, 4, 'latin1');
    header.writeUInt32BE(checksum(t.data), rec + 4);
    header.writeUInt32BE(offset, rec + 8);
    header.writeUInt32BE(t.data.length, rec + 12);
    const padded = Buffer.alloc(pad4(t.data.length));
    t.data.copy(padded);
    out.push(padded);
    t.at = offset;
    offset += padded.length;
  });
  const whole = Buffer.concat([header, ...out]);
  const head = tables.find((t) => t.tag === 'head');
  whole.writeUInt32BE((0xb1b0afba - checksum(whole)) >>> 0, head.at + 8);
  return whole;
}

for (const file of process.argv.slice(2)) {
  const font = fs.readFileSync(file);
  const tables = readTables(font);
  const name = tables.find((t) => t.tag === 'name');
  const result = rebuildName(name.data);
  if (result.dropped === 0) {
    console.log(file + ': nothing to change');
    continue;
  }
  name.data = result.data;
  fs.writeFileSync(file, rebuildFont(font, tables));
  console.log(file + ': dropped ' + result.dropped + ' name records');
}
