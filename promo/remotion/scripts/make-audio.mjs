/**
 * Deterministic audio for the promo: ambient bed + foley SFX.
 * Everything is synthesized here (no external samples), so the film ships
 * license-clean audio: self-authored, CC0-dedicated in the project.
 *
 *   node scripts/make-audio.mjs
 */
import fs from "node:fs";
import path from "node:path";

const SR = 48000;
const OUT = path.resolve("public/audio/sfx");
const OUT_BGM = path.resolve("public/audio/bgm");
fs.mkdirSync(OUT, {recursive: true});
fs.mkdirSync(OUT_BGM, {recursive: true});

/* ---------- deterministic noise ---------- */
const mulberry32 = (seed) => {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};

const writeWav = (file, L, R) => {
  const n = L.length;
  const buf = Buffer.alloc(44 + n * 4);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + n * 4, 4);
  buf.write("WAVE", 8);
  buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);
  buf.writeUInt16LE(2, 22);
  buf.writeUInt32LE(SR, 24);
  buf.writeUInt32LE(SR * 4, 28);
  buf.writeUInt16LE(4, 32);
  buf.writeUInt16LE(16, 34);
  buf.write("data", 36);
  buf.writeUInt32LE(n * 4, 40);
  for (let i = 0; i < n; i++) {
    buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(L[i] * 32767))), 44 + i * 4);
    buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(R[i] * 32767))), 46 + i * 4);
  }
  fs.writeFileSync(file, buf);
};

const norm = (L, R, peakDb = -3) => {
  let p = 1e-9;
  for (let i = 0; i < L.length; i++) p = Math.max(p, Math.abs(L[i]), Math.abs(R[i]));
  const g = Math.pow(10, peakDb / 20) / p;
  for (let i = 0; i < L.length; i++) {
    L[i] *= g;
    R[i] *= g;
  }
  return {L, R, gain: g};
};

const env = (i, n, a = 0.005, d = 0.02, s = 0.2) => {
  const t = i / n;
  const at = Math.min(1, t / a);
  const dt = Math.min(1, (1 - t) / d);
  return Math.min(at, dt) * (1 - s + s * Math.min(1, t * 20));
};

/* ---------- one-pole low-pass ---------- */
const lp = (x, coef, state) => {
  state.y = state.y + coef * (x - state.y);
  return state.y;
};

/* ---------- SFX ---------- */
const sfxPaper = () => {
  const n = Math.floor(SR * 0.34);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(11);
  const stL = {y: 0}, stR = {y: 0};
  for (let i = 0; i < n; i++) {
    const t = i / n;
    const cut = 0.05 + 0.32 * Math.sin(Math.PI * t); // opens then closes
    const nz = rnd() * 2 - 1;
    const e = Math.sin(Math.PI * Math.pow(t, 0.7));
    L[i] = lp(nz, cut, stL) * e * 0.9;
    R[i] = lp(rnd() * 2 - 1, cut * 0.92, stR) * e * 0.9;
  }
  return norm(L, R, -8);
};

const sfxStamp = () => {
  const n = Math.floor(SR * 0.26);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(23);
  const stL = {y: 0}, stR = {y: 0};
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const thump = Math.sin(2 * Math.PI * (128 - 60 * t) * t) * Math.exp(-t * 26);
    const click = (rnd() * 2 - 1) * Math.exp(-t * 190) * 0.5;
    const body = lp(rnd() * 2 - 1, 0.09, stL) * Math.exp(-t * 34) * 0.5;
    L[i] = thump * 0.9 + click * 0.5 + body;
    R[i] = Math.sin(2 * Math.PI * (128 - 60 * t) * (t + 0.0004)) * Math.exp(-t * 26) * 0.9 + click * 0.45 + lp(rnd() * 2 - 1, 0.09, stR) * Math.exp(-t * 34) * 0.5;
  }
  return norm(L, R, -6);
};

const sfxPop = () => {
  const n = Math.floor(SR * 0.16);
  const L = new Float32Array(n), R = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const f = 360 + 900 * t;
    const s = Math.sin(2 * Math.PI * f * t) * Math.exp(-t * 30);
    L[i] = s;
    R[i] = s * 0.96;
  }
  return norm(L, R, -10);
};

