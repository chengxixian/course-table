/**
 * make-bgm.mjs — original 40.0 s BGM for the 课程表 promo.
 *
 * Everything is synthesised here from deterministic maths (mulberry32 seeds):
 * no samples, no external assets, no network. Self-authored and CC0-dedicated
 * with the project, same policy as the film's foley (scripts/make-audio.mjs).
 *
 *   node promo/audio/make-bgm.mjs
 *
 * Musical design
 * --------------
 * 120 BPM, 4/4, D major with modal colour. At 120 BPM one beat is 15 video
 * frames, so every shot boundary (150/390/540/750/930/1080/1200) lands on a
 * beat and 1200 frames = exactly 80 beats = 20 bars.
 *
 *   S1 OPEN     0-150   bars 0-2.5   pad + felt piano + soft clock ticks
 *   S2 WEEK   150-390   bars 2.5-6.5 gentle shaker/bass lift, no hard drums
 *   S3 DETAIL 390-540   bars 6.5-9   drums out, warm low string + piano
 *   S4 IMPORT 540-750   bars 9-12.5  clear soft groove (kick/shaker/bass)
 *   S5 DRAG   750-930   bars 12.5-15.5 lift, suck, snap accent at frame 800
 *   S6 WIDGETS930-1080  bars 15.5-18  light precise groove, rising figure
 *   S7 OUTRO 1080-1200  bars 18-20   A7 rise -> impact 1126 -> D resolution
 *                                    1142 -> ring, fade to silence by 1200
 */
import fs from "node:fs";
import path from "node:path";

/* ------------------------------------------------------------------ setup */
const SR = 48000;
const DUR = 40.0;
const N = Math.round(SR * DUR);
const BPM = 120;
const BEAT = 60 / BPM; // 0.5 s
const BAR = BEAT * 4; // 2.0 s
const FPS = 30;
const FRAMES = 1200;
const at = (frame) => frame / FPS; // authored frame -> seconds

const OUT_DIR = path.resolve("promo/audio");
fs.mkdirSync(OUT_DIR, {recursive: true});

/* ------------------------------------------------------- deterministic rng */
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

/* --------------------------------------------------------------- utilities */
const midi = (m) => 440 * Math.pow(2, (m - 69) / 12);
const clamp = (v, a, b) => (v < a ? a : v > b ? b : v);
const smooth = (x) => {
  const t = clamp(x, 0, 1);
  return t * t * (3 - 2 * t);
};
const panGains = (p) => {
  const a = ((clamp(p, -1, 1) + 1) * Math.PI) / 4;
  return {l: Math.cos(a), r: Math.sin(a)};
};

const dry = {L: new Float32Array(N), R: new Float32Array(N)};
const send = {L: new Float32Array(N), R: new Float32Array(N)};

/**
 * Mix balance. Sustained layers carry the body; transient layers sit under the
 * film's foley, which owns the actual hit points. Tuned numerically against
 * integrated loudness / true peak; see docs/promo/07-bgm.md.
 */
const BAL = {
  pad: 1.28,
  cello: 1.1,
  piano: 1.32,
  glass: 1.26,
  bass: 1.18,
  kick: 0.74,
  shaker: 0.92,
  tick: 0.8,
  timpani: 0.82,
  snap: 0.9,
  impact: 0.8,
  air: 1.0,
};

const put = (bus, idx, v, gl, gr) => {
  bus.L[idx] += v * gl;
  bus.R[idx] += v * gr;
};

/* Wavetable oscillators (cheap, band-limited by construction). */
const TABLE = 4096;
const makeTable = (partials) => {
  const t = new Float64Array(TABLE + 1);
  for (const [k, amp, phase] of partials) {
    for (let i = 0; i <= TABLE; i++) {
      t[i] += amp * Math.sin((2 * Math.PI * k * i) / TABLE + phase);
    }
  }
  let p = 0;
  for (let i = 0; i < TABLE; i++) p = Math.max(p, Math.abs(t[i]));
  for (let i = 0; i <= TABLE; i++) t[i] /= p || 1;
  return t;
};
const tableRead = (tab, ph) => {
  const p = ph - Math.floor(ph);
  const x = p * TABLE;
  const i = x | 0;
  const f = x - i;
  return tab[i] + (tab[i + 1] - tab[i]) * f;
};
const harmonics = (n, slope, oddOnly = false) => {
  const out = [];
  for (let k = 1; k <= n; k++) {
    if (oddOnly && k % 2 === 0) continue;
    out.push([k, 1 / Math.pow(k, slope), 0]);
  }
  return out;
};

const PAD_TABLE = makeTable(harmonics(14, 1.28));
const CELLO_TABLE = makeTable(harmonics(9, 1.05, true));

/* ------------------------------------------------------------ instruments */
let noteSeed = 1;
const nextSeed = () => (noteSeed += 7919);

/** Felt-piano / prepared-piano pluck. amp is a musical velocity 0..1. */
const piano = (t0, m, amp, dur = 3.2, pan = 0, opts = {}) => {
  const rng = mulberry32(nextSeed() + m);
  const f = midi(m) * (1 + (rng() - 0.5) * 0.0007);
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(dur * SR), N - start);
  if (n <= 0) return;
  const g = amp * (opts.gain ?? 0.22) * BAL.piano;
  const p = panGains(pan);
  const bright = opts.bright ?? 0.55;
  const parts = [
    [1, 1.0, 1.05, 0],
    [2.002, 0.44 * bright, 1.9, 0.3],
    [3.006, 0.2 * bright, 2.8, 0.7],
    [4.013, 0.09 * bright, 3.7, 1.1],
    [5.02, 0.045 * bright, 4.6, 0.4],
    [6.03, 0.02 * bright, 5.6, 0.9],
  ];
  const rnd = mulberry32(nextSeed() + m * 3);
  let lp = 0;
  const sendAmt = 0.36;
  const len = Math.min(n, Math.round(3.4 * SR));
  for (let i = 0; i < len; i++) {
    const t = i / SR;
    const attack = smooth(t / 0.004);
    const body = 0.72 * Math.exp(-t * 1.08) + 0.28 * Math.exp(-t * 0.42);
    let s = 0;
    for (const [k, a, dec, ph] of parts) {
      s += Math.sin(2 * Math.PI * f * k * t + ph) * a * Math.exp(-t * dec * 0.32);
    }
    lp += 0.06 * (rnd() * 2 - 1 - lp);
    const hammer = lp * Math.exp(-t * 90) * 0.5;
    const v = (s * (attack * body) + hammer) * g;
    const tail = smooth((len / SR - t) / 0.25);
    put(dry, start + i, v * tail, p.l, p.r);
    put(send, start + i, v * tail * sendAmt, 0.72, 0.72);
  }
};

