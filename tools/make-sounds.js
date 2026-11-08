// Makes b0r3d TV's sounds: app/sounds/tune.wav, the burst of TV static heard when a channel
// opens, Stuck Pixels' effects (app/sounds/sp-*.wav): a turn, putting a piece on hold, a piece
// setting, a line, three lines or more, a stuck pixel popping, a new level, the screen losing
// its signal and a finished run, and Test Pattern's (app/sounds/tp-*.wav): the ball off the
// paddle, a brick, a bomb, a capsule caught, a ball lost and a wall cleared. The noise comes
// from fixed seeds, so every run writes the same files.
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

// --- Stuck Pixels ---

// A quick rise, then a fall to nothing by the end.
function envelope(t, attack, length) {
  if (t < attack) return t / attack;
  const left = Math.max(0, 1 - (t - attack) / (length - attack));
  return left * left;
}

// One voice: its pitch can move (f is a function of time), with a little of the third
// harmonic when bright, for a brighter, game-like tone.
function voice(length, f, gain, attack, bright) {
  const n = Math.round(RATE * length);
  const out = new Array(n);
  let phase = 0;
  for (let i = 0; i < n; i++) {
    const t = i / RATE;
    phase += (2 * Math.PI * f(t)) / RATE;
    let v = Math.sin(phase);
    if (bright) v = 0.8 * v + 0.25 * Math.sin(3 * phase);
    out[i] = v * gain * envelope(t, attack, length);
  }
  return out;
}

// Notes one after another: [frequency, seconds] each.
function notes(list, gain, bright) {
  let out = [];
  for (const [freq, length] of list) out = out.concat(voice(length, () => freq, gain, 0.004, bright));
  return out;
}

// Soft noise, low-passed by smooth (0 to 1, smaller is darker), fading out over length.
function hiss(seed, length, gain, smooth) {
  const rnd = seeded(seed);
  const n = Math.round(RATE * length);
  const out = new Array(n);
  let low = 0;
  for (let i = 0; i < n; i++) {
    const t = i / RATE;
    low += smooth * ((rnd() * 2 - 1) - low);
    out[i] = low * gain * envelope(t, 0.004, length);
  }
  return out;
}

// Adds b into a, starting at seconds.
function mixIn(a, b, seconds) {
  const start = Math.round(RATE * (seconds || 0));
  const out = a.slice();
  for (let i = 0; i < b.length; i++) out[start + i] = (out[start + i] || 0) + b[i];
  return out;
}

const stuck = {
  // a turn: a short bright blip that rises a little
  turn: () => voice(0.05, (t) => 880 + 4000 * t, 0.42, 0.003, true),
  // on hold: a soft swish under a falling note
  hold: () => mixIn(hiss(0x401d, 0.09, 0.5, 0.25), voice(0.09, (t) => 520 - 1400 * t, 0.3, 0.004, false)),
  // a piece sets: a low thud with a tap of noise on top
  lock: () => mixIn(voice(0.09, (t) => 150 - 500 * t, 0.7, 0.002, false), hiss(0x10c, 0.012, 0.35, 0.6)),
  // a line: three notes going up
  clear: () => notes([[1047, 0.055], [1319, 0.055], [1568, 0.08]], 0.42, true),
  // three lines or more: five notes and a shimmer
  big: () => mixIn(notes([[1047, 0.045], [1319, 0.045], [1568, 0.045], [2093, 0.045], [2637, 0.12]], 0.4, true), hiss(0xb16, 0.2, 0.18, 0.9), 0.12),
  // a stuck pixel pops: a fast chirp up and a crackle of sparks
  fix: () => mixIn(voice(0.07, (t) => 600 + 26000 * t, 0.5, 0.002, false), hiss(0xf1c5, 0.13, 0.35, 0.95), 0.05),
  // a new level: two notes, low then high
  level: () => notes([[784, 0.12], [1175, 0.22]], 0.45, true),
  // the well's screen loses its signal: static, and a whine falling away
  over: () => mixIn(hiss(0x0ff, 0.75, 0.6, 0.35), voice(0.75, (t) => 1600 * Math.pow(0.12, t / 0.75), 0.3, 0.01, false)),
  // a finished run: a little run of notes up, the last one held
  done: () => notes([[784, 0.1], [1047, 0.1], [1319, 0.1], [1568, 0.32]], 0.42, true)
};

// --- Test Pattern ---

const test = {
  // the ball off the paddle: a soft, low bop
  paddle: () => voice(0.06, (t) => 330 + 400 * t, 0.5, 0.002, false),
  // a brick: a short bright tink
  brick: () => voice(0.04, () => 1046, 0.32, 0.002, true),
  // a bomb: a burst of static over a low thud
  bomb: () => mixIn(hiss(0xb0b, 0.3, 0.65, 0.3), voice(0.25, (t) => 120 - 200 * t, 0.6, 0.003, false)),
  // a capsule caught: two notes up
  catch: () => notes([[880, 0.07], [1320, 0.12]], 0.42, true),
  // a ball lost: a tone falling away
  lost: () => voice(0.45, (t) => 600 * Math.pow(0.3, t / 0.45), 0.42, 0.005, true),
  // a wall cleared: a quick run of notes up
  clear: () => notes([[784, 0.06], [988, 0.06], [1175, 0.06], [1568, 0.2]], 0.42, true)
};

const dir = path.join(__dirname, '..', 'app', 'sounds');
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, 'tune.wav'), wav(tune()));
console.log('wrote app/sounds/tune.wav');
for (const name of Object.keys(stuck)) {
  fs.writeFileSync(path.join(dir, 'sp-' + name + '.wav'), wav(stuck[name]()));
  console.log('wrote app/sounds/sp-' + name + '.wav');
}
for (const name of Object.keys(test)) {
  fs.writeFileSync(path.join(dir, 'tp-' + name + '.wav'), wav(test[name]()));
  console.log('wrote app/sounds/tp-' + name + '.wav');
}
