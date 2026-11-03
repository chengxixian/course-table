/**
 * make-samples.mjs — one-shot drum samples for the REAPER v2 production.
 * Self-authored synthesis (deterministic), CC0 with the project. These are
 * loaded into ReaSamplOmatic5000 inside promo/reaper/bgm-v2.rpp.
 *
 *   node promo/reaper/make-samples.mjs
 */
import fs from "node:fs";
import path from "node:path";

const SR = 48000;
const OUT = path.resolve("promo/reaper/samples");
fs.mkdirSync(OUT, {recursive: true});

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
const writeWav = (name, L, R, peakDb = -3) => {
  let p = 1e-9;
  for (let i = 0; i < L.length; i++) p = Math.max(p, Math.abs(L[i]), Math.abs(R[i]));
  const g = Math.pow(10, peakDb / 20) / p;
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
    buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(L[i] * g * 32767))), 44 + i * 4);
    buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(R[i] * g * 32767))), 46 + i * 4);
  }
  fs.writeFileSync(path.join(OUT, name), buf);
  return (n / SR).toFixed(2) + "s";
};

const kick = () => {
  const dur = 0.5, n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(11);
  let ph = 0, lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const f = 46 + 150 * Math.exp(-t * 36);
    ph += (2 * Math.PI * f) / SR;
    const body = Math.sin(ph) * Math.exp(-t * 7.5);
    const click = (rnd() * 2 - 1) * Math.exp(-t * 420) * 0.5;
    lp += 0.2 * (click - lp);
    const v = body * 0.95 + lp * 1.4 + Math.sin(2 * Math.PI * 120 * t) * Math.exp(-t * 55) * 0.18;
    L[i] = Math.tanh(v * 1.25);
    R[i] = L[i];
  }
  return [L, R, -2.5];
};

const snare = () => {
  const dur = 0.3, n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(23);
  let hp = 0, hp2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const body = (Math.sin(2 * Math.PI * 185 * t) * 0.55 + Math.sin(2 * Math.PI * 330 * t) * 0.25) * Math.exp(-t * 28);
    const nz = rnd() * 2 - 1;
    hp += 0.32 * (nz - hp);
    hp2 += 0.18 * (hp - hp2);
    const noise = (hp - hp2 * 0.5) * Math.exp(-t * 20);
    const v = body * 0.8 + noise * 1.1;
    L[i] = v;
    R[i] = v * 0.96 + (rnd() * 2 - 1) * Math.exp(-t * 35) * 0.04;
  }
  return [L, R, -4];
};

const clap = () => {
  const dur = 0.35, n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(37);
  let hp = 0;
  const bursts = [0, 0.011, 0.023, 0.041];
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const nz = rnd() * 2 - 1;
    hp += 0.4 * (nz - hp);
    const band = nz - hp;
    let e = 0;
    for (const b of bursts) if (t >= b) e += Math.exp(-(t - b) * 180) * 0.7;
    e += Math.exp(-Math.max(0, t - 0.055) * 22) * 0.35;
    const v = band * e;
    L[i] = v;
    R[i] = band * e * 0.92 + (rnd() * 2 - 1) * e * 0.05;
  }
  return [L, R, -5];
};

const hat = (open = false) => {
  const dur = open ? 0.38 : 0.075, n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(open ? 51 : 53);
  let hp = 0, hp2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const nz = rnd() * 2 - 1;
    hp += 0.62 * (nz - hp);
    hp2 += 0.45 * (hp - hp2);
    const band = hp - hp2 * 0.6;
    const env = Math.exp(-t * (open ? 9 : 85)) * Math.min(1, t / 0.0008);
    L[i] = band * env;
    R[i] = band * env * 0.9;
  }
  return [L, R, open ? -8 : -9];
};

const crash = () => {
  const dur = 1.9, n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(67);
  let hp = 0, hp2 = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const nz = rnd() * 2 - 1;
    hp += 0.55 * (nz - hp);
    hp2 += 0.2 * (hp - hp2);
    const band = hp - hp2 * 0.5;
    const env = Math.exp(-t * 2.2) * Math.min(1, t / 0.002);
    const shimmer = Math.sin(2 * Math.PI * 5200 * t + 0.5) * 0.04 + Math.sin(2 * Math.PI * 7130 * t) * 0.03;
    L[i] = band * env + shimmer * env;
    R[i] = band * 0.94 * env + shimmer * 0.8 * env;
  }
  return [L, R, -7];
};

const tom = (base = 150) => {
  const dur = 0.55, n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(79);
  let ph = 0, lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const f = base * (0.65 + 0.35 * Math.exp(-t * 14));
    ph += (2 * Math.PI * f) / SR;
    const body = Math.sin(ph) * Math.exp(-t * 9);
    lp += 0.08 * (rnd() * 2 - 1 - lp);
    const v = body * 0.9 + lp * Math.exp(-t * 40) * 0.4;
    L[i] = v;
    R[i] = v * 0.98;
  }
  return [L, R, -5];
};

const leadGlass = () => {
  const root = 523.2511; // C5
  const dur = 2.6, n = Math.floor(SR * dur);
  const L = new Float32Array(n), R = new Float32Array(n);
  const rnd = mulberry32(97);
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const env = Math.min(1, t / 0.0025) * Math.exp(-t * 1.35);
    let s = 0;
    const parts = [[1, 1.0], [2.005, 0.42], [3.01, 0.18], [4.02, 0.08], [5.03, 0.035], [6.04, 0.015]];
    for (const [k, a] of parts) s += Math.sin(2 * Math.PI * root * k * t + k * 0.4) * a * Math.exp(-t * (0.5 + k * 0.25));
    const air = (rnd() * 2 - 1) * Math.exp(-t * 120) * 0.04;
    const v = Math.tanh((s + air) * 1.05) * env;
    L[i] = v;
    R[i] = v * 0.97;
  }
  return [L, R, -3.5];
};

const jobs = [
  ["lead-glass.wav", leadGlass()],
  ["kick.wav", kick()],
  ["snare.wav", snare()],
  ["clap.wav", clap()],
  ["hat-closed.wav", hat(false)],
  ["hat-open.wav", hat(true)],
  ["crash.wav", crash()],
  ["tom-high.wav", tom(185)],
  ["tom-low.wav", tom(110)],
];
for (const [name, [L, R, peak]] of jobs) {
  console.log(name, writeWav(name, L, R, peak));
}
