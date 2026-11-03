/**
 * Two-stage master DSP for the promo.
 *
 * Stage 1 — soft-knee bus compressor (stereo-linked, RMS detector)
 *   threshold −24 dBFS, ratio 2.5:1, knee 8 dB, attack 15 ms, release 150 ms,
 *   makeup 0 (the global loudnorm gain supplies the level afterwards).
 *   Purpose: spread the energy reduction over the whole programme instead of
 *   shaving two isolated peaks, so the end-card impact keeps its weight.
 *
 * Stage 2 — look-ahead limiter with a RAMPED attack
 *   the required gain descends linearly across the whole look-ahead window and
 *   is exactly at target when the peak arrives (no step at the window edge),
 *   release 150 ms, ceiling 0.75 (≈ −2.5 dBFS; AAC overshoot measured +0.47 dB).
 *
 *   node scripts/master-audio.mjs --in a.wav --out b.wav --gain 6.9 \
 *        [--ceiling 0.75] [--comp on|off] [--comp-threshold -24] [--comp-ratio 2.5] \
 *        [--comp-knee 8] [--comp-attack-ms 15] [--comp-release-ms 150] \
 *        [--attack-ms 4] [--release-ms 150]
 */
import fs from "node:fs";

const args = process.argv.slice(2);
const argOf = (n, d) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : d;
};

const IN = argOf("in", null);
const OUT = argOf("out", null);
if (!IN || !OUT) {
  console.error("usage: node scripts/master-audio.mjs --in <wav> --out <wav> --gain <dB>");
  process.exit(2);
}

const GAIN_DB = Number(argOf("gain", "0"));
const CEILING = Number(argOf("ceiling", "0.75"));
const ATTACK_MS = Number(argOf("attack-ms", "4"));
const RELEASE_MS = Number(argOf("release-ms", "150"));
const COMP = argOf("comp", "on") !== "off";
const CT = Number(argOf("comp-threshold", "-24"));
const CR = Number(argOf("comp-ratio", "2.5"));
const CK = Number(argOf("comp-knee", "8"));
const CA = Number(argOf("comp-attack-ms", "15"));
const CRel = Number(argOf("comp-release-ms", "150"));

const readWav = (file) => {
  const b = fs.readFileSync(file);
  if (b.toString("ascii", 0, 4) !== "RIFF") throw new Error(`not RIFF: ${file}`);
  let off = 12;
  let fmt = null;
  let dataOff = -1;
  let dataLen = 0;
  while (off + 8 <= b.length) {
    const id = b.toString("ascii", off, off + 4);
    const sz = b.readUInt32LE(off + 4);
    if (id === "fmt ") fmt = {format: b.readUInt16LE(off + 8), ch: b.readUInt16LE(off + 10), sr: b.readUInt32LE(off + 12), bits: b.readUInt16LE(off + 22)};
    if (id === "data") { dataOff = off + 8; dataLen = Math.min(sz, b.length - dataOff); }
    off += 8 + sz + (sz % 2);
  }
  if (!fmt || dataOff < 0) throw new Error(`no fmt/data: ${file}`);
  const bytes = fmt.bits / 8;
  const frames = Math.floor(dataLen / (bytes * fmt.ch));
  const chans = [];
  for (let c = 0; c < fmt.ch; c++) chans.push(new Float32Array(frames));
  const rd = (o) => {
    if (fmt.format === 3 && fmt.bits === 32) return b.readFloatLE(o);
    if (fmt.bits === 16) return b.readInt16LE(o) / 32768;
    if (fmt.bits === 24) {
      const v = b[o] | (b[o + 1] << 8) | (b[o + 2] << 16);
      return (v & 0x800000 ? v - 0x1000000 : v) / 8388608;
    }
    if (fmt.bits === 32) return b.readInt32LE(o) / 2147483648;
    throw new Error(`unsupported ${fmt.bits}-bit`);
  };
  for (let i = 0; i < frames; i++) {
    const o = dataOff + i * bytes * fmt.ch;
    for (let c = 0; c < fmt.ch; c++) chans[c][i] = rd(o + c * bytes);
  }
  return {chans, frames, sr: fmt.sr, bits: fmt.bits};
};

