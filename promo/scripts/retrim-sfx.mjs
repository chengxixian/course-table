/**
 * retrim-sfx.mjs — cut Freesound candidates into the promo's cue slots.
 *
 * For every cue it
 *   1. decodes the source to 48 kHz mono float,
 *   2. finds the onset (first sample within 40 dB of the peak) — or, for
 *      "tail" cues, keeps the END of the file so the build-up lands on the hit,
 *   3. cuts `dur` seconds (+ 5 ms pre-roll), applies a 25 ms fade-out so the
 *      cut cannot click,
 *   4. normalises the peak to the level the synthesized placeholder had, so the
 *      existing per-cue volumes and the BGM↔SFX peak balance stay valid,
 *   5. writes 48 kHz / 16-bit / stereo WAV.
 *
 *   node retrim-sfx.mjs --in <candidatesDir> --out <stagingDir> [--apply <sfxDir>]
 *
 * --apply copies the results over the real cue files in public/audio/sfx/.
 */
import fs from "node:fs";
import path from "node:path";
import {execFileSync} from "node:child_process";

const FF = "D:\\hsu_flutter\\promo\\remotion\\node_modules\\@remotion\\compositor-win32-x64-msvc\\ffmpeg.exe";

const argv = process.argv.slice(2);
const argOf = (n, d) => {
  const i = argv.indexOf(`--${n}`);
  return i >= 0 && argv[i + 1] !== undefined ? argv[i + 1] : d;
};

const IN = argOf("in", "promo/.work/sfx-wav");
const OUT = argOf("out", "promo/.work/sfx-final");
const APPLY = argOf("apply", null);

/** cue -> {src, dur, mode, peakDb, note} */
const PLAN = {
  "swish.wav": {src: "fs_71852_digital_whoosh_soft-wav.wav", dur: 0.5, mode: "head", peakDb: -12,
    note: "fs:71852 digital_whoosh_soft (CC0) — soft digital whoosh for phone/wordmark moves"},
  "paper-slide.wav": {src: "fs_464302_PaperSlide-wav.wav", dur: 0.34, mode: "head", peakDb: -6,
    note: "fs:464302 PaperSlide (CC0) — real paper across a table"},
  "stamp.wav": {src: "fs_555545_wood_block-ogg.wav", dur: 0.14, mode: "head", peakDb: -4,
    note: "fs:555545 wood_block (CC0) — wood tok for course blocks landing; cut to 0.14 s so the pitched ring is not audible"},
  "pop.wav": {src: "fs_733264_Bubble_Pop.wav", dur: 0.16, mode: "head", peakDb: -10,
    note: "fs:733264 Bubble_Pop (CC0) — UI tap"},
  "snap.wav": {src: "fs_478197_Click_1-wav.wav", dur: 0.09, mode: "head", peakDb: -9,
    note: "fs:478197 Click_1 (CC0) — crisp click for the slot-in snap"},
  "key.wav": {src: "fs_701113_Computer-Keyboard-Foley-Percussion.wav", dur: 0.08, mode: "head", peakDb: -14,
    note: "fs:701113 Computer Keyboard Foley Percussion (CC0) — single key"},
  "riser.wav": {src: "fs_511872_Riser-Hit-sfx-025-wav.wav", dur: 1.55, mode: "tail", peakDb: -14,
    note: "fs:511872 Riser Hit sfx 025 (CC0) — tail cut so the crest lands on the impact"},
  "impact.wav": {src: "fs_511883_Impact-sfx-017-wav.wav", dur: 0.9, mode: "head", peakDb: -6,
    note: "fs:511883 Impact sfx 017 (CC0) — final slam"},
};

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
      s += fmt.bits === 16 ? data.readInt16LE(o) / 32768 : data.readIntLE(o, 3) / 8388608;
    }
    x[i] = s / fmt.ch;
  }
  return {x, sr: fmt.sr};
};

const readStereo = (file) => {
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
  const out = [];
  for (let c = 0; c < fmt.ch; c++) out.push(new Float32Array(frames));
  for (let i = 0; i < frames; i++) {
    for (let c = 0; c < fmt.ch; c++) {
      const o = i * bytes * fmt.ch + c * bytes;
      out[c][i] = fmt.bits === 16 ? data.readInt16LE(o) / 32768 : data.readIntLE(o, 3) / 8388608;
    }
  }
  return {chans: out, sr: fmt.sr, ch: fmt.ch};
};