/** Glass / music-box pluck for the upper register. */
const glass = (t0, m, amp, dur = 1.6, pan = 0) => {
  const f = midi(m);
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(dur * SR), N - start);
  if (n <= 0) return;
  const g = amp * 0.15 * BAL.glass;
  const p = panGains(pan);
  const parts = [
    [1, 1.0, 2.1, 0],
    [2.0, 0.3, 3.3, 0.5],
    [3.0, 0.11, 4.6, 1.2],
    [4.0, 0.045, 6.2, 0.2],
    [5.01, 0.018, 8.0, 0.8],
  ];
  const len = Math.min(n, Math.round(2.2 * SR));
  for (let i = 0; i < len; i++) {
    const t = i / SR;
    let s = 0;
    for (const [k, a, dec, ph] of parts) {
      s += Math.sin(2 * Math.PI * f * k * t + ph) * a * Math.exp(-t * dec);
    }
    const env = smooth(t / 0.0025);
    const v = s * env * g;
    const tail = smooth((len / SR - t) / 0.2);
    put(dry, start + i, v * tail, p.l, p.r);
    put(send, start + i, v * tail * 0.5, 0.8, 0.8);
  }
};

/** Warm analogue-ish pad note (wavetable + one-pole low-pass). */
const padNote = (t0, dur, m, amp, cutoff, pan = 0, attack = 0.45, release = 1.1, table = PAD_TABLE, gainMul = BAL.pad) => {
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(dur * SR), N - start);
  if (n <= 0) return;
  const f = midi(m);
  const p = panGains(pan);
  const incs = [(f * 0.9991) / SR, (f * 1.0009) / SR];
  const ph = [0.0, 0.31];
  const coef = 1 - Math.exp((-2 * Math.PI * cutoff) / SR);
  const lp = [0, 0];
  const g = amp * gainMul;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const env = smooth(t / attack) * smooth((dur - t) / release);
    let s = 0;
    for (let k = 0; k < 2; k++) {
      ph[k] += incs[k];
      const raw = tableRead(table, ph[k]);
      lp[k] += coef * (raw - lp[k]);
      s += lp[k];
    }
    s *= 0.5;
    s *= 1 + 0.055 * Math.sin(2 * Math.PI * 0.071 * t + m * 0.7);
    const v = s * env * g;
    put(dry, start + i, v, p.l, p.r);
    put(send, start + i, v * 0.3, 0.7, 0.7);
  }
};

/** Plucked warm bass (sine + harmonics, soft saturation). */
const bass = (t0, m, amp, dur = 0.9, pan = 0) => {
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(dur * SR), N - start);
  if (n <= 0) return;
  const f = midi(m);
  const p = panGains(pan);
  const g = amp * 0.2 * BAL.bass;
  const len = Math.min(n, Math.round((dur + 0.18) * SR));
  for (let i = 0; i < len; i++) {
    const t = i / SR;
    const env = smooth(t / 0.006) * (0.55 + 0.45 * Math.exp(-t * 3.2)) * smooth((dur + 0.18 - t) / 0.16);
    let s =
      Math.sin(2 * Math.PI * f * t) * 1.0 +
      Math.sin(2 * Math.PI * f * 2 * t + 0.2) * 0.24 +
      Math.sin(2 * Math.PI * f * 3 * t + 0.5) * 0.06;
    s = Math.tanh(s * 1.25) / 1.25;
    const v = s * env * g;
    put(dry, start + i, v, p.l, p.r);
    put(send, start + i, v * 0.06, 0.7, 0.7);
  }
};

/** Soft long low string under the intimate section. */
const sustainedLow = (t0, dur, m, amp, cutoff = 420, pan = 0) => {
  padNote(t0, dur, m, amp, cutoff, pan, 0.7, 1.4, CELLO_TABLE, BAL.cello);
};

/** Kick: low sine with a pitch drop and a quiet beater. */
const kick = (t0, amp, pan = 0) => {
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(0.34 * SR), N - start);
  if (n <= 0) return;
  const p = panGains(pan);
  const rng = mulberry32(nextSeed());
  let phase = 0;
  let lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const f = 47 + 86 * Math.exp(-t * 34);
    phase += (2 * Math.PI * f) / SR;
    const body = Math.sin(phase) * Math.exp(-t * 7.2);
    lp += 0.09 * (rng() * 2 - 1 - lp);
    const beater = lp * Math.exp(-t * 150) * 0.9;
    const v = (body + beater) * amp * 0.9 * BAL.kick * smooth((0.34 - t) / 0.03);
    put(dry, start + i, v, p.l, p.r);
    put(send, start + i, v * 0.08, 0.6, 0.6);
  }
};

/** Shaker / brush: band-limited noise burst. */
const shaker = (t0, amp, pan = 0.25, dur = 0.11) => {
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(dur * SR), N - start);
  if (n <= 0) return;
  const p = panGains(pan);
  const rng = mulberry32(nextSeed());
  let hp = 0;
  let lp1 = 0;
  let lp2 = 0;
  const g = amp * 0.11 * BAL.shaker;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const nz = rng() * 2 - 1;
    hp += 0.14 * (nz - hp);
    const hi = nz - hp;
    lp1 += 0.42 * (hi - lp1);
    lp2 += 0.42 * (lp1 - lp2); // second pole: keeps brushes out of the air band
    const env = smooth(t / 0.004) * Math.exp(-t * 58);
    const v = lp2 * env * g;
    put(dry, start + i, v, p.l, p.r);
    put(send, start + i, v * 0.08, 0.6, 0.6);
  }
};