const writeWav24 = (file, chans, sr) => {
  const ch = chans.length;
  const frames = chans[0].length;
  const dataBytes = frames * ch * 3;
  const buf = Buffer.alloc(44 + dataBytes);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + dataBytes, 4);
  buf.write("WAVE", 8);
  buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);
  buf.writeUInt16LE(ch, 22);
  buf.writeUInt32LE(sr, 24);
  buf.writeUInt32LE(sr * ch * 3, 28);
  buf.writeUInt16LE(ch * 3, 32);
  buf.writeUInt16LE(24, 34);
  buf.write("data", 36);
  buf.writeUInt32LE(dataBytes, 40);
  let o = 44;
  const clip = (v) => Math.max(-1, Math.min(1, v));
  for (let i = 0; i < frames; i++) {
    for (let c = 0; c < ch; c++) {
      const v = Math.round(clip(chans[c][i]) * 8388607);
      buf[o++] = v & 0xff;
      buf[o++] = (v >> 8) & 0xff;
      buf[o++] = (v >> 16) & 0xff;
    }
  }
  fs.writeFileSync(file, buf);
};

const src = readWav(IN);
const sr = src.sr;
const n = src.frames;
const nch = src.chans.length;

// ---------- 0) working copy (compressor runs at programme level, BEFORE the gain) ----------
const gain = Math.pow(10, GAIN_DB / 20);
const chans = src.chans.map((c) => {
  const out = new Float32Array(c.length);
  for (let i = 0; i < c.length; i++) out[i] = c[i];
  return out;
});

const link = new Float32Array(n);
for (let i = 0; i < n; i++) {
  let p = 0;
  for (let c = 0; c < nch; c++) p = Math.max(p, Math.abs(chans[c][i]));
  link[i] = p;
}

// ---------- 1) soft-knee bus compressor (RMS detector, stereo linked) ----------
const comp = {enabled: COMP, thresholdDb: CT, ratio: CR, kneeDb: CK, attackMs: CA, releaseMs: CRel};
if (COMP) {
  const boxLen = Math.max(1, Math.round(0.01 * sr)); // 10 ms RMS window
  const powArr = new Float32Array(n);
  for (let i = 0; i < n; i++) powArr[i] = link[i] * link[i];
  const pre = new Float64Array(n + 1);
  for (let i = 0; i < n; i++) pre[i + 1] = pre[i] + powArr[i];

  const aCoef = 1 - Math.exp(-1 / ((CA / 1000) * sr)); // attack (dB domain)
  const rCoef = 1 - Math.exp(-1 / ((CRel / 1000) * sr)); // release
  let gr = 0;
  let maxGr = 0;
  let sumGr = 0;
  let grSamples = 0;
  const gainArr = new Float32Array(n);

  for (let i = 0; i < n; i++) {
    const a = Math.max(0, i - boxLen + 1);
    const rms = Math.sqrt(Math.max(1e-12, (pre[i + 1] - pre[a]) / (i - a + 1)));
    const lvl = 20 * Math.log10(Math.max(rms, 1e-9));
    const x = lvl - CT;
    let target = 0;
    if (2 * x < -CK) target = 0;
    else if (Math.abs(2 * x) <= CK) target = (1 / CR - 1) * Math.pow(x + CK / 2, 2) / (2 * CK);
    else target = (1 / CR - 1) * x;

    if (target < gr) gr = gr + (target - gr) * aCoef;
    else gr = gr + (target - gr) * rCoef;
    if (gr < -0.001) {
      grSamples++;
      sumGr += gr;
      if (gr < maxGr) maxGr = gr;
    }
    gainArr[i] = Math.pow(10, gr / 20);
  }
  for (let c = 0; c < nch; c++) {
    const ch = chans[c];
    for (let i = 0; i < n; i++) ch[i] *= gainArr[i];
  }
  comp.maxGainReductionDb = +(-maxGr).toFixed(2);
  comp.avgGainReductionDb = +(grSamples ? -sumGr / grSamples : 0).toFixed(2);
  comp.activeSamples = grSamples;
  comp.activeRatio = +(grSamples / n).toFixed(3);
}

