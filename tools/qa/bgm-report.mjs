/**
 * verify-bgm-v2.mjs — Lead-side non-auditory verification of the promo BGM.
 * Reads a PCM WAV (16/24/32-bit) and reports, per 2 s window and per shot
 * segment: RMS, band energy (low/mid/high), transient (kick/snare) counts.
 * Also prints a 4-bar melodic-contour fingerprint so motif recurrence can be
 * checked without listening.
 *
 *   node verify-bgm-v2.mjs <file.wav>
 */
import fs from "node:fs";

const readWav = (file) => {
  const buf = fs.readFileSync(file);
  if (buf.toString("ascii", 0, 4) !== "RIFF") throw new Error("not RIFF");
  let pos = 12, fmt = null, data = null;
  while (pos + 8 <= buf.length) {
    const id = buf.toString("ascii", pos, pos + 4);
    const size = buf.readUInt32LE(pos + 4);
    const body = pos + 8;
    if (id === "fmt ") {
      fmt = {
        format: buf.readUInt16LE(body),
        channels: buf.readUInt16LE(body + 2),
        sampleRate: buf.readUInt32LE(body + 4),
        bits: buf.readUInt16LE(body + 14),
      };
    } else if (id === "data") {
      data = buf.subarray(body, Math.min(body + size, buf.length));
    }
    pos = body + size + (size & 1);
  }
  if (!fmt || !data) throw new Error("missing fmt/data");
  const bytes = fmt.bits / 8;
  const frames = Math.floor(data.length / (bytes * fmt.channels));
  const L = new Float32Array(frames), R = new Float32Array(frames);
  for (let i = 0; i < frames; i++) {
    const base = i * bytes * fmt.channels;
    const rd = (o) => {
      if (fmt.bits === 16) return data.readInt16LE(o) / 32768;
      if (fmt.bits === 24) return data.readIntLE(o, 3) / 8388608;
      return data.readInt32LE(o) / 2147483648;
    };
    L[i] = rd(base);
    R[i] = fmt.channels > 1 ? rd(base + bytes) : L[i];
  }
  return {...fmt, frames, L, R, duration: frames / fmt.sampleRate};
};

/* ---- RBJ biquad ---- */
const biquad = (x, type, f0, q, SR) => {
  const w = (2 * Math.PI * f0) / SR, cs = Math.cos(w), sn = Math.sin(w);
  const alpha = sn / (2 * q);
  let b0, b1, b2, a0, a1, a2;
  if (type === "lp") {
    b0 = (1 - cs) / 2; b1 = 1 - cs; b2 = (1 - cs) / 2;
    a0 = 1 + alpha; a1 = -2 * cs; a2 = 1 - alpha;
  } else if (type === "hp") {
    b0 = (1 + cs) / 2; b1 = -(1 + cs); b2 = (1 + cs) / 2;
    a0 = 1 + alpha; a1 = -2 * cs; a2 = 1 - alpha;
  } else {
    b0 = alpha; b1 = 0; b2 = -alpha;
    a0 = 1 + alpha; a1 = -2 * cs; a2 = 1 - alpha;
  }
  const nb0 = b0 / a0, nb1 = b1 / a0, nb2 = b2 / a0, na1 = a1 / a0, na2 = a2 / a0;
  const y = new Float32Array(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const v = nb0 * x[i] + nb1 * x1 + nb2 * x2 - na1 * y1 - na2 * y2;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = v; y[i] = v;
  }
  return y;
};

const db = (v) => (v <= 1e-12 ? -120 : 20 * Math.log10(v));
const rms = (x, a, b) => {
  let s = 0;
  const n = Math.max(1, b - a);
  for (let i = a; i < b; i++) s += x[i] * x[i];
  return Math.sqrt(s / n);
};

const file = process.argv[2];
const w = readWav(file);
const SR = w.sampleRate;
const n = w.frames;
const mono = new Float32Array(n);
for (let i = 0; i < n; i++) mono[i] = (w.L[i] + w.R[i]) * 0.5;

console.log(`# ${file}`);
console.log(`format: ${w.sampleRate} Hz / ${w.bits}-bit / ${w.channels} ch / ${w.duration.toFixed(3)} s / ${n} frames`);

/* band split */
const low = biquad(mono, "lp", 160, 0.707, SR);                    // kick + bass fundamental
const midLow = biquad(mono, "lp", 1200, 0.707, SR);                // body
const high = biquad(mono, "hp", 6000, 0.707, SR);                  // hats / air
const melBand = biquad(biquad(mono, "hp", 420, 0.707, SR), "lp", 3200, 0.707, SR); // melody range