/** Wood / clock tick. */
const tick = (t0, amp, f = 1400, pan = 0) => {
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(0.07 * SR), N - start);
  if (n <= 0) return;
  const p = panGains(pan);
  const rng = mulberry32(nextSeed());
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const env = smooth(t / 0.0015) * Math.exp(-t * 82);
    const s = Math.sin(2 * Math.PI * f * t) * 0.8 + (rng() * 2 - 1) * 0.18 * Math.exp(-t * 300);
    const v = s * env * amp * 0.07 * BAL.tick;
    put(dry, start + i, v, p.l, p.r);
    put(send, start + i, v * 0.12, 0.6, 0.6);
  }
};

/** Tuned low drum (timpani-ish) for the outro rise. */
const timpani = (t0, amp, m = 45, pan = 0) => {
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round(0.75 * SR), N - start);
  if (n <= 0) return;
  const f = midi(m);
  const p = panGains(pan);
  const rng = mulberry32(nextSeed());
  let lp = 0;
  for (let i = 0; i < n; i++) {
    const t = i / SR;
    const bend = 1 - 0.025 * Math.min(1, t / 0.12);
    const body = Math.sin(2 * Math.PI * f * bend * t) * Math.exp(-t * 4.2);
    lp += 0.05 * (rng() * 2 - 1 - lp);
    const v = (body * 0.9 + lp * Math.exp(-t * 12) * 0.25) * amp * BAL.timpani *
      smooth(t / 0.004) * smooth((0.75 - t) / 0.12);
    put(dry, start + i, v, p.l, p.r);
    put(send, start + i, v * 0.28, 0.7, 0.7);
  }
};

/** Filtered noise swell used for the pre-snap suck. */
const noiseSwell = (t0, t1, amp, f0, f1, panSpread = 0.4, seed = 900) => {
  const start = Math.round(t0 * SR);
  const n = Math.min(Math.round((t1 - t0) * SR), N - start);
  if (n <= 0) return;
  const rng = mulberry32(seed);
  let lpL = 0, lpR = 0;
  const gl = panGains(-panSpread * 0.5).l;
  const gr = panGains(panSpread * 0.5).r;
  for (let i = 0; i < n; i++) {
    const t = i / n;
    const fc = f0 * Math.pow(f1 / f0, Math.pow(t, 1.6));
    const a = 1 - Math.exp((-2 * Math.PI * fc) / SR);
    const nl = rng() * 2 - 1;
    const nr = rng() * 2 - 1;
    lpL += a * (nl - lpL);
    lpR += a * (nr - lpR);
    const env = Math.pow(t, 2.1) * smooth((1 - t) / 0.06);
    put(dry, start + i, lpL * env * amp * 0.5, gl, gr);
    put(send, start + i, lpR * env * amp * 0.4, 0.7, 0.7);
  }
};

/* ------------------------------------------------------------ harmony map */
/** One chord per 2 s bar; bars 0-19 cover 0-40 s. */
const CHORDS = [
  {name: "Dmaj9", bass: 38, pad: [50, 57, 61, 64, 66]},
  {name: "Bm7", bass: 47, pad: [54, 57, 59, 62]},
  {name: "Gmaj7", bass: 43, pad: [55, 59, 62, 66]},
  {name: "A7sus4", bass: 45, pad: [57, 62, 64, 67]},
  {name: "F#m7", bass: 42, pad: [54, 57, 61, 64]},
  {name: "Bm7", bass: 47, pad: [54, 57, 59, 62]},
  {name: "Gmaj7", bass: 43, pad: [55, 59, 62, 66]},
  {name: "A7sus4", bass: 45, pad: [57, 62, 64, 67]},
  {name: "Dmaj9/F#", bass: 42, pad: [57, 61, 64, 66]},
  {name: "Bm7", bass: 47, pad: [54, 57, 59, 62]},
  {name: "Gmaj7", bass: 43, pad: [55, 59, 62, 66]},
  {name: "A7", bass: 45, pad: [57, 61, 64, 67]},
  {name: "F#m7", bass: 42, pad: [54, 57, 61, 64]},
  {name: "Bm7", bass: 47, pad: [54, 57, 59, 62]},
  {name: "Em7", bass: 40, pad: [52, 55, 59, 62]},
  {name: "A7sus4", bass: 45, pad: [57, 62, 64, 67]},
  {name: "Gmaj7", bass: 43, pad: [55, 59, 62, 66]},
  {name: "A7sus4", bass: 45, pad: [57, 62, 64, 67]},
  {name: "A7", bass: 45, pad: [57, 61, 64, 67]},
  {name: "Dmaj9", bass: 38, pad: [50, 57, 61, 64, 66]},
];
const chordAt = (t) => CHORDS[clamp(Math.floor(t / BAR), 0, 19)];

/* ------------------------------------------------------------------- pads */
const PAD_AMP = [0.055, 0.062, 0.058, 0.06, 0.06, 0.064, 0.058, 0.058, 0.06, 0.068, 0.068, 0.07, 0.066, 0.066, 0.066, 0.068, 0.07, 0.072, 0.088, 0.092];
const PAD_CUT = [1500, 1650, 1750, 1850, 1950, 2000, 1900, 1950, 2100, 2300, 2350, 2400, 2350, 2350, 2300, 2400, 2500, 2600, 3000, 3100];
for (let b = 0; b < 20; b++) {
  const c = CHORDS[b];
  const t0 = b * BAR;
  c.pad.forEach((m, i) => {
    const spread = c.pad.length > 1 ? (i / (c.pad.length - 1)) * 2 - 1 : 0;
    padNote(t0, BAR + 0.85, m, PAD_AMP[b], PAD_CUT[b], spread * 0.55, 0.55, 1.15);
  });
}

// S1: a very soft low D/A foundation so the typographic opening is not thin
// on phone speakers.
sustainedLow(0.35, 4.75, 38, 0.05, 300, 0); // D2
sustainedLow(1.0, 4.0, 45, 0.028, 300, -0.2); // A2

// S3: low sustained line under the intimate detail shot.
sustainedLow(13.0, 5.0, 42, 0.075, 380, -0.25); // F#2
sustainedLow(16.0, 2.0, 42, 0.06, 380, -0.2);
bass(15.0, 43, 0.42, 1.2); // G2
bass(17.0, 45, 0.4, 1.0); // A2

