/**
 * spectral-report.mjs — calibrated octave-band report for a 48 kHz stereo WAV.
 * Used to check that the BGM is warm (energy concentrated low-mid) and that no
 * band runs away, without relying on playback.
 *
 *   node promo/audio/spectral-report.mjs promo/audio/bgm.wav [reference.wav]
 */
import fs from "node:fs";

const readWav = (file) => {
  const b = fs.readFileSync(file);
  let pos = 12;
  let fmt = null;
  let data = null;
  while (pos + 8 <= b.length) {
    const id = b.toString("ascii", pos, pos + 4);
    const sz = b.readUInt32LE(pos + 4);
    const body = pos + 8;
    if (id === "fmt ") {
      fmt = {
        format: b.readUInt16LE(body),
        ch: b.readUInt16LE(body + 2),
        sr: b.readUInt32LE(body + 4),
        bits: b.readUInt16LE(body + 14),
      };
    } else if (id === "data") {
      data = b.subarray(body, body + sz);
    }
    pos = body + sz + (sz & 1);
  }
  if (!fmt || !data) throw new Error(`${file}: missing fmt/data`);
  const bytes = fmt.bits / 8;
  const n = Math.floor(data.length / bytes / fmt.ch);
  const mono = new Float32Array(n);
  for (let i = 0; i < n; i++) {
    let s = 0;
    for (let c = 0; c < fmt.ch; c++) {
      const off = i * fmt.ch * bytes + c * bytes;
      const v =
        fmt.bits === 16
          ? data.readInt16LE(off) / 32768
          : fmt.bits === 24
            ? data.readIntLE(off, 3) / 8388608
            : data.readInt32LE(off) / 2147483648;
      s += v / fmt.ch;
    }
    mono[i] = s;
  }
  return {mono, sr: fmt.sr, n};
};

const NFFT = 4096;
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

const BANDS = [
  ["sub", 20, 63],
  ["low", 63, 125],
  ["lowmid", 125, 250],
  ["mid", 250, 500],
  ["mid2", 500, 1000],
  ["himid", 1000, 2000],
  ["presence", 2000, 4000],
  ["high", 4000, 8000],
  ["air", 8000, 16000],
  ["top", 16000, 24000],
];

const analyzeRange = (mono, sr, from, to) => {
  const hop = 1024;
  const a = Math.max(0, Math.floor(from * sr));
  const b = Math.min(mono.length, Math.floor(to * sr));
  const re = new Float64Array(NFFT);
  const im = new Float64Array(NFFT);
  const sums = BANDS.map(() => 0);
  let frames = 0, total = 0, centroidNum = 0;
  for (let s = a; s + NFFT <= b; s += hop) {
    for (let i = 0; i < NFFT; i++) {
      re[i] = mono[s + i] * win[i];
      im[i] = 0;
    }
    fft(re, im);
    for (let i = 1; i < NFFT / 2; i++) {
      const hz = (i * sr) / NFFT;
      const p = re[i] * re[i] + im[i] * im[i];
      total += p;
      centroidNum += p * hz;
      for (let bi = 0; bi < BANDS.length; bi++) {
        if (hz >= BANDS[bi][1] && hz < BANDS[bi][2]) {
          sums[bi] += p;
          break;
        }
      }
    }
    frames++;
  }
  const amp = (p) => Math.sqrt(p / Math.max(frames, 1) / (NFFT / 4) ** 2);
  const out = {};
  for (let bi = 0; bi < BANDS.length; bi++) out[BANDS[bi][0]] = +(20 * Math.log10(Math.max(amp(sums[bi]), 1e-12))).toFixed(1);
  return {
    bandsDbfs: out,
    spectralCentroidHz: frames ? Math.round(centroidNum / total) : null,
    overallDbfs: +(10 * Math.log10(Math.max(total / Math.max(frames, 1) / (NFFT / 4) ** 2, 1e-20))).toFixed(1),
    frames,
  };
};

const files = process.argv.slice(2);
const SHOTS = [
  ["S1", 0, 5], ["S2", 5, 13], ["S3", 13, 18], ["S4", 18, 25],
  ["S5", 25, 31], ["S6", 31, 36], ["S7", 36, 40],
];
for (const file of files) {
  const {mono, sr} = readWav(file);
  const whole = analyzeRange(mono, sr, 0, mono.length / sr);
  const perShot = {};
  for (const [id, t0, t1] of SHOTS) perShot[id] = analyzeRange(mono, sr, t0, t1).bandsDbfs;
  console.log(JSON.stringify({
    file,
    duration: +(mono.length / sr).toFixed(3),
    whole,
    perShot,
  }, null, 2));
}
