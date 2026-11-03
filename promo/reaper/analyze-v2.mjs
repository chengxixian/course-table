/**
 * analyze-v2.mjs — technical QC for the REAPER-rendered v2.
 * Reports whole-track and per-shot peak/RMS/LUFS, mono compatibility, and a
 * melody-presence probe: at every hook-note onset it compares the energy at
 * the written pitch with the neighbouring semitones. This is how we verify the
 * tune is actually in the mix without being able to listen.
 *
 *   node promo/reaper/analyze-v2.mjs promo/audio/bgm-v2.wav
 */
import fs from "node:fs";

const file = process.argv[2] || "promo/audio/bgm-v2.wav";
const buf = fs.readFileSync(file);
let pos = 12;
let fmt = null;
let data = null;
while (pos + 8 <= buf.length) {
  const id = buf.toString("ascii", pos, pos + 4);
  const sz = buf.readUInt32LE(pos + 4);
  const body = pos + 8;
  if (id === "fmt ") {
    fmt = {
      format: buf.readUInt16LE(body),
      ch: buf.readUInt16LE(body + 2),
      sr: buf.readUInt32LE(body + 4),
      bits: buf.readUInt16LE(body + 14),
    };
  } else if (id === "data") {
    data = buf.subarray(body, body + sz);
  }
  pos = body + sz + (sz & 1);
}
const bytes = fmt.bits / 8;
const N = Math.floor(data.length / bytes / fmt.ch);
const SR = fmt.sr;
const L = new Float32Array(N);
const R = new Float32Array(N);
for (let i = 0; i < N; i++) {
  const read = (o) =>
    fmt.bits === 16 ? data.readInt16LE(o) / 32768 : fmt.bits === 24 ? data.readIntLE(o, 3) / 8388608 : data.readInt32LE(o) / 2147483648;
  L[i] = read(i * fmt.ch * bytes);
  R[i] = read(i * fmt.ch * bytes + bytes);
}
const db = (v) => 20 * Math.log10(Math.max(v, 1e-12));
const dur = N / SR;

const peakOf = (a, b) => {
  let p = 0, ss = 0, dc = 0;
  for (let i = a; i < b; i++) {
    p = Math.max(p, Math.abs(L[i]), Math.abs(R[i]));
    ss += L[i] * L[i] + R[i] * R[i];
    dc += L[i] + R[i];
  }
  return {peak: p, rms: Math.sqrt(ss / (2 * Math.max(1, b - a))), dc: dc / (2 * Math.max(1, b - a))};
};

/* K-weighting + gated LUFS (BS.1770-4, 48 kHz) */
const biquad = (b, a, x) => {
  const y = new Float32Array(x.length);
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < x.length; i++) {
    const v = b[0] * x[i] + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2;
    x2 = x1; x1 = x[i]; y2 = y1; y1 = v;
    y[i] = v;
  }
  return y;
};
const kWeight = (x) =>
  biquad([1, -2, 1], [1, -1.99004745483398, 0.99007225036621],
    biquad([1.53512485958697, -2.69169618940638, 1.19839281085285], [1, -1.69065929318241, 0.73248077421585], x));
const kl = kWeight(L);
const kr = kWeight(R);
const lufsRange = (a, b) => {
  const block = Math.round(0.4 * SR), hop = Math.round(0.1 * SR);
  const z = [];
  for (let s = a; s + block <= b; s += hop) {
    let ms = 0;
    for (let i = s; i < s + block; i++) ms += kl[i] * kl[i] + kr[i] * kr[i];
    z.push(ms / block);
  }
  if (!z.length) return null;
  const l = (v) => -0.691 + 10 * Math.log10(Math.max(v, 1e-20));
  const ungated = z.reduce((x, y) => x + y, 0) / z.length;
  const rel = Math.pow(10, (-10 + l(ungated)) / 10);
  const abs = Math.pow(10, (-70 + 0.691) / 10);
  const kept = z.filter((v) => v > abs && v > rel);
  return l(kept.reduce((x, y) => x + y, 0) / kept.length);
};

const whole = peakOf(0, N);
let corrN = 0, corrL = 0, corrR = 0, midSq = 0, sideSq = 0, lSq = 0, rSq = 0;
for (let i = 0; i < N; i++) {
  const m = (L[i] + R[i]) * 0.5;
  const s = (L[i] - R[i]) * 0.5;
  midSq += m * m;
  sideSq += s * s;
  lSq += L[i] * L[i];
  rSq += R[i] * R[i];
  corrN += L[i] * R[i];
  corrL += L[i] * L[i];
  corrR += R[i] * R[i];
}
const midRms = Math.sqrt(midSq / N);
const sideRms = Math.sqrt(sideSq / N);
const sideMinusMidDb = db(sideRms) - db(midRms);

