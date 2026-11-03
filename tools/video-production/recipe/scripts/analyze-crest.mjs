/**
 * Crest / impact analysis for the acceptance criteria.
 *
 *   node scripts/analyze-crest.mjs --in <wav> [--impact 37.5] [--window 0.5]
 *
 * Reports: overall RMS/peak, the loudest 0.5 s window (start + level), and the
 * crest of the end-card impact versus the preceding 5 s of programme.
 */
import fs from "node:fs";

const args = process.argv.slice(2);
const argOf = (n, d) => {
  const i = args.indexOf(`--${n}`);
  return i >= 0 && args[i + 1] !== undefined ? args[i + 1] : d;
};

const IN = argOf("in", null);
const IMPACT_SEC = Number(argOf("impact", "37.5"));
const WIN = Number(argOf("window", "0.5"));
const PREV = Number(argOf("prev", "5"));
if (!IN) {
  console.error("usage: node scripts/analyze-crest.mjs --in <wav>");
  process.exit(2);
}

const readWav = (file) => {
  const b = fs.readFileSync(file);
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
  const bytes = fmt.bits / 8;
  const frames = Math.floor(dataLen / (bytes * fmt.ch));
  const mono = new Float32Array(frames);
  const rd = (o) => {
    if (fmt.format === 3 && fmt.bits === 32) return b.readFloatLE(o);
    if (fmt.bits === 16) return b.readInt16LE(o) / 32768;
    if (fmt.bits === 24) {
      const v = b[o] | (b[o + 1] << 8) | (b[o + 2] << 16);
      return (v & 0x800000 ? v - 0x1000000 : v) / 8388608;
    }
    if (fmt.bits === 32) return b.readInt32LE(o) / 2147483648;
    throw new Error("unsupported bit depth");
  };
  for (let i = 0; i < frames; i++) {
    const o = dataOff + i * bytes * fmt.ch;
    let s = 0;
    for (let c = 0; c < fmt.ch; c++) s += rd(o + c * bytes);
    mono[i] = s / fmt.ch;
  }
  return {mono, frames, sr: fmt.sr};
};

const {mono, frames, sr} = readWav(IN);
const db = (v) => +(20 * Math.log10(Math.max(v, 1e-9))).toFixed(2);

let peak = 0;
let sumSq = 0;
for (let i = 0; i < frames; i++) {
  const a = Math.abs(mono[i]);
  if (a > peak) peak = a;
  sumSq += mono[i] * mono[i];
}
const overallRms = Math.sqrt(sumSq / frames);

// loudest WIN-second window
const winN = Math.round(WIN * sr);
let bestAt = 0;
let bestSq = -1;
for (let start = 0; start + winN <= frames; start += winN) { // 0.5 s grid aligned to 0, same as the reviewer's method
  let s = 0;
  for (let i = start; i < start + winN; i++) s += mono[i] * mono[i];
  if (s > bestSq) {
    bestSq = s;
    bestAt = start;
  }
}
const bestRms = Math.sqrt(bestSq / winN);
// peak inside that window
let bestPeak = 0;
for (let i = bestAt; i < Math.min(frames, bestAt + winN); i++) bestPeak = Math.max(bestPeak, Math.abs(mono[i]));

// impact crest: peak of [impact, impact+WIN) vs RMS of [impact-PREV, impact)
const i0 = Math.round(IMPACT_SEC * sr);
const i1 = Math.min(frames, i0 + winN);
let impactPeak = 0;
for (let i = i0; i < i1; i++) impactPeak = Math.max(impactPeak, Math.abs(mono[i]));
const p0 = Math.max(0, i0 - Math.round(PREV * sr));
let prevSq = 0;
for (let i = p0; i < i0; i++) prevSq += mono[i] * mono[i];
const prevRms = Math.sqrt(prevSq / Math.max(1, i0 - p0));

console.log(
  JSON.stringify(
    {
      file: IN,
      durationSec: +(frames / sr).toFixed(3),
      overallRmsDbfs: db(overallRms),
      peakDbfs: db(peak),
      loudestHalfSecondAtSec: +(bestAt / sr).toFixed(2),
      loudestHalfSecondRmsDbfs: db(bestRms),
      loudestHalfSecondPeakDbfs: db(bestPeak),
      crest: {
        impactAtSec: IMPACT_SEC,
        impactPeakDbfs: db(impactPeak),
        prevWindowSec: PREV,
        prevRmsDbfs: db(prevRms),
        crestDb: +(db(impactPeak) - db(prevRms)).toFixed(2),
      },
    },
    null,
    2,
  ),
);
