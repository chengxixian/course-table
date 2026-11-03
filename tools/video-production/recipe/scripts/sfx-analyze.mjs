/**
 * sfx-analyze.mjs — objective profile of a sound-effect candidate.
 *
 * Reports duration, peak/RMS, band split (low <160 Hz, body 160–1.2k, presence
 * 1.2–6k, air >6k), zero-crossing rate, and — for tonal tails — an
 * autocorrelation pitch estimate. Used to decide whether a Freesound clip can
 * be trimmed into the cue slot without dragging a tail or a rumble into the mix.
 *
 *   node sfx-analyze.mjs <file.wav> [more.wav ...]
 */
import fs from "node:fs";
import path from "node:path";

const readMono = (file) => {
  const b = fs.readFileSync(file);
  let p = 12, fmt = null, data = null;
  while (p + 8 <= b.length) {
    const id = b.toString("ascii", p, p + 4), sz = b.readUInt32LE(p + 4), body = p + 8;
    if (id === "fmt ") fmt = {ch: b.readUInt16LE(body + 2), sr: b.readUInt32LE(body + 4), bits: b.readUInt16LE(body + 14)};
    else if (id === "data") data = b.subarray(body, Math.min(body + sz, b.length));
    p = body + sz + (sz & 1);
  }
  const bytes = fmt.bits / 8;
  const frames = Math.floor(data.length / (bytes * fmt.ch));
  const x = new Float32Array(frames);
  for (let i = 0; i < frames; i++) {
    let s = 0;
    for (let c = 0; c < fmt.ch; c++) {
      const o = i * bytes * fmt.ch + c * bytes;
      let v;
      if (fmt.bits === 16) v = data.readInt16LE(o) / 32768;
      else if (fmt.bits === 24) v = data.readIntLE(o, 3) / 8388608;
      else v = data.readInt32LE(o) / 2147483648;
      s += v;
    }
    x[i] = s / fmt.ch;
  }
  return {x, sr: fmt.sr};
};

const db = (v) => (v <= 1e-12 ? -120 : 20 * Math.log10(v));
const rms = (x, a = 0, b = x.length) => {
  let s = 0;
  for (let i = a; i < b; i++) s += x[i] * x[i];
  return Math.sqrt(s / Math.max(1, b - a));
};

const biquad = (x, type, f0, q, SR) => {
  const w = (2 * Math.PI * f0) / SR, cs = Math.cos(w), sn = Math.sin(w);
  const alpha = sn / (2 * q);
  let b0, b1, b2, a0, a1, a2;
  if (type === "lp") { b0 = (1 - cs) / 2; b1 = 1 - cs; b2 = (1 - cs) / 2; a0 = 1 + alpha; a1 = -2 * cs; a2 = 1 - alpha; }
  else { b0 = (1 + cs) / 2; b1 = -(1 + cs); b2 = (1 + cs) / 2; a0 = 1 + alpha; a1 = -2 * cs; a2 = 1 - alpha; }
  const nb0 = b0 / a0, nb1 = b1 / a0, nb2 = b2 / a0, na1 = a1 / a0, na2 = a2 / a0;
  const y = new Float32Array(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const v = nb0 * x[i] + nb1 * x1 + nb2 * x2 - na1 * y1 - na2 * y2;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = v; y[i] = v;
  }
  return y;
};

const band = (x, SR, lo, hi) => {
  let y = x;
  if (lo > 0) y = biquad(y, "hp", lo, 0.707, SR);
  if (hi > 0) y = biquad(y, "lp", hi, 0.707, SR);
  return y;
};

const noteName = (f) => {
  if (!f || !isFinite(f) || f < 20) return "-";
  const m = Math.round(69 + 12 * Math.log2(f / 440));
  const names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
  return names[((m % 12) + 12) % 12] + (Math.floor(m / 12) - 1) + ` (${f.toFixed(0)}Hz)`;
};

const analyze = (file) => {
  const {x, sr} = readMono(file);
  const dur = x.length / sr;
  let pk = 0;
  for (let i = 0; i < x.length; i++) pk = Math.max(pk, Math.abs(x[i]));

  // time to decay to -30 dB relative to peak (tail length)
  const peakIdx = (() => {
    let idx = 0, best = 0;
    for (let i = 0; i < x.length; i++) if (Math.abs(x[i]) > best) { best = Math.abs(x[i]); idx = i; }
    return idx;
  })();
  const win = Math.round(0.01 * sr);
  let tailIdx = x.length - 1;
  for (let a = x.length - win; a > peakIdx; a -= win) {
    if (rms(x, a, a + win) > pk * 0.0316) { tailIdx = a + win; break; }
  }

  const low = rms(band(x, sr, 0, 160));
  const body = rms(band(x, sr, 160, 1200));
  const pres = rms(band(x, sr, 1200, 6000));
  const air = rms(band(x, sr, 6000, 0));

  // pitch of the tail (last 300 ms) — catches bells and tonal impacts
  const tailStart = Math.max(peakIdx, x.length - Math.round(0.3 * sr));
  const seg = x.subarray(tailStart, x.length);
  let bestLag = 0, bestVal = -1;
  const minLag = Math.floor(sr / 2000), maxLag = Math.floor(sr / 80);
  for (let lag = minLag; lag < Math.min(maxLag, seg.length - 1); lag++) {
    let s = 0;
    for (let i = 0; i < seg.length - lag; i += 2) s += seg[i] * seg[i + lag];
    if (s > bestVal) { bestVal = s; bestLag = lag; }
  }
  const f0 = bestLag ? sr / bestLag : 0;

  return {
    file: path.basename(file),
    dur: +dur.toFixed(3),
    peak: +db(pk).toFixed(1),
    rms: +db(rms(x)).toFixed(1),
    body: +db(body).toFixed(1),
    low: +db(low).toFixed(1),
    presence: +db(pres).toFixed(1),
    air: +db(air).toFixed(1),
    tailAt30dB: +(tailIdx / sr).toFixed(2),
    f0: noteName(f0),
  };
};

const files = process.argv.slice(2);
const rows = files.map(analyze);
console.log(JSON.stringify(rows, null, 1));
