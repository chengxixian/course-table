/**
 * visualize-bgm.mjs — render a waveform + log-frequency spectrogram of the BGM
 * to PNG with zero dependencies (zlib only). Used as a non-auditory check that
 * every section has programme material, that the accents land where intended,
 * and that the spectrum has no runaway band.
 *
 *   node promo/audio/visualize-bgm.mjs promo/audio/bgm.wav promo/audio/analysis/bgm-spectrogram.png
 */
import fs from "node:fs";
import path from "node:path";
import zlib from "node:zlib";

const [, , inPath, outPath] = process.argv;
if (!inPath || !outPath) {
  console.error("usage: node visualize-bgm.mjs <in.wav> <out.png>");
  process.exit(2);
}

const buf = fs.readFileSync(inPath);
const channels = buf.readUInt16LE(22);
const SR = buf.readUInt32LE(24);
const bits = buf.readUInt16LE(34);
const dataSize = buf.readUInt32LE(40);
const frames = dataSize / (bits / 8) / channels;
const mono = new Float32Array(frames);
for (let i = 0; i < frames; i++) {
  let s = 0;
  for (let c = 0; c < channels; c++) {
    const off = 44 + i * channels * 2 + c * 2;
    s += buf.readInt16LE(off) / 32768;
  }
  mono[i] = s / channels;
}

const W = 1600;
const H_WAVE = 170;
const H_SPEC = 700;
const H = H_WAVE + H_SPEC;
const px = new Uint8Array(W * H * 3);
const set = (x, y, r, g, b) => {
  if (x < 0 || x >= W || y < 0 || y >= H) return;
  const i = (y * W + x) * 3;
  px[i] = r;
  px[i + 1] = g;
  px[i + 2] = b;
};

/* ---- waveform panel ---- */
const maxAmp = mono.reduce((m, v) => Math.max(m, Math.abs(v)), 1e-9);
for (let x = 0; x < W; x++) {
  const a = Math.floor((x * frames) / W);
  const b = Math.max(a + 1, Math.floor(((x + 1) * frames) / W));
  let lo = 0, hi = 0;
  for (let i = a; i < b; i++) {
    lo = Math.min(lo, mono[i]);
    hi = Math.max(hi, mono[i]);
  }
  const mid = H_WAVE / 2;
  const scale = (H_WAVE / 2 - 14) / maxAmp;
  const y0 = Math.round(mid - hi * scale);
  const y1 = Math.round(mid - lo * scale);
  for (let y = 0; y < H_WAVE; y++) {
    const grid = y === mid ? 40 : 18;
    set(x, y, grid, grid, grid + 6);
  }
  for (let y = y0; y <= y1; y++) set(x, y, 120, 220, 210);
}

/* ---- spectrogram panel ---- */
const NFFT = 2048;
const HOP = 512;
const win = new Float64Array(NFFT);
for (let i = 0; i < NFFT; i++) win[i] = 0.5 - 0.5 * Math.cos((2 * Math.PI * i) / (NFFT - 1));

const fft = (re, im) => {
  const n = re.length;
  for (let i = 1, j = 0; i < n; i++) {
    let bit = n >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) {
      let t = re[i]; re[i] = re[j]; re[j] = t;
      t = im[i]; im[i] = im[j]; im[j] = t;
    }
  }
  for (let len = 2; len <= n; len <<= 1) {
    const ang = (-2 * Math.PI) / len;
    const wr = Math.cos(ang), wi = Math.sin(ang);
    for (let i = 0; i < n; i += len) {
      let cr = 1, ci = 0;
      for (let k = 0; k < len / 2; k++) {
        const ar = re[i + k], ai = im[i + k];
        const br = re[i + k + len / 2] * cr - im[i + k + len / 2] * ci;
        const bi = re[i + k + len / 2] * ci + im[i + k + len / 2] * cr;
        re[i + k] = ar + br;
        im[i + k] = ai + bi;
        re[i + k + len / 2] = ar - br;
        im[i + k + len / 2] = ai - bi;
        const ncr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = ncr;
      }
    }
  }
};

const framesCount = Math.floor((frames - NFFT) / HOP);
const re = new Float64Array(NFFT);
const im = new Float64Array(NFFT);
const col = new Float64Array(framesCount);

// log-frequency bands
const fmin = 40, fmax = 18000;
const bands = H_SPEC;
const bandHz = new Float64Array(bands);
for (let y = 0; y < bands; y++) {
  const f = fmin * Math.pow(fmax / fmin, 1 - y / (bands - 1));
  bandHz[y] = f;
}