const sfxKey = () => {
  const n = Math.floor(SR * 0.05);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(31);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const e = Math.exp(-t * 240);
    const ping = Math.sin(2 * Math.PI * 2100 * t) * 0.5 + Math.sin(2 * Math.PI * 3300 * t) * 0.2;
    const tick = (rnd() * 2 - 1) * 0.5;
    L[i] = (ping + tick) * e;
    R[i] = (ping * 0.9 + tick * 0.6) * e;
  }
  return norm(L, R, -12);
};

const sfxSwish = () => {
  const n = Math.floor(SR * 0.5);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(41);
  const stL = {y: 0}, stR = {y: 0};
  for (let i = 0; i < n; i++) {
    const t = i / n;
    const cut = 0.3 - 0.22 * t;
    const e = Math.sin(Math.PI * Math.pow(t, 0.55)) ** 2;
    L[i] = lp(rnd() * 2 - 1, cut, stL) * e;
    R[i] = lp(rnd() * 2 - 1, cut * 0.97, stR) * e;
  }
  return norm(L, R, -11);
};

const sfxSnap = () => {
  const n = Math.floor(SR * 0.09);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(53);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const e = Math.exp(-t * 150);
    const wood = Math.sin(2 * Math.PI * 780 * t) * 0.6 + Math.sin(2 * Math.PI * 1560 * t) * 0.25;
    const click = (rnd() * 2 - 1) * 0.35;
    L[i] = (wood + click) * e;
    R[i] = (wood * 0.95 + click * 0.8) * e;
  }
  return norm(L, R, -9);
};

const sfxChime = () => {
  const n = Math.floor(SR * 1.6);
  const L = new Float32Array(n), R = new Float32Array(n);
  const base = 660;
  const parts = [
    [1, 1, 1.5],
    [2.01, 0.45, 2.4],
    [3.02, 0.22, 3.2],
    [4.5, 0.1, 4.0],
  ];
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    let s = 0;
    for (const [m, a, d] of parts) s += Math.sin(2 * Math.PI * base * m * t) * a * Math.exp(-t * d);
    const e = Math.min(1, t / 0.004);
    L[i] = s * e;
    R[i] = s * Math.exp(-t * 0.2) * e;
  }
  return norm(L, R, -12);
};

const sfxRiser = () => {
  const n = Math.floor(SR * 1.7);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(67);
  const stL = {y: 0}, stR = {y: 0};
  for (let i = 0; i < n; i++) {
    const t = i / n;
    const cut = 0.02 + 0.4 * Math.pow(t, 2.2);
    const e = Math.pow(t, 2.4) * 0.9;
    const s = lp(rnd() * 2 - 1, cut, stL) * e;
    L[i] = s + Math.sin(2 * Math.PI * (180 + 520 * t * t) * (i / SR)) * 0.06 * Math.pow(t, 3);
    R[i] = lp(rnd() * 2 - 1, cut * 0.95, stR) * e + Math.sin(2 * Math.PI * (180 + 520 * t * t) * (i / SR) + 0.4) * 0.06 * Math.pow(t, 3);
  }
  return norm(L, R, -12);
};

const sfxImpact = () => {
  const n = Math.floor(SR * 0.9);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(79);
  const stL = {y: 0}, stR = {y: 0};
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const sub = Math.sin(2 * Math.PI * (72 - 20 * t) * t) * Math.exp(-t * 6);
    const nz = lp(rnd() * 2 - 1, 0.06, stL) * Math.exp(-t * 9) * 0.5;
    L[i] = sub * 0.9 + nz;
    R[i] = Math.sin(2 * Math.PI * (72 - 20 * t) * (t + 0.0006)) * Math.exp(-t * 6) * 0.9 + lp(rnd() * 2 - 1, 0.06, stR) * Math.exp(-t * 9) * 0.5;
  }
  return norm(L, R, -6);
};