/* --------------------------------------------------------------- melody A */
const MELODY = [
  // S1 - typesetting: sparse felt piano, clock underneath
  [0.30, 62, 0.52, 2.4, -0.18],
  [1.10, 69, 0.44, 2.1, 0.12],
  [2.10, 66, 0.38, 1.9, -0.1],
  [3.20, 64, 0.32, 1.5, 0.2],
  [4.10, 71, 0.4, 1.7, -0.05],
  // S2 - gentle lift
  [5.00, 74, 0.42, 1.6, 0.22, "glass"],
  [5.78, 69, 0.42, 1.6, -0.15],
  [6.55, 66, 0.38, 1.5, 0.12],
  [7.30, 64, 0.36, 1.4, -0.2],
  [8.00, 66, 0.3, 1.3, 0.3, "glass"],
  [8.78, 69, 0.4, 1.5, -0.1],
  [9.55, 73, 0.36, 1.4, 0.16],
  [10.30, 71, 0.34, 1.4, -0.18],
  [11.05, 69, 0.3, 1.4, 0.28, "glass"],
  [11.80, 67, 0.32, 1.5, -0.12],
  [12.55, 66, 0.38, 1.6, 0.1],
  // S3 - intimate detail
  [13.05, 71, 0.46, 2.5, -0.1],
  [14.05, 69, 0.38, 1.9, 0.16],
  [15.00, 67, 0.4, 1.9, -0.12],
  [15.78, 64, 0.28, 1.4, 0.26, "glass"],
  [16.05, 66, 0.4, 2.0, -0.08],
  [16.80, 69, 0.3, 1.4, 0.22, "glass"],
  [17.35, 76, 0.22, 1.2, 0.34, "glass"],
  [17.75, 74, 0.3, 1.2, -0.05],
  // S4 - clear groove (space left for the typing foley at 19.0-20.4)
  [18.05, 66, 0.42, 1.5, -0.14],
  [18.78, 69, 0.4, 1.5, 0.16],
  [20.55, 74, 0.4, 1.4, -0.08],
  [21.18, 71, 0.3, 1.2, 0.3, "glass"],
  [21.80, 69, 0.38, 1.4, 0.08],
  [22.55, 73, 0.38, 1.4, -0.18],
  [23.20, 71, 0.34, 1.3, 0.12],
  [23.75, 69, 0.28, 1.3, 0.32, "glass"],
  [24.28, 66, 0.36, 1.3, -0.1],
  [24.80, 64, 0.3, 1.2, 0.06],
  // S5 - drag: sparse, then snap, then re-entry
  [25.05, 66, 0.32, 1.6, 0.2, "glass"],
  [26.95, 71, 0.38, 1.4, -0.12],
  [27.52, 74, 0.28, 1.3, 0.28, "glass"],
  [28.05, 67, 0.4, 1.6, -0.06],
  [28.72, 71, 0.34, 1.5, 0.14],
  [29.50, 74, 0.3, 1.3, 0.3, "glass"],
  [30.05, 69, 0.38, 1.5, -0.1],
  [30.75, 73, 0.28, 1.2, 0.22, "glass"],
  // S6 - widgets: light, precise, rising
  [31.10, 76, 0.26, 1.4, 0.26, "glass"],
  [32.22, 74, 0.34, 1.2, -0.16],
  [33.05, 79, 0.2, 1.2, 0.34, "glass"],
  [33.78, 66, 0.34, 1.3, -0.08],
  [34.10, 69, 0.34, 1.3, 0.12],
  [34.82, 73, 0.26, 1.1, 0.26, "glass"],
  [35.40, 76, 0.32, 1.3, -0.05],
  [35.78, 74, 0.24, 1.1, 0.24, "glass"],
  // S7 - rise, impact, resolution
  [36.10, 69, 0.3, 1.2, -0.12],
  [36.60, 73, 0.3, 1.2, 0.14],
  [37.00, 76, 0.3, 1.1, 0.3, "glass"],
  [37.35, 79, 0.26, 0.9, -0.2, "glass"],
  [38.08, 62, 0.46, 3.0, -0.12],
  [38.22, 66, 0.4, 3.0, 0.14],
  [38.36, 69, 0.36, 3.0, -0.05],
  [38.50, 74, 0.3, 2.8, 0.2],
  [38.66, 76, 0.24, 2.6, 0.3, "glass"],
];
for (const [t0, m, amp, dur, pan, voice] of MELODY) {
  if (voice === "glass") glass(t0, m, amp, dur, pan);
  else piano(t0, m, amp, dur, pan, {bright: 0.5 + amp * 0.3});
}

/* ------------------------------------------------------------- clock ticks */
for (let i = 0; i < 6; i++) {
  const t = 0.5 + i;
  if (t > 5.0) break;
  tick(t, 0.9 - i * 0.09, i % 2 === 0 ? 1560 : 1080, i % 2 === 0 ? -0.22 : 0.22);
}
tick(5.55, 0.3, 1250, 0.18);

/* --------------------------------------------------------- groove patterns */
const groove = (t0, t1, level) => {
  for (let b = Math.floor(t0 / BAR); b * BAR < t1; b++) {
    const barStart = b * BAR;
    const c = CHORDS[clamp(b, 0, 19)];
    for (const beat of [0, 2]) {
      const t = barStart + beat * BEAT;
      if (t >= t0 && t < t1) kick(t, 0.42 * level);
    }
    for (const beat of [0.5, 1.5, 2.5, 3.5]) {
      const t = barStart + beat * BEAT;
      if (t >= t0 && t < t1) {
        const accent = beat === 1.5 || beat === 3.5 ? 1 : 0.72;
        shaker(t, 0.62 * level * accent, beat === 1.5 ? -0.32 : 0.32);
      }
    }
    for (const beat of [1, 3]) {
      const t = barStart + beat * BEAT;
      if (t >= t0 && t < t1) tick(t, 0.28 * level, beat === 1 ? 1320 : 980, beat === 1 ? -0.28 : 0.28);
    }
    const bassPattern = [
      [0.0, 0, 0.9],
      [1.5, 0, 0.42],
      [2.5, 7, 0.62],
    ];
    for (const [beat, off, dur] of bassPattern) {
      const t = barStart + beat * BEAT;
      if (t >= t0 && t < t1) bass(t, c.bass + off, 0.62 * level, dur);
    }
  }
};