/* ---- per 2 s window ---- */
console.log("\n## 2 s windows: rms / low / melody / high (dBFS)");
const W = 2 * SR;
const rows = [];
for (let a = 0; a < n; a += W) {
  const b = Math.min(n, a + W);
  rows.push({
    t: (a / SR).toFixed(0).padStart(2, " ") + "s",
    rms: db(rms(mono, a, b)).toFixed(1),
    low: db(rms(low, a, b)).toFixed(1),
    mel: db(rms(melBand, a, b)).toFixed(1),
    high: db(rms(high, a, b)).toFixed(1),
  });
}
for (const r of rows) console.log(`${r.t}  all ${r.rms.padStart(6)}  low ${r.low.padStart(6)}  mel ${r.mel.padStart(6)}  high ${r.high.padStart(6)}`);

/* ---- shot segments (frame -> s) ---- */
const SHOTS = [
  ["open", 0],
  ["week", 300],
  ["detail", 590],
  ["import", 780],
  ["drag", 1000],
  ["widget", 1185],
  ["outro", 1400],
  ["end", 2400],
];
const FPS = 60;
console.log("\n## shot segments");
for (let i = 0; i < SHOTS.length - 1; i++) {
  const [name, f0] = SHOTS[i];
  const f1 = SHOTS[i + 1][1];
  const a = Math.round((f0 / FPS) * SR), b = Math.min(n, Math.round((f1 / FPS) * SR));
  console.log(
    `${name.padEnd(7)} ${(f0 / FPS).toFixed(2)}–${(f1 / FPS).toFixed(2)}s  ` +
    `all ${db(rms(mono, a, b)).toFixed(1)}  low ${db(rms(low, a, b)).toFixed(1)}  ` +
    `mel ${db(rms(melBand, a, b)).toFixed(1)}  high ${db(rms(high, a, b)).toFixed(1)}`
  );
}

/* ---- transient detection on low + broadband ---- */
const detect = (sig, threshold, minGapMs) => {
  const hop = Math.round(SR * 0.005);
  const env = [];
  for (let i = 0; i + hop < sig.length; i += hop) env.push(rms(sig, i, i + hop));
  const times = [];
  let lastT = -1e9;
  for (let k = 2; k < env.length - 2; k++) {
    const rise = env[k] - env[k - 2];
    if (env[k] > threshold && rise > threshold * 0.6) {
      const t = (k * hop) / SR;
      if ((t - lastT) * 1000 >= minGapMs) { times.push(t); lastT = t; }
    }
  }
  return times;
};
const kicks = detect(low, 0.05, 180);
const snares = detect(biquad(mono, "hp", 1800, 0.707, SR), 0.05, 180);
console.log(`\n## transients\nkick-ish: ${kicks.length}\nsnare/hat-ish: ${snares.length}`);
const bpmSpan = 120;
const beat = 60 / bpmSpan;
const onGrid = kicks.filter((t) => Math.abs(((t % beat) + beat) % beat) < 0.02 || Math.abs((((t % beat) + beat) % beat) - beat) < 0.02).length;
console.log(`on 120 BPM grid (kick): ${onGrid}/${kicks.length}`);

/* ---- melodic contour fingerprint: strongest pitch per beat ---- */
console.log("\n## melodic pitch track (strongest bin per 2 beats, MIDI note)");
const noteName = (m) => {
  const names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
  return names[m % 12] + (Math.floor(m / 12) - 1);
};
const segFrames = Math.round(2 * beat * SR);
const pitches = [];
for (let a = 0; a + segFrames <= n; a += segFrames) {
  const seg = melBand.subarray(a, a + segFrames);
  // autocorrelation over plausible melody f0 range 110–900 Hz
  let bestLag = 0, bestVal = -1;
  const minLag = Math.floor(SR / 900), maxLag = Math.floor(SR / 110);
  for (let lag = minLag; lag < maxLag; lag++) {
    let s = 0;
    for (let i = 0; i < segFrames - lag; i += 4) s += seg[i] * seg[i + lag];
    if (s > bestVal) { bestVal = s; bestLag = lag; }
  }
  const f0 = SR / bestLag;
  const midi = Math.round(69 + 12 * Math.log2(f0 / 440));
  pitches.push(midi);
}
const line = pitches.map((m) => noteName(m).padStart(4)).join(" ");
console.log(line);
console.log(`\nunique pitches: ${[...new Set(pitches)].length}, range: ${noteName(Math.min(...pitches))}–${noteName(Math.max(...pitches))}`);

/* ---- motif recurrence: repeated 8-beat subsequences across the piece ---- */
const key = (arr) => arr.join(",");
const winLen = 4;
const seen = new Map();
for (let i = 0; i + winLen <= pitches.length; i++) {
  const k = key(pitches.slice(i, i + winLen));
  if (!seen.has(k)) seen.set(k, []);
  seen.get(k).push(i);
}
const repeats = [...seen.entries()].filter(([, v]) => v.length >= 2).sort((a, b) => b[1].length - a[1].length).slice(0, 6);
console.log(`\n## recurring 8-beat motifs (>=2 occurrences)`);
for (const [k, v] of repeats) console.log(`x${v.length} at 2-beat index [${v.join(", ")}]  ->  ${k}`);
if (!repeats.length) console.log("none — motif does not recur");