/* ---------- ambient bed: soft piano + pad, 41s ---------- */
const makeBed = () => {
  const dur = 41;
  const n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(101);

  const notes = [
    // [time, midi, amp]
    [0.6, 62, 0.5],
    [2.4, 69, 0.32],
    [4.9, 66, 0.34],
    [7.2, 62, 0.3],
    [9.6, 57, 0.36],
    [12.2, 64, 0.34],
    [14.6, 69, 0.3],
    [17.0, 66, 0.3],
    [19.4, 62, 0.34],
    [21.8, 59, 0.3],
    [24.2, 64, 0.32],
    [26.9, 71, 0.26],
    [29.3, 69, 0.3],
    [31.8, 66, 0.3],
    [34.2, 62, 0.34],
    [36.6, 69, 0.28],
  ];
  const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);

  // piano-ish pluck
  for (const [t0, m, amp] of notes) {
    const f = midi(m);
    const start = Math.floor(t0 * SR);
    const len = Math.floor(SR * 3.2);
    for (let i = 0; i < len; i++) {
      const idx = start + i;
      if (idx >= n) break;
      const t = i / SR;
      const e = Math.exp(-t * 1.5) * Math.min(1, t / 0.006);
      const s =
        Math.sin(2 * Math.PI * f * t) * 0.62 +
        Math.sin(2 * Math.PI * f * 2.002 * t) * 0.22 * Math.exp(-t * 2.2) +
        Math.sin(2 * Math.PI * f * 3.01 * t) * 0.1 * Math.exp(-t * 3.4) +
        Math.sin(2 * Math.PI * f * 0.5 * t) * 0.1 * Math.exp(-t * 1.1);
      const pan = 0.5 + 0.12 * Math.sin(t0);
      L[idx] += s * e * amp * (1 - pan);
      R[idx] += s * e * amp * pan;
    }
  }

  // pad: two slow chords, very quiet
  const padChords = [
    [0, 38, [50, 57, 62, 66]], // D2 + Dmaj9-ish
    [20.5, 38, [47, 54, 59, 62]],
  ];
  for (const [t0, , chord] of padChords) {
    const start = Math.floor(t0 * SR);
    const len = Math.floor(SR * 21);
    for (let i = 0; i < len; i++) {
      const idx = start + i;
      if (idx >= n) break;
      const t = i / SR;
      const sway = 0.6 + 0.4 * Math.sin(2 * Math.PI * 0.06 * t + t0);
      const fade = Math.min(1, t / 3.5) * Math.min(1, (21 - t) / 4);
      let s = 0;
      for (const [k, m] of chord.entries()) {
        const f = midi(m);
        const detune = 1 + (k % 2 === 0 ? 0.0012 : -0.0012);
        s += Math.sin(2 * Math.PI * f * detune * t + k) * 0.16;
      }
      L[idx] += s * fade * sway * 0.5;
      R[idx] += s * fade * (1.2 - sway) * 0.5;
    }
  }

  // sub drone
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const fade = Math.min(1, t / 2.5) * Math.min(1, (dur - t) / 3);
    const s = Math.sin(2 * Math.PI * 36.7 * t) * 0.05 * fade;
    L[i] += s;
    R[i] += s;
  }

  // air / room tone
  const stL = {y: 0}, stR = {y: 0};
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const fade = Math.min(1, t / 2) * Math.min(1, (dur - t) / 3);
    L[i] += lp(rnd() * 2 - 1, 0.02, stL) * 0.05 * fade;
    R[i] += lp(rnd() * 2 - 1, 0.02, stR) * 0.05 * fade;
  }

  // gentle master fade in/out
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const g = Math.min(1, t / 1.2) * Math.min(1, (dur - t) / 2.2);
    L[i] *= g;
    R[i] *= g;
  }
  return norm(L, R, -3);
};

/* ---------- write ---------- */
const jobs = [
  ["bed-paper-piano.wav", makeBed(), OUT_BGM],
  ["paper-slide.wav", sfxPaper(), OUT],
  ["stamp.wav", sfxStamp(), OUT],
  ["pop.wav", sfxPop(), OUT],
  ["key.wav", sfxKey(), OUT],
  ["swish.wav", sfxSwish(), OUT],
  ["snap.wav", sfxSnap(), OUT],
  ["chime.wav", sfxChime(), OUT],
  ["riser.wav", sfxRiser(), OUT],
  ["impact.wav", sfxImpact(), OUT],
];

for (const [name, {L, R}, dir] of jobs) {
  writeWav(path.join(dir, name), L, R);
  console.log("wrote", path.join(dir, name), (L.length / SR).toFixed(2) + "s");
}