// S2: lift without a hard groove - shaker + soft bass from 8.0, kick from 10.0.
for (let i = 0; i < 20; i++) {
  const t = 8.0 + i * 0.25;
  if (t >= 13.0) break;
  shaker(t, i % 2 === 0 ? 0.22 : 0.15, i % 2 === 0 ? 0.3 : -0.3);
}
for (let i = 0; i < 4; i++) {
  const t = 8.0 + i * 2;
  bass(t, chordAt(t).bass, 0.3, 0.9);
  bass(t + 1.0, chordAt(t + 1).bass + 7, 0.22, 0.5);
}
for (const t of [10.0, 11.0, 12.0]) {
  kick(t, 0.2);
  kick(t + 1.0, 0.2);
}

// S4: full soft groove (18.0-25.0)
groove(18.0, 25.0, 1.0);

// S5: drums out under the lift, then a suck into the snap at 26.667
noiseSwell(25.55, 26.64, 0.5, 340, 2600, 0.5, 4242);
timpani(26.2, 0.1, 45);
// snap accent at frame 800: low body + open chord stab; the mid click belongs
// to the film's own snap.wav (780 Hz wood) so the two do not mask each other.
const SNAP_T = at(800); // 26.6667
kick(SNAP_T, 0.62 * BAL.snap);
bass(SNAP_T, 38, 0.72 * BAL.snap, 0.7);
[50, 57, 62, 66].forEach((m, i) => {
  padNote(SNAP_T, 1.35, m, 0.085 * BAL.snap, 3200, (i - 1.5) * 0.28, 0.012, 0.55);
});
glass(SNAP_T + 0.012, 74, 0.34 * BAL.snap, 1.0, 0.2);
glass(SNAP_T + 0.02, 81, 0.22 * BAL.snap, 0.9, -0.24);
tick(26.92, 0.34, 1760, 0.18);
groove(27.0, 31.0, 0.96);

// S6: keep the groove, add 16th shaker sparkle after the cards land (32.7+)
groove(31.0, 36.0, 1.02);
for (let t = 32.75; t < 35.9; t += 0.25) {
  shaker(t + 0.125, 0.085, t % 0.5 < 0.25 ? -0.4 : 0.4, 0.07);
}

// S7: drums out at 36.0; tuned roll -> impact 1126 -> resolution 1142.
sustainedLow(36.0, 1.55, 45, 0.045, 340, 0); // A2 pedal under the rise
bass(36.0, 45, 0.5, 1.5);
for (let i = 0; i < 8; i++) {
  timpani(36.45 + i * 0.135, 0.075 + i * 0.012, 45, -0.15 + (i % 2) * 0.3);
}
for (const [beat, off, dur] of [[0.5, 0, 0.9], [1.5, 0, 0.5], [2.5, 7, 0.6]]) {
  bass(36.0 + beat * BEAT, 45 + off, 0.5, dur);
}
// impact: mid-low A + wide A7 stab + shimmer; the sub is left to impact.wav
const IMPACT = at(1126); // 37.5333
kick(IMPACT, 0.5 * BAL.impact * BAL.snap);
timpani(IMPACT, 0.5 * BAL.impact, 45);
[57, 61, 64, 67].forEach((m, i) => {
  padNote(IMPACT, 2.2, m, 0.095 * BAL.impact, 3600, (i - 1.5) * 0.32, 0.008, 1.2);
});
glass(IMPACT + 0.01, 81, 0.3 * BAL.impact, 2.0, 0.35);
noiseSwell(36.6, IMPACT - 0.01, 0.32 * BAL.impact, 500, 5200, 0.35, 777);
// resolution at frame 1142 (38.0667) - Dmaj9, matches the 660 Hz chime (E5)
const RES = at(1142);
bass(RES, 38, 0.5, 1.8);
[50, 57, 62, 66].forEach((m, i) => {
  padNote(RES, 2.0, m, 0.075, 2600, (i - 1.5) * 0.3, 0.01, 1.5);
});
[74, 78, 81].forEach((m, i) => glass(RES + 0.02 + i * 0.055, m, 0.16 - i * 0.025, 2.2, 0.1 + i * 0.14));
tick(RES + 0.01, 0.25, 1320, 0);

/* ------------------------------------------------------- gentle room tone */
{
  const rng = mulberry32(2024);
  let lpL = 0, lpR = 0;
  for (let i = 0; i < N; i++) {
    const t = i / SR;
    lpL += 0.012 * (rng() * 2 - 1 - lpL);
    lpR += 0.012 * (rng() * 2 - 1 - lpR);
    const e = smooth(t / 1.5) * smooth((38.8 - t) / 1.4) * BAL.air;
    dry.L[i] += lpL * 0.028 * e;
    dry.R[i] += lpR * 0.028 * e;
  }
}

/* ------------------------------------------------------------------ reverb */
/** Synthetic stereo impulse: predelay + damped exponential noise tail. */
const makeIR = (seconds = 1.5, seed = 77) => {
  const n = Math.round(seconds * SR);
  const pre = Math.round(0.018 * SR);
  const L = new Float64Array(n);
  const R = new Float64Array(n);
  const rL = mulberry32(seed);
  const rR = mulberry32(seed + 1);
  let sL = 0, sR = 0, lpL = 0, lpR = 0, lpL2 = 0, lpR2 = 0;
  for (let i = pre; i < n; i++) {
    const t = (i - pre) / SR;
    const env = Math.exp(-t * 3.15) * smooth(t / 0.012);
    const a = 0.06 + 0.36 * Math.exp(-t * 2.1);
    sL = rL() * 2 - 1;
    sR = rR() * 2 - 1;
    lpL += a * (sL - lpL);
    lpR += a * (sR - lpR);
    lpL2 += a * (lpL - lpL2);
    lpR2 += a * (lpR - lpR2);
    L[i] = lpL2 * env;
    R[i] = lpR2 * env;
  }
  for (const [ms, g, side] of [[11, 0.42, -1], [17, 0.3, 1], [23, 0.24, -1], [31, 0.16, 1], [43, 0.1, -1]]) {
    const i = Math.round((0.018 + ms / 1000) * SR);
    if (i < n) L[i] += g * 0.5;
    if (i + side * 3 < n) R[i + side * 3] += g * 0.5;
  }
  let e = 1e-12;
  for (let i = 0; i < n; i++) e += L[i] * L[i] + R[i] * R[i];
  const g = 1 / Math.sqrt(e / 2);
  for (let i = 0; i < n; i++) {
    L[i] *= g;
    R[i] *= g;
  }
  return {L, R, n};
};

