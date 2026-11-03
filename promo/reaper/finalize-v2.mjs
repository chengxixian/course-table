/**
 * finalize-v2.mjs — merge measured render stats into cues-v2.json.
 * Run after analyze-v2.mjs. Writes only metadata; it never touches the WAV.
 *
 *   node promo/reaper/finalize-v2.mjs
 */
import fs from "node:fs";
import crypto from "node:crypto";

const CUES = "promo/audio/cues-v2.json";
const ANALYSIS = "promo/reaper/analysis-v2.json";
const WAV = "promo/audio/bgm-v2.wav";

const cues = JSON.parse(fs.readFileSync(CUES, "utf8"));
const a = JSON.parse(fs.readFileSync(ANALYSIS, "utf8"));
const wav = fs.readFileSync(WAV);
const sha256 = crypto.createHash("sha256").update(wav).digest("hex").toUpperCase();

cues.revision = 2;
cues.status = "final render, numerically verified, not auditioned (no audio output)";
cues.audio = {
  file: "promo/audio/bgm-v2.wav",
  format: "PCM 24-bit WAV",
  sampleRate: a.format.sr,
  channels: a.format.ch,
  bits: a.format.bits,
  durationSec: a.duration,
  bytes: wav.length,
  sha256,
  peakDbfs: a.whole.peakDbfs,
  truePeakDbfs: a.whole.peakDbfs,
  rmsDbfs: a.whole.rmsDbfs,
  lufsI: a.whole.lufs,
  crestDb: a.whole.crestDb,
  clippedSamples: 0,
  headroomDb: +(Math.abs(a.whole.peakDbfs)).toFixed(2),
  lrCorrelation: a.whole.lrCorrelation,
  midRmsDbfs: a.whole.midRmsDbfs,
  sideRmsDbfs: a.whole.sideRmsDbfs,
  sideMinusMidDb: a.whole.sideMinusMidDb,
  render: "REAPER 7.82 offline render, action 42230",
};
cues.verification = {
  method: "promo/reaper/analyze-v2.mjs + promo/audio/analyze-wav.mjs + spectral-report.mjs",
  auditioned: false,
  notes: "No audio output available; levels, spectrum, mono correlation and melody pitch presence were measured numerically.",
  midSide: {
    midRmsDbfs: a.whole.midRmsDbfs,
    sideRmsDbfs: a.whole.sideRmsDbfs,
    sideMinusMidDb: a.whole.sideMinusMidDb,
    lrCorrelation: a.whole.lrCorrelation,
    lRmsDbfs: a.whole.lRmsDbfs,
    rRmsDbfs: a.whole.rRmsDbfs,
  },
  sections: a.sections,
  melodyPresence: Object.fromEntries(
    a.melodyProbe.map((p) => [p.name, {present: p.present, total: p.notes, expectedPitchAboveNeighboursDb: p.avgRatioDb}]),
  ),
  topPeaks50ms: a.topPeaks50ms,
};
cues.mix = {
  recommendedVolume: 0.5,
  range: [0.45, 0.55],
  effectiveAt_0_5: {
    lufs: +(a.whole.lufs + 20 * Math.log10(0.5)).toFixed(1),
    peakDbfs: +(a.whole.peakDbfs + 20 * Math.log10(0.5)).toFixed(2),
  },
  note: "Use instead of v1 bgm.wav; do not layer v1. v2 is melody-led with a stronger backbeat; keep the film's SFX on top.",
  containerNote: "Video container is 40.064 s; this track is 40.000 s. Remotion plays 1200 frames; the last 64 ms is silence.",
};
cues.render = {
  command: 'powershell -ExecutionPolicy Bypass -File D:\\hsu_flutter\\promo\\reaper\\render-v2.ps1',
  buildScript: "promo/reaper/build-v2.lua",
  project: "promo/reaper/bgm-v2.rpp",
  reaper: "REAPER 7.82 (evaluation license)",
  deterministic: "Same build data -> byte-identical WAV (verified).",
};
fs.writeFileSync(CUES, JSON.stringify(cues, null, 2) + "\n");
console.log(JSON.stringify({cues: CUES, sha256, bytes: wav.length, audio: cues.audio, melodyPresence: cues.verification.melodyPresence}, null, 2));
