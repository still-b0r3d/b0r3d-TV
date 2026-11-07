// Makes b0r3d TV's sounds: app/sounds/tune.wav, the burst of TV static heard when a channel
// opens. The noise comes from a fixed seed, so every run writes the same file.
//   node tools/make-sounds.js
// 16-bit PCM, mono, 44.1 kHz WAV, the format Roku's roAudioResource plays.

const fs = require('fs');
const path = require('path');

const RATE = 44100;

// A small fixed-seed random number generator (0 to 1).
function seeded(seed) {
  let s = seed >>> 0;
  return () => {
    s = (Math.imul(s, 1664525) + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

function wav(samples) {
  const data = Buffer.alloc(samples.length * 2);
  samples.forEach((v, i) => {
    const clipped = Math.max(-1, Math.min(1, v));
    data.writeInt16LE(Math.round(clipped * 32767), i * 2);
  });
  const head = Buffer.alloc(44);
  head.write('RIFF', 0, 'latin1');
  head.writeUInt32LE(36 + data.length, 4);
  head.write('WAVE', 8, 'latin1');
  head.write('fmt ', 12, 'latin1');
  head.writeUInt32LE(16, 16);
  head.writeUInt16LE(1, 20);
  head.writeUInt16LE(1, 22);
  head.writeUInt32LE(RATE, 24);
  head.writeUInt32LE(RATE * 2, 28);
  head.writeUInt16LE(2, 32);
  head.writeUInt16LE(16, 34);
  head.write('data', 36, 'latin1');
  head.writeUInt32LE(data.length, 40);
  return Buffer.concat([head, data]);
}

// Static: noise through a soft low-pass, fluttering like a tuner, in and out quickly.
function tune() {
  const rnd = seeded(0x0b03d);
  const length = Math.round(RATE * 0.42);
  const out = new Array(length);
  let low = 0;
  for (let i = 0; i < length; i++) {
    const t = i / RATE;
    low += 0.35 * ((rnd() * 2 - 1) - low);
    const attack = Math.min(1, t / 0.01);
    const release = t > 0.3 ? Math.max(0, 1 - (t - 0.3) / 0.12) : 1;
    const flutter = 0.75 + 0.25 * Math.sin(2 * Math.PI * 25 * t);
    out[i] = low * 0.9 * attack * release * flutter;
  }
  return out;
}

const dir = path.join(__dirname, '..', 'app', 'sounds');
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'tune.wav'), wav(tune()));
console.log('wrote app/sounds/tune.wav');