/* FFT (radix-2, in place) with cached twiddles. */
const FFT_N = 1 << 18; // 262144
const HALF = FFT_N >> 1;
const COS = new Float64Array(HALF + 1);
const SIN = new Float64Array(HALF + 1);
for (let i = 0; i <= HALF; i++) {
  COS[i] = Math.cos((2 * Math.PI * i) / FFT_N);
  SIN[i] = Math.sin((2 * Math.PI * i) / FFT_N);
}
const bitrev = new Uint32Array(FFT_N);
for (let i = 0; i < FFT_N; i++) {
  let x = i, r = 0;
  for (let b = 0; b < 18; b++) {
    r = (r << 1) | (x & 1);
    x >>= 1;
  }
  bitrev[i] = r;
}
const fft = (re, im, inverse) => {
  for (let i = 0; i < FFT_N; i++) {
    const j = bitrev[i];
    if (j > i) {
      let t = re[i]; re[i] = re[j]; re[j] = t;
      t = im[i]; im[i] = im[j]; im[j] = t;
    }
  }
  for (let len = 2; len <= FFT_N; len <<= 1) {
    const half = len >> 1;
    const step = FFT_N / len;
    const sign = inverse ? 1 : -1;
    for (let i = 0; i < FFT_N; i += len) {
      for (let k = 0; k < half; k++) {
        const wr = COS[k * step];
        const wi = sign * SIN[k * step];
        const a = i + k;
        const b = a + half;
        const xr = re[b] * wr - im[b] * wi;
        const xi = re[b] * wi + im[b] * wr;
        re[b] = re[a] - xr;
        im[b] = im[a] - xi;
        re[a] += xr;
        im[a] += xi;
      }
    }
  }
  if (inverse) {
    for (let i = 0; i < FFT_N; i++) {
      re[i] /= FFT_N;
      im[i] /= FFT_N;
    }
  }
};

const convolve = (input, ir) => {
  const irRe = new Float64Array(FFT_N);
  const irIm = new Float64Array(FFT_N);
  irRe.set(ir);
  fft(irRe, irIm, false);
  const out = new Float64Array(N + FFT_N);
  const blk = 1 << 17; // 131072
  const re = new Float64Array(FFT_N);
  const im = new Float64Array(FFT_N);
  const tr = new Float64Array(FFT_N);
  const ti = new Float64Array(FFT_N);
  for (let off = 0; off < N; off += blk) {
    re.fill(0);
    im.fill(0);
    const n = Math.min(blk, N - off);
    for (let i = 0; i < n; i++) re[i] = input[off + i];
    fft(re, im, false);
    for (let i = 0; i < FFT_N; i++) {
      tr[i] = re[i] * irRe[i] - im[i] * irIm[i];
      ti[i] = re[i] * irIm[i] + im[i] * irRe[i];
    }
    fft(tr, ti, true);
    for (let i = 0; i < FFT_N; i++) out[off + i] += tr[i];
  }
  return out;
};

const ir = makeIR(1.5, 7717);
const wetL = convolve(send.L, ir.L);
const wetR = convolve(send.R, ir.R);

/* ------------------------------------------------------------ master bus */
const outL = new Float64Array(N);
const outR = new Float64Array(N);
const WET = 0.3;
for (let i = 0; i < N; i++) {
  outL[i] = dry.L[i] + wetL[i] * WET;
  outR[i] = dry.R[i] + wetR[i] * WET;
}

// 26 Hz rumble filter (two cascaded one-pole high-passes)
{
  const a = 1 - Math.exp((-2 * Math.PI * 26) / SR);
  let l1 = 0, l2 = 0, r1 = 0, r2 = 0;
  for (let i = 0; i < N; i++) {
    l1 += a * (outL[i] - l1);
    l2 += a * (l1 - l2);
    outL[i] -= l2;
    r1 += a * (outR[i] - r1);
    r2 += a * (r1 - r2);
    outR[i] -= r2;
  }
}

// soft bus glue (very gentle, only rounds the loudest transients)
for (let i = 0; i < N; i++) {
  outL[i] = Math.tanh(outL[i] * 1.12) / 1.12;
  outR[i] = Math.tanh(outR[i] * 1.12) / 1.12;
}

// musical fades: 12 ms in, long breathing fade after the final ring
for (let i = 0; i < N; i++) {
  const t = i / SR;
  const fin = smooth(t / 0.012);
  const fend = t < 38.86 ? 1 : 1 - smooth((t - 38.86) / 1.03);
  outL[i] *= fin * fend;
  outR[i] *= fin * fend;
}

/* --------------------------------------------------- loudness / peak check */
const truePeak = (L, R) => {
  let p = 0;
  for (const x of [L, R]) {
    for (let i = 1; i < N - 2; i++) {
      const xm1 = x[i - 1], x0 = x[i], x1 = x[i + 1], x2 = x[i + 2];
      const a0 = 2 * x0;
      const a1 = -xm1 + x1;
      const a2 = 2 * xm1 - 5 * x0 + 4 * x1 - x2;
      const a3 = -xm1 + 3 * x0 - 3 * x1 + x2;
      for (let s = 1; s < 4; s++) {
        const t = s / 4, t2 = t * t, t3 = t2 * t;
        const v = Math.abs(0.5 * (a0 + a1 * t + a2 * t2 + a3 * t3));
        if (v > p) p = v;
      }
    }
  }
  return p;
};
const peakOf = (L, R) => {
  let p = 0;
  for (let i = 0; i < N; i++) p = Math.max(p, Math.abs(L[i]), Math.abs(R[i]));
  return p;
};