const sections = [
  ["S1", 0, 150], ["S2", 150, 390], ["S3", 390, 540], ["S4", 540, 750],
  ["S5", 750, 930], ["S6", 930, 1080], ["S7", 1080, 1200],
];
const sectionStats = sections.map(([id, f0, f1]) => {
  const a = Math.round((f0 / 30) * SR), b = Math.round((f1 / 30) * SR);
  const s = peakOf(a, b);
  let m2 = 0, s2 = 0;
  for (let i = a; i < b; i++) {
    const m = (L[i] + R[i]) * 0.5;
    const sd = (L[i] - R[i]) * 0.5;
    m2 += m * m;
    s2 += sd * sd;
  }
  return {
    id, from: f0, to: f1,
    peakDbfs: +db(s.peak).toFixed(2),
    rmsDbfs: +db(s.rms).toFixed(2),
    lufs: +lufsRange(a, b).toFixed(1),
    sideMinusMidDb: +(db(Math.sqrt(s2 / Math.max(1, b - a))) - db(Math.sqrt(m2 / Math.max(1, b - a)))).toFixed(1),
  };
});

/* pitch energy at a time (Goertzel over 180 ms) */
const noteEnergy = (t, midi) => {
  const f = 440 * Math.pow(2, (midi - 69) / 12);
  const start = Math.round((t + 0.02) * SR);
  const n = Math.round(0.18 * SR);
  const goertzel = (freq) => {
    let s1 = 0, s2 = 0;
    const w = (2 * Math.PI * freq) / SR;
    const c = 2 * Math.cos(w);
    for (let i = 0; i < n && start + i < N; i++) {
      const v = (L[start + i] + R[start + i]) * 0.5 * (0.5 - 0.5 * Math.cos((2 * Math.PI * i) / (n - 1)));
      const s = v + c * s1 - s2;
      s2 = s1; s1 = s;
    }
    return s1 * s1 + s2 * s2 - c * s1 * s2;
  };
  const e = goertzel(f);
  const eu = goertzel(f * Math.pow(2, 1 / 12));
  const ed = goertzel(f * Math.pow(2, -1 / 12));
  return {f: Math.round(f), ratio: +(e / Math.max(eu, ed, 1e-9)).toFixed(2)};
};

const HOOK = [
  [0.0, 69], [0.5, 69], [1.0, 74], [2.0, 73], [2.5, 71], [3.0, 69],
  [4.0, 66], [5.0, 69], [5.5, 71], [6.0, 74],
  [8.0, 74], [8.5, 76], [9.0, 78], [10.0, 76], [10.5, 74], [11.0, 71],
  [12.0, 73], [13.5, 71], [14.0, 69], [14.5, 66], [15.0, 69],
];
const statements = [
  ["A1", 0, 0], ["A2", 16, 0], ["A3", 36, 0], ["A4", 62, 0], ["A5", 72, 2],
];
const probe = statements.map(([name, offset, tr]) => {
  const notes = HOOK.filter(([b]) => name !== "A2" && name !== "A4" ? true : b < 8).filter(([b]) => name !== "A5" ? true : b < 4);
  const scores = notes.map(([b, m]) => noteEnergy((offset + b) * 0.5, m + tr).ratio);
  const avg = scores.reduce((x, y) => x + y, 0) / Math.max(1, scores.length);
  return {name, notes: notes.length, avgRatio: +avg.toFixed(2), present: scores.filter((v) => v >= 1.5).length};
});

const peaks = [];
const win = Math.round(0.05 * SR);
for (let s = 0; s + win <= N; s += win) {
  let p = 0;
  for (let i = s; i < s + win; i++) p = Math.max(p, Math.abs(L[i]), Math.abs(R[i]));
  peaks.push({t: +(s / SR).toFixed(2), db: +db(p).toFixed(1)});
}
peaks.sort((a, b) => b.db - a.db);

const report = {
  file,
  duration: +dur.toFixed(4),
  format: {sr: SR, bits: fmt.bits, ch: fmt.ch},
  whole: {
    peakDbfs: +db(whole.peak).toFixed(2),
    rmsDbfs: +db(whole.rms).toFixed(2),
    lufs: +lufsRange(0, N).toFixed(1),
    crestDb: +(db(whole.peak) - db(whole.rms)).toFixed(1),
    dcDbfs: +db(Math.abs(whole.dc)).toFixed(1),
    lrCorrelation: +(corrN / Math.sqrt(corrL * corrR)).toFixed(3),
    lRmsDbfs: +db(Math.sqrt(lSq / N)).toFixed(2),
    rRmsDbfs: +db(Math.sqrt(rSq / N)).toFixed(2),
    midRmsDbfs: +db(midRms).toFixed(2),
    sideRmsDbfs: +db(sideRms).toFixed(2),
    sideMinusMidDb: +sideMinusMidDb.toFixed(1),
  },
  sections: sectionStats,
  melodyProbe: probe.map((p) => ({...p, avgRatioDb: +Math.min(60, 20 * Math.log10(Math.max(1, p.avgRatio))).toFixed(1)})),
  topPeaks50ms: peaks.slice(0, 12),
};
fs.writeFileSync("promo/reaper/analysis-v2.json", JSON.stringify(report, null, 2) + "\n");
console.log(JSON.stringify(report, null, 2));