const palette = (v) => {
  // v in 0..1 -> magma-ish
  const stops = [
    [0, [4, 3, 12]],
    [0.28, [45, 18, 72]],
    [0.52, [125, 34, 96]],
    [0.72, [196, 63, 74]],
    [0.86, [240, 140, 55]],
    [1, [252, 255, 191]],
  ];
  for (let i = 1; i < stops.length; i++) {
    if (v <= stops[i][0]) {
      const [a, ca] = stops[i - 1];
      const [b, cb] = stops[i];
      const t = (v - a) / (b - a);
      return [
        Math.round(ca[0] + (cb[0] - ca[0]) * t),
        Math.round(ca[1] + (cb[1] - ca[1]) * t),
        Math.round(ca[2] + (cb[2] - ca[2]) * t),
      ];
    }
  }
  return stops[stops.length - 1][1];
};

for (let f = 0; f < framesCount; f++) {
  const start = f * HOP;
  for (let i = 0; i < NFFT; i++) {
    re[i] = mono[start + i] * win[i];
    im[i] = 0;
  }
  fft(re, im);
  const mag = new Float64Array(NFFT / 2);
  for (let i = 1; i < NFFT / 2; i++) mag[i] = Math.hypot(re[i], im[i]);
  // log-band max
  let lastBin = 1;
  for (let y = 0; y < bands; y++) {
    const f0 = bandHz[y];
    const f1 = y === 0 ? f0 * 1.04 : bandHz[y - 1];
    let i0 = Math.max(1, Math.floor((f0 / SR) * NFFT));
    let i1 = Math.min(NFFT / 2 - 1, Math.ceil((f1 / SR) * NFFT));
    if (i1 < i0) i1 = i0;
    let m = 0;
    for (let i = i0; i <= i1; i++) m = Math.max(m, mag[i]);
    const dbv = 20 * Math.log10(m / (NFFT / 4) + 1e-9);
    col[y] = Math.max(-95, Math.min(-6, dbv));
  }
  const x = Math.min(W - 1, Math.round((f * HOP) / (frames / W)));
  for (let y = 0; y < H_SPEC; y++) {
    const v = Math.max(0, Math.min(1, (col[y] + 82) / 70));
    const [r, g, b] = palette(v);
    set(x, H_WAVE + y, r, g, b);
  }
}

/* ---- section / bar markers ---- */
const shotFrames = [0, 150, 390, 540, 750, 930, 1080, 1200];
const shotTint = [[11, 87, 208], [255, 255, 255], [255, 255, 255], [255, 255, 255], [255, 176, 32], [255, 255, 255], [255, 82, 82]];
for (let i = 0; i < shotFrames.length - 1; i++) {
  const x = Math.round((shotFrames[i] / 1200) * W);
  for (let y = 0; y < H; y++) {
    if (i === 0) continue;
    set(x, y, 235, 235, 245);
    set(x + 1, y, 65, 65, 75);
  }
  // coloured section strip at the very top
  const x2 = Math.round((shotFrames[i + 1] / 1200) * W);
  for (let xx = x; xx < x2; xx++) {
    set(xx, 0, ...shotTint[i]);
    set(xx, 1, ...shotTint[i]);
    set(xx, 2, ...shotTint[i]);
  }
}
// bar ticks every 2 s (20 bars)
for (let bar = 1; bar < 20; bar++) {
  const x = Math.round(((bar * 60) / 1200) * W);
  for (let y = 3; y < 13; y++) set(x, y, 120, 120, 130);
}
// accent markers: snap 800, impact 1126, resolve 1142
for (const [fr, r, g, b] of [[800, 255, 210, 80], [1126, 255, 120, 120], [1142, 160, 255, 170]]) {
  const x = Math.round((fr / 1200) * W);
  for (let y = 0; y < H_WAVE; y += 2) set(x, y, r, g, b);
  set(x, H_WAVE, r, g, b);
  set(x, H_WAVE + 1, r, g, b);
}

/* ---- PNG encode ---- */
const crcTable = new Uint32Array(256);
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  crcTable[n] = c >>> 0;
}
const crc32 = (b) => {
  let c = 0xffffffff;
  for (let i = 0; i < b.length; i++) c = crcTable[(c ^ b[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const t = Buffer.from(type, "ascii");
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
};
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(W, 0);
ihdr.writeUInt32BE(H, 4);
ihdr[8] = 8;
ihdr[9] = 2;
ihdr[10] = 0;
ihdr[11] = 0;
ihdr[12] = 0;
const raw = Buffer.alloc((W * 3 + 1) * H);
for (let y = 0; y < H; y++) {
  raw[y * (W * 3 + 1)] = 0;
  Buffer.from(px.buffer, px.byteOffset + y * W * 3, W * 3).copy(raw, y * (W * 3 + 1) + 1);
}
const png = Buffer.concat([
  Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
  chunk("IHDR", ihdr),
  chunk("IDAT", zlib.deflateSync(raw, {level: 6})),
  chunk("IEND", Buffer.alloc(0)),
]);
fs.mkdirSync(path.dirname(path.resolve(outPath)), {recursive: true});
fs.writeFileSync(outPath, png);
console.log(JSON.stringify({png: path.resolve(outPath), width: W, height: H, spectrogramFrames: framesCount, sizeBytes: png.length}));