const kWeight = (x) => {
  const out = new Float64Array(N);
  const sb = [1.53512485958697, -2.69169618940638, 1.19839281085285];
  const sa = [1, -1.69065929318241, 0.73248077421585];
  const hb = [1.0, -2.0, 1.0];
  const ha = [1, -1.99004745483398, 0.99007225036621];
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < N; i++) {
    const v = x[i];
    const y = sb[0] * v + sb[1] * x1 + sb[2] * x2 - sa[1] * y1 - sa[2] * y2;
    x2 = x1; x1 = v; y2 = y1; y1 = y;
    out[i] = y;
  }
  x1 = x2 = y1 = y2 = 0;
  for (let i = 0; i < N; i++) {
    const v = out[i];
    const y = hb[0] * v + hb[1] * x1 + hb[2] * x2 - ha[1] * y1 - ha[2] * y2;
    x2 = x1; x1 = v; y2 = y1; y1 = y;
    out[i] = y;
  }
  return out;
};
const lufsOf = (kl, kr, a = 0, b = N) => {
  const block = 0.4 * SR, hop = 0.1 * SR;
  const z = [];
  for (let s = a; s + block <= b; s += hop) {
    let ms = 0;
    for (let i = s; i < s + block; i++) ms += kl[i] * kl[i] + kr[i] * kr[i];
    z.push(ms / block);
  }
  if (!z.length) return null;
  const l = (v) => -0.691 + 10 * Math.log10(Math.max(v, 1e-20));
  const ungated = z.reduce((a2, b2) => a2 + b2, 0) / z.length;
  const rel = Math.pow(10, (-10 + l(ungated)) / 10);
  const abs = Math.pow(10, (-70 + 0.691) / 10);
  const kept = z.filter((v) => v > abs && v > rel);
  return l(kept.reduce((a2, b2) => a2 + b2, 0) / kept.length);
};
const lufs = (L, R) => lufsOf(kWeight(L), kWeight(R));
const db = (v) => 20 * Math.log10(Math.max(v, 1e-12));

// Normalise: integrated loudness at -17.5 LUFS, but never exceed a -2.6 dBFS
// sample peak, so the delivered file keeps headroom.
const rawPeak = peakOf(outL, outR);
const rawLufs = lufs(outL, outR);
const gPeak = Math.pow(10, -2.6 / 20) / rawPeak;
const gLufs = Math.pow(10, -17.5 / 20) / Math.pow(10, rawLufs / 20);
const gain = Math.min(gPeak, gLufs);
for (let i = 0; i < N; i++) {
  outL[i] *= gain;
  outR[i] *= gain;
}

const finalPeak = peakOf(outL, outR);
const finalTp = truePeak(outL, outR);
const kl = kWeight(outL);
const kr = kWeight(outR);
const finalLufs = lufsOf(kl, kr);
let sumSq = 0;
let clipped = 0;
for (let i = 0; i < N; i++) {
  sumSq += outL[i] * outL[i] + outR[i] * outR[i];
  if (Math.abs(outL[i]) >= 0.9999 || Math.abs(outR[i]) >= 0.9999) clipped++;
}
const rms = Math.sqrt(sumSq / (2 * N));

/* --------------------------------------------------------------- WAV write */
const writeWav = (file, L, R) => {
  const buf = Buffer.alloc(44 + N * 4);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + N * 4, 4);
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
  buf.writeUInt32LE(N * 4, 40);
  for (let i = 0; i < N; i++) {
    buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(L[i] * 32767))), 44 + i * 4);
    buf.writeInt16LE(Math.max(-32767, Math.min(32767, Math.round(R[i] * 32767))), 46 + i * 4);
  }
  fs.writeFileSync(file, buf);
};
const wavPath = path.join(OUT_DIR, "bgm.wav");
writeWav(wavPath, outL, outR);

/* --------------------------------------------------------- per-shot stats */
const SHOTS = [
  {id: "S1", name: "OPEN", from: 0, to: 150, label: "开场 · 软时钟/打字机"},
  {id: "S2", name: "WEEK", from: 150, to: 390, label: "周课表 · 轻推进"},
  {id: "S3", name: "DETAIL", from: 390, to: 540, label: "详情 · 收束留白"},
  {id: "S4", name: "IMPORT", from: 540, to: 750, label: "导入 · 清晰律动"},
  {id: "S5", name: "DRAG", from: 750, to: 930, label: "拖拽 · snap 重音"},
  {id: "S6", name: "WIDGETS", from: 930, to: 1080, label: "小组件 · 轻快精密"},
  {id: "S7", name: "OUTRO", from: 1080, to: 1200, label: "色彩+收尾 · 峰值后留白"},
];
const sectionStats = SHOTS.map((s) => {
  const a = Math.round(at(s.from) * SR);
  const b = Math.min(N, Math.round(at(s.to) * SR));
  let peak = 0, ss = 0, zc = 0, prev = 0;
  for (let i = a; i < b; i++) {
    const l = outL[i], r = outR[i];
    peak = Math.max(peak, Math.abs(l), Math.abs(r));
    ss += l * l + r * r;
    if ((l >= 0) !== (prev >= 0)) zc++;
    prev = l;
  }
  const frames = b - a;
  return {
    ...s,
    peakDbfs: +db(peak).toFixed(2),
    rmsDbfs: +db(Math.sqrt(ss / (2 * frames))).toFixed(2),
    lufsShort: +lufsOf(kl, kr, a, b).toFixed(1),
    zcrPerSec: +((zc / (frames / SR)) || 0).toFixed(0),
  };
});

