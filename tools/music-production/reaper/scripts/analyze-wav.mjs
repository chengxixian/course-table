/**
 * analyze-wav.mjs — dependency-free PCM WAV inspector for the promo audio.
 *
 * Reports: format, duration, peak / RMS (dBFS), approximate BS.1770-4
 * integrated loudness (LUFS-I), 4x-interpolated true-peak estimate, DC offset,
 * clipped-sample count and L/R correlation. Used to verify numerically that a
 * bed cannot clip and to compare loudness between beds.
 *
 *   node promo/audio/analyze-wav.mjs <file.wav> [more.wav ...]
 */
import fs from "node:fs";

const readWav = (file) => {
  const buf = fs.readFileSync(file);
  if (buf.toString("ascii", 0, 4) !== "RIFF" || buf.toString("ascii", 8, 12) !== "WAVE") {
    throw new Error(`${file}: not a RIFF/WAVE file`);
  }
  let pos = 12;
  let fmt = null;
  let data = null;
  while (pos + 8 <= buf.length) {
    const id = buf.toString("ascii", pos, pos + 4);
    const size = buf.readUInt32LE(pos + 4);
    const body = pos + 8;
    if (id === "fmt ") {
      fmt = {
        format: buf.readUInt16LE(body),
        channels: buf.readUInt16LE(body + 2),
        sampleRate: buf.readUInt32LE(body + 4),
        byteRate: buf.readUInt32LE(body + 8),
        blockAlign: buf.readUInt16LE(body + 12),
        bits: buf.readUInt16LE(body + 14),
      };
    } else if (id === "data") {
      data = buf.subarray(body, Math.min(body + size, buf.length));
    }
    pos = body + size + (size & 1);
  }
  if (!fmt || !data) throw new Error(`${file}: missing fmt/data chunk`);
  if (fmt.format !== 1) throw new Error(`${file}: expected PCM (format ${fmt.format})`);
  const bytes = fmt.bits / 8;
  const frames = Math.floor(data.length / (bytes * fmt.channels));
  const chans = Array.from({ length: fmt.channels }, () => new Float32Array(frames));
  const read = (o) => {
    if (fmt.bits === 16) return data.readInt16LE(o) / 32768;
    if (fmt.bits === 24) return data.readIntLE(o, 3) / 8388608;
    if (fmt.bits === 32) return data.readInt32LE(o) / 2147483648;
    throw new Error(`unsupported bit depth ${fmt.bits}`);
  };
  for (let i = 0; i < frames; i++) {
    const base = i * bytes * fmt.channels;
    for (let c = 0; c < fmt.channels; c++) chans[c][i] = read(base + c * bytes);
  }
  return {...fmt, frames, chans, duration: frames / fmt.sampleRate};
};

/* ---- BS.1770-4 K-weighting (coefficients for 48 kHz) ---- */
const biquad = (b, a, x) => {
  const y = new Float32Array(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const acc = b[0] * x[i] + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2;
    y[i] = acc;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = acc;
  }
  return y;
};

const kWeight = (sr, x) => {
  // Exact-stage coefficients are specified at 48 kHz; for other rates fall
  // back to the same values (this project only ships 48 kHz).
  if (sr !== 48000) throw new Error("LUFS implementation is 48 kHz only");
  const shelfB = [1.53512485958697, -2.69169618940638, 1.19839281085285];
  const shelfA = [1, -1.69065929318241, 0.73248077421585];
  const hpB = [1.0, -2.0, 1.0];
  const hpA = [1, -1.99004745483398, 0.99007225036621];
  return biquad(hpB, hpA, biquad(shelfB, shelfA, x));
};

const lufs = (chans, sr) => {
  const kw = chans.map((c) => kWeight(sr, c));
  const block = Math.round(0.4 * sr);
  const hop = Math.round(0.1 * sr);
  const z = [];
  for (let start = 0; start + block <= kw[0].length; start += hop) {
    let sum = 0;
    for (const c of kw) {
      let ms = 0;
      for (let i = start; i < start + block; i++) ms += c[i] * c[i];
      sum += ms / block;
    }
    z.push(sum);
  }
  if (!z.length) return null;
  const l = (v) => -0.691 + 10 * Math.log10(Math.max(v, 1e-20));
  const ungated = z.reduce((s, v) => s + v, 0) / z.length;
  const relGate = Math.pow(10, (-10 + l(ungated)) / 10); // -10 LU below ungated
  const absGate = Math.pow(10, (-70 + 0.691) / 10); // -70 LUFS absolute
  const gated = z.filter((v) => v > absGate && v > relGate);
  if (!gated.length) return null;
  return l(gated.reduce((s, v) => s + v, 0) / gated.length);
};

const stats = (info) => {
  const {chans, frames, sampleRate, channels} = info;
  let peak = 0;
  let sumSq = 0;
  let dc = 0;
  let clipped = 0;
  let corrNum = 0, corrDenL = 0, corrDenR = 0;
  for (const c of chans) {
    for (let i = 0; i < frames; i++) {
      const v = c[i];
      const av = Math.abs(v);
      if (av > peak) peak = av;
      if (av >= 0.9999) clipped++;
      sumSq += v * v;
      dc += v;
    }
  }
  if (channels >= 2) {
    const L = chans[0], R = chans[1];
    for (let i = 0; i < frames; i++) {
      corrNum += L[i] * R[i];
      corrDenL += L[i] * L[i];
      corrDenR += R[i] * R[i];
    }
  }
  const rms = Math.sqrt(sumSq / (frames * channels));
  const db = (v) => 20 * Math.log10(Math.max(v, 1e-12));

  // 4x true-peak estimate (cubic Hermite between samples)
  let tp = peak;
  if (frames > 4) {
    for (let c = 0; c < channels; c++) {
      const x = chans[c];
      for (let i = 1; i < frames - 2; i++) {
        const xm1 = x[i - 1], x0 = x[i], x1 = x[i + 1], x2 = x[i + 2];
        for (let s = 1; s < 4; s++) {
          const t = s / 4;
          const t2 = t * t, t3 = t2 * t;
          const v =
            0.5 * (2 * x0 + (-xm1 + x1) * t + (2 * xm1 - 5 * x0 + 4 * x1 - x2) * t2 +
              (-xm1 + 3 * x0 - 3 * x1 + x2) * t3);
          if (Math.abs(v) > tp) tp = Math.abs(v);
        }
      }
    }
  }

  return {
    file: info.file,
    duration: +info.duration.toFixed(4),
    sampleRate,
    channels,
    bits: info.bits,
    peakDbfs: +db(peak).toFixed(2),
    truePeakDbfs: +db(tp).toFixed(2),
    rmsDbfs: +db(rms).toFixed(2),
    lufsI: lufs(chans, sampleRate) === null ? null : +lufs(chans, sampleRate).toFixed(1),
    dcOffsetDb: +db(Math.abs(dc / (frames * channels))).toFixed(1),
    clippedSamples: clipped,
    lrCorrelation: channels >= 2 && corrDenL > 0 && corrDenR > 0 ? +(corrNum / Math.sqrt(corrDenL * corrDenR)).toFixed(3) : null,
    samples: frames,
  };
};

const files = process.argv.slice(2);
if (!files.length) {
  console.error("usage: node analyze-wav.mjs <file.wav> [...]");
  process.exit(2);
}
const rows = files.map((f) => {
  const info = readWav(f);
  info.file = f;
  return stats(info);
});
console.log(JSON.stringify(rows.length === 1 ? rows[0] : rows, null, 2));