// ---------- 1b) loudness gain (after compression, before limiting) ----------
for (let c = 0; c < nch; c++) {
  const ch = chans[c];
  for (let i = 0; i < n; i++) ch[i] *= gain;
}

// ---------- 2) ramped look-ahead limiter ----------
const look = Math.max(1, Math.round((ATTACK_MS / 1000) * sr));
const relStep = 1 / Math.max(1, (RELEASE_MS / 1000) * sr);

const peak = new Float32Array(n);
for (let i = 0; i < n; i++) {
  let p = 0;
  for (let c = 0; c < nch; c++) p = Math.max(p, Math.abs(chans[c][i]));
  peak[i] = p;
}

const hot = [];
for (let i = 0; i < n; i++) if (peak[i] > CEILING) hot.push(i);

const gArr = new Float32Array(n).fill(1);
let maxRed = 0;
let sumRed = 0;
let redN = 0;
if (hot.length) {
  // linear descent over the whole look-ahead window, at target when the peak hits
  let hi = 0;
  for (let i = 0; i < n; i++) {
    while (hi < hot.length && hot[hi] < i) hi++;
    let g = 1;
    for (let k = hi; k < hot.length && hot[k] < i + look; k++) {
      const p = hot[k];
      const target = CEILING / peak[p];
      const w = (p - i) / look; // 0 at the peak, 1 at the far edge of the window
      const ramp = target + (1 - target) * w;
      if (ramp < g) g = ramp;
    }
    gArr[i] = g;
  }
  let g = 1;
  for (let i = 0; i < n; i++) {
    const target = gArr[i];
    if (target < g) g = target;
    else g = Math.min(1, g + relStep);
    gArr[i] = g;
    if (g < 0.999) {
      const red = -20 * Math.log10(Math.max(g, 1e-6));
      sumRed += red;
      redN++;
      if (red > maxRed) maxRed = red;
    }
  }
}

for (let c = 0; c < nch; c++) {
  const ch = chans[c];
  for (let i = 0; i < n; i++) ch[i] *= gArr[i];
}

let hardClamped = 0;
for (let c = 0; c < nch; c++) {
  const ch = chans[c];
  for (let i = 0; i < n; i++) {
    if (ch[i] > 1 || ch[i] < -1) {
      ch[i] = Math.max(-1, Math.min(1, ch[i]));
      hardClamped++;
    }
  }
}

let peakBefore = 0;
let peakAfter = 0;
for (let c = 0; c < nch; c++) {
  for (let i = 0; i < n; i++) {
    peakBefore = Math.max(peakBefore, Math.abs(src.chans[c][i]) * gain);
    peakAfter = Math.max(peakAfter, Math.abs(chans[c][i]));
  }
}

writeWav24(OUT, chans, sr);
const db = (v) => +(20 * Math.log10(Math.max(v, 1e-9))).toFixed(2);
console.log(
  JSON.stringify(
    {
      in: IN,
      out: OUT,
      gainDb: +GAIN_DB.toFixed(2),
      ceiling: CEILING,
      limiter: {
        attackMs: ATTACK_MS,
        releaseMs: RELEASE_MS,
        maxReductionDb: +maxRed.toFixed(2),
        avgReductionDb: +(redN ? sumRed / redN : 0).toFixed(2),
        hotSamples: hot.length,
      },
      compressor: comp,
      peakAfterGainDbfs: db(peakBefore),
      peakAfterLimiterDbfs: db(peakAfter),
      hardClampedSamples: hardClamped,
      frames: n,
      sampleRate: sr,
    },
    null,
    2,
  ),
);