const writeWav = (file, chans, sr) => {
  const ch = chans.length;
  const frames = chans[0].length;
  const dataBytes = frames * ch * 2;
  const buf = Buffer.alloc(44 + dataBytes);
  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + dataBytes, 4);
  buf.write("WAVE", 8);
  buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16);
  buf.writeUInt16LE(1, 20);
  buf.writeUInt16LE(ch, 22);
  buf.writeUInt32LE(sr, 24);
  buf.writeUInt32LE(sr * ch * 2, 28);
  buf.writeUInt16LE(ch * 2, 32);
  buf.writeUInt16LE(16, 34);
  buf.write("data", 36);
  buf.writeUInt32LE(dataBytes, 40);
  let o = 44;
  for (let i = 0; i < frames; i++) {
    for (let c = 0; c < ch; c++) {
      const v = Math.max(-1, Math.min(1, chans[c][i]));
      buf.writeInt16LE(Math.round(v * 32767), o);
      o += 2;
    }
  }
  fs.writeFileSync(file, buf);
};

const db = (v) => (v <= 1e-12 ? -120 : 20 * Math.log10(v));

const decode = (mp3Path, wavPath) => {
  execFileSync(FF, ["-hide_banner", "-loglevel", "error", "-i", mp3Path, "-ac", "1", "-ar", "48000", "-c:a", "pcm_s16le", "-y", wavPath]);
};

fs.mkdirSync(OUT, {recursive: true});

const results = [];
for (const [cue, p] of Object.entries(PLAN)) {
  const srcWav = path.join(IN, p.src);
  if (!fs.existsSync(srcWav)) throw new Error(`missing candidate ${srcWav}`);
  const {x, sr} = readMono(srcWav);

  let pk = 0;
  for (let i = 0; i < x.length; i++) pk = Math.max(pk, Math.abs(x[i]));
  const thresh = pk * 0.01;
  let onset = 0;
  for (let i = 0; i < x.length; i++) if (Math.abs(x[i]) > thresh) { onset = i; break; }

  const n = Math.round(p.dur * sr);
  let start;
  if (p.mode === "tail") {
    start = Math.max(0, x.length - n);
  } else {
    start = Math.max(0, onset - Math.round(0.005 * sr));
    if (start + n > x.length) start = Math.max(0, x.length - n);
  }
  const len = Math.min(n, x.length - start);
  const seg = new Float32Array(len);
  for (let i = 0; i < len; i++) seg[i] = x[start + i];

  // 25 ms fade-out on the cut edge
  const fade = Math.min(Math.round(0.025 * sr), len);
  for (let i = 0; i < fade; i++) {
    const g = 0.5 - 0.5 * Math.cos((Math.PI * i) / fade);
    seg[len - 1 - i] *= g;
  }
  // 3 ms fade-in at the head
  const fin = Math.min(Math.round(0.003 * sr), len);
  for (let i = 0; i < fin; i++) seg[i] *= 0.5 - 0.5 * Math.cos((Math.PI * i) / fin);

  let segPk = 0;
  for (let i = 0; i < len; i++) segPk = Math.max(segPk, Math.abs(seg[i]));
  const gain = Math.pow(10, (p.peakDb - db(segPk)) / 20);
  const L = new Float32Array(len), R = new Float32Array(len);
  for (let i = 0; i < len; i++) {
    const v = seg[i] * gain;
    L[i] = v;
    R[i] = v;
  }
  const outFile = path.join(OUT, cue);
  writeWav(outFile, [L, R], sr);

  // verify what we actually wrote
  const check = readStereo(outFile);
  let outPk = 0, sum = 0;
  for (let i = 0; i < check.chans[0].length; i++) {
    outPk = Math.max(outPk, Math.abs(check.chans[0][i]));
    sum += check.chans[0][i] * check.chans[0][i];
  }
  results.push({
    cue,
    src: path.basename(p.src),
    dur: +(len / sr).toFixed(3),
    onsetUsed: +(start / sr).toFixed(3),
    peakDb: +db(outPk).toFixed(2),
    rmsDb: +db(Math.sqrt(sum / check.chans[0].length)).toFixed(2),
    note: p.note,
  });
}

console.table(results);
fs.writeFileSync(path.join(OUT, "sfx-manifest.json"), JSON.stringify(results, null, 2));

if (APPLY) {
  fs.mkdirSync(APPLY, {recursive: true});
  for (const r of results) {
    fs.copyFileSync(path.join(OUT, r.cue), path.join(APPLY, r.cue));
  }
  console.log(`\napplied ${results.length} files -> ${APPLY}`);
}
