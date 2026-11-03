/**
 * Offline mix verification: rebuilds the exact audio bus (BGM envelope + every
 * SFX hit from src/audio.tsx) in float32 and reports true peak / RMS / clipping.
 * This is a sample-accurate model of what Remotion mixes before AAC encoding.
 *
 *   node scripts/check-mix.mjs [--bgm audio/bgm/x.wav] [--volume 0.46] [--label v2-046]
 *
 * Supports 16/24/32-bit PCM and 32-bit float WAV.
 */
import fs from "node:fs";
import path from "node:path";
import {pathToFileURL} from "node:url";
import {build} from "esbuild";

const args = process.argv.slice(2);
const argOf = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : dflt;
};
const BGM_REL = argOf("bgm", "audio/bgm/bgm-final.wav");
const BGM_VOL = Number(argOf("volume", "0.5"));
const LABEL = argOf("label", path.basename(BGM_REL, ".wav") + "-" + BGM_VOL);
const SFX_GAIN = Number(argOf("sfxGain", "1"));

const SR = 48000;
const FPS = 60;
const DURATION_FRAMES = 2400;
const N = Math.round((DURATION_FRAMES / FPS) * SR);

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
    if (id === "fmt ") {
      fmt = {
        format: b.readUInt16LE(off + 8),
        ch: b.readUInt16LE(off + 10),
        sr: b.readUInt32LE(off + 12),
        bits: b.readUInt16LE(off + 22),
      };
    }
    if (id === "data") {
      dataOff = off + 8;
      dataLen = Math.min(sz, b.length - dataOff);
    }
    off += 8 + sz + (sz % 2);
  }
  if (!fmt || dataOff < 0) throw new Error(`no fmt/data chunk: ${file}`);
  if (fmt.sr !== SR) throw new Error(`expected 48k, got ${fmt.sr}: ${file}`);

  const bytes = fmt.bits / 8;
  const frames = Math.floor(dataLen / (bytes * fmt.ch));
  const l = new Float32Array(frames);
  const r = new Float32Array(frames);
  const readSample = (o) => {
    if (fmt.format === 3 && fmt.bits === 32) return b.readFloatLE(o);
    if (fmt.bits === 16) return b.readInt16LE(o) / 32768;
    if (fmt.bits === 24) {
      const v = b[o] | (b[o + 1] << 8) | (b[o + 2] << 16);
      return (v & 0x800000 ? v - 0x1000000 : v) / 8388608;
    }
    if (fmt.bits === 32) return b.readInt32LE(o) / 2147483648;
    throw new Error(`unsupported ${fmt.bits}-bit sample in ${file}`);
  };
  for (let i = 0; i < frames; i++) {
    const o = dataOff + i * bytes * fmt.ch;
    l[i] = readSample(o);
    r[i] = fmt.ch > 1 ? readSample(o + bytes) : l[i];
  }
  return {l, r, frames, bits: fmt.bits, channels: fmt.ch};
};

// bundle the real SFX table out of the TSX so this check can never drift
await build({
  entryPoints: [path.resolve("src/audio.tsx")],
  bundle: true,
  platform: "node",
  format: "esm",
  outfile: path.resolve("out/audio-table.mjs"),
  external: ["remotion", "react"],
  logLevel: "error",
});
const {SFX} = await import(pathToFileURL(path.resolve("out/audio-table.mjs")).href);

const FS = FPS / 30;
const mixL = new Float32Array(N);
const mixR = new Float32Array(N);

// --- BGM: same 24-frame fade-in to the requested level as src/audio.tsx
const bgm = readWav(path.resolve("public", BGM_REL));
let bgmPeak = 0;
for (let i = 0; i < Math.min(N, bgm.frames); i++) {
  const f = (i / SR) * FPS;
  const vol = f >= 24 ? BGM_VOL : (f / 24) * BGM_VOL;
  mixL[i] += bgm.l[i] * vol;
  mixR[i] += bgm.r[i] * vol;
  bgmPeak = Math.max(bgmPeak, Math.abs(bgm.l[i] * vol), Math.abs(bgm.r[i] * vol));
}

// --- SFX one-shots at from*FS delivery frames
let sfxPeak = 0;
const rows = [];
for (const hit of SFX) {
  const wav = readWav(path.resolve("public/audio/sfx", hit.src));
  const start = Math.round(((hit.from * FS) / FPS) * SR);
  let localPeak = 0;
  for (let i = 0; i < wav.frames; i++) {
    const j = start + i;
    if (j < 0 || j >= N) continue;
    const l = wav.l[i] * hit.volume * SFX_GAIN;
    const r = wav.r[i] * hit.volume * SFX_GAIN;
    mixL[j] += l;
    mixR[j] += r;
    localPeak = Math.max(localPeak, Math.abs(l), Math.abs(r));
  }
  sfxPeak = Math.max(sfxPeak, localPeak);
  rows.push({from: hit.from, src: hit.src, volume: hit.volume * SFX_GAIN, peak: +localPeak.toFixed(3)});
}

// --- report
let peak = 0;
let clipped = 0;
let sumSq = 0;
for (let i = 0; i < N; i++) {
  const l = Math.abs(mixL[i]);
  const r = Math.abs(mixR[i]);
  peak = Math.max(peak, l, r);
  if (l > 1 || r > 1) clipped++;
  sumSq += mixL[i] * mixL[i] + mixR[i] * mixR[i];
}
const db = (v) => +(20 * Math.log10(Math.max(v, 1e-9))).toFixed(2);
const rms = Math.sqrt(sumSq / (N * 2));

const win = SR / 2;
let loudestAt = 0;
let loudestVal = 0;
for (let w = 0; w + win < N; w += win) {
  let p = 0;
  for (let i = w; i < w + win; i++) p = Math.max(p, Math.abs(mixL[i]), Math.abs(mixR[i]));
  if (p > loudestVal) {
    loudestVal = p;
    loudestAt = w;
  }
}

const report = {
  label: LABEL,
  bgm: BGM_REL,
  bgmBits: bgm.bits,
  bgmVolume: BGM_VOL,
  sfxGain: SFX_GAIN,
  durationSec: +(N / SR).toFixed(3),
  bgmPeakDbfs: db(bgmPeak),
  sfxPeakDbfs: db(sfxPeak),
  peakDeltaDb: +(db(sfxPeak) - db(bgmPeak)).toFixed(2),
  mixPeakDbfs: db(peak),
  mixRmsDbfs: db(rms),
  clippedSamples: clipped,
  headroomDb: -db(peak),
  loudestHalfSecondAtSec: +(loudestAt / SR).toFixed(2),
  sfxCount: rows.length,
};
console.log(JSON.stringify(report, null, 2));

// append to a running A/B log so several candidates can be compared
const logPath = path.resolve("out/mix-ab.jsonl");
fs.mkdirSync(path.dirname(logPath), {recursive: true});
fs.appendFileSync(logPath, JSON.stringify(report) + "\n");
console.log("\n[ab] appended to out/mix-ab.jsonl");