/* ------------------------------------------------------------------- cues */
const beatGrid = [];
for (let beat = 0; beat < 80; beat++) {
  const t = beat * BEAT;
  const frame = Math.round(t * FPS);
  const bar = Math.floor(beat / 4) + 1;
  const beatInBar = (beat % 4) + 1;
  const section = SHOTS.find((s) => frame >= s.from && frame < s.to) || SHOTS[6];
  beatGrid.push({
    beat,
    frame,
    timeSec: +t.toFixed(3),
    bar,
    beatInBar,
    shot: section.id,
    downbeat: beatInBar === 1,
  });
}
const accent = (frame, type, desc, extra = {}) => ({
  frame,
  timeSec: +(frame / FPS).toFixed(3),
  beat: +((frame / FPS) / BEAT).toFixed(3),
  type,
  desc,
  ...extra,
});
const accents = [
  accent(0, "start", "片头 · pad 起音（12ms fade-in），首拍"),
  accent(2, "foley", "纸滑落版（SFX，非 BGM）", {layer: "sfx"}),
  accent(48, "foley", "字标升起 swish（SFX）", {layer: "sfx"}),
  accent(70, "foley", "字标落定 stamp（SFX）", {layer: "sfx"}),
  accent(150, "cut", "S2 切点 · 同时换和弦 Gmaj7，shaker 进入", {layer: "both"}),
  accent(300, "beat", "第 20 拍 · S2 中段", {layer: "bgm"}),
  accent(390, "cut", "S3 切点 · 鼓组退出，低音长音进入", {layer: "both"}),
  accent(520, "beat", "第 34.67 拍 · 详情镜头中段"),
  accent(540, "cut", "S4 切点 · 完整律动开始（kick/shaker/bass）", {layer: "both"}),
  accent(590, "beat", "第 39.33 拍 · 导入前呼吸"),
  accent(700, "beat", "第 46.67 拍 · 导入卡列尾段"),
  accent(750, "cut", "S5 切点 · 鼓组抽空，进入 drag", {layer: "both"}),
  accent(780, "beat", "第 52 拍 · 落点高亮，噪声 suck 渐强", {layer: "bgm"}),
  accent(800, "snap", "SNAP 重音：低音 kick + D add9 开放和声 + 玻璃高音（与 snap.wav 分工）", {layer: "both", musicEvent: "snap-accent"}),
  accent(806, "foley", "归位 stamp（SFX）", {layer: "sfx"}),
  accent(860, "beat", "第 57.33 拍 · 归位 hold，律动回归", {layer: "bgm"}),
  accent(930, "cut", "S6 切点 · 轻快精密律动 + 上升动机", {layer: "both"}),
  accent(938, "foley", "小组件 1 落位（SFX）", {layer: "sfx"}),
  accent(964, "foley", "小组件 2 落位（SFX）", {layer: "sfx"}),
  accent(972, "foley", "小组件 3 落位（SFX）", {layer: "sfx"}),
  accent(980, "foley", "小组件 4 落位（SFX）", {layer: "sfx"}),
  accent(1000, "beat", "第 66.67 拍 · 小组件镜头中段"),
  accent(1080, "cut", "S7 切点 · 鼓组停止，A7 上升 + 定音鼓滚奏", {layer: "both"}),
  accent(1105, "beat", "第 73.67 拍 · 色板横扫"),
  accent(1126, "impact", "字标落地重音：A7 宽和声 + 中低 A + 玻璃高音（低频留给 impact.wav）", {layer: "both", musicEvent: "impact"}),
  accent(1140, "beat", "第 76 拍 · 收束和弦预备"),
  accent(1142, "resolve", "Dmaj9 解决，与 660Hz chime 同落（E5）", {layer: "both", musicEvent: "resolution"}),
  accent(1185, "hold", "字标 hold · 无新音符，只剩和弦尾音", {layer: "bgm"}),
  accent(1200, "end", "片尾 · 已淡出至数字静音", {layer: "bgm"}),
];

const cues = {
  $schema: "promo-bgm-cues/1",
  generatedBy: "promo/audio/make-bgm.mjs",
  title: "课程表 · 40s promo BGM",
  license: "CC0-1.0 (self-authored, synthesised, no third-party samples)",
  fps: FPS,
  durationFrames: FRAMES,
  durationSec: DUR,
  bpm: BPM,
  beatsPerBar: 4,
  beatFrames: (60 / BPM) * FPS,
  offsetFrames: 0,
  offsetSec: 0,
  audio: {
    file: "promo/audio/bgm.wav",
    format: "PCM 16-bit",
    sampleRate: SR,
    channels: 2,
    durationSec: DUR,
    peakDbfs: +db(finalPeak).toFixed(2),
    truePeakDbfs: +db(finalTp).toFixed(2),
    rmsDbfs: +db(rms).toFixed(2),
    lufsI: +finalLufs.toFixed(1),
    clippedSamples: clipped,
  },
  mix: {
    recommendedVolume: 0.5,
    note: "以 Remotion <Audio volume> ≈0.5 与现有 SFX 混音；本曲比原 bed 更有律动，请勿与 bed-paper-piano.wav 叠加。",
    containerNote: "成片容器 40.064s（AAC priming），本轨 40.000s；Remotion 内按 1200f 时间线播放，尾部 64ms 为静音。",
  },
  sections: sectionStats.map((s) => ({
    id: s.id,
    name: s.name,
    from: s.from,
    to: s.to,
    durationFrames: s.to - s.from,
    fromSec: +(s.from / FPS).toFixed(3),
    toSec: +(s.to / FPS).toFixed(3),
    bars: [Math.floor(s.from / FPS / BAR) + 1, Math.ceil(s.to / FPS / BAR)],
    label: s.label,
    peakDbfs: s.peakDbfs,
    rmsDbfs: s.rmsDbfs,
    lufsShort: s.lufsShort,
    brightnessZcrPerSec: s.zcrPerSec,
  })),
  beats: beatGrid,
  accents,
  fades: {
    in: {fromFrame: 0, toFrame: 1, note: "12ms 余弦淡入，避免起音 click"},
    out: {fromFrame: Math.round(38.86 * FPS), toFrame: Math.round(39.89 * FPS), note: "38.86s 起余弦淡出，39.89s 后数字静音，保留 1.2s 字标 hold 的呼吸"},
  },
  source: {
    type: "original synthesis",
    script: "promo/audio/make-bgm.mjs",
    instruments: ["felt piano", "warm pad", "plucked bass", "low string sustain", "soft kick", "brush shaker", "wood tick", "timpani", "glass/music-box pluck", "synthetic convolution reverb"],
    seedPolicy: "deterministic mulberry32; same script -> same bytes",
  },
};
fs.writeFileSync(path.join(OUT_DIR, "cues.json"), JSON.stringify(cues, null, 2) + "\n");

/* --------------------------------------------------------------- console */
console.log(JSON.stringify({
  wav: wavPath,
  duration: DUR,
  bpm: BPM,
  bars: 20,
  peakDbfs: +db(finalPeak).toFixed(2),
  truePeakDbfs: +db(finalTp).toFixed(2),
  rmsDbfs: +db(rms).toFixed(2),
  lufsI: +finalLufs.toFixed(1),
  gainDb: +db(gain).toFixed(2),
  clippedSamples: clipped,
  sections: sectionStats,
  accents: accents.filter((a) => a.musicEvent).map((a) => ({frame: a.frame, event: a.musicEvent})),
}, null, 2));
