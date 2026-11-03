/**
 * compose-v2.mjs — melody-first BGM v2 for the 课程表 promo.
 *
 * 120 BPM, 4/4, D major with a final lift to E major. 40.000 s = 80 beats =
 * 20 bars. The tune is built around a 4-bar hook (16 beats) that is stated at
 * the top, returned doubled at S4 (18 s) and returned transposed at S7 (36 s),
 * with a contrasting B section (bars 7-9) and a B' answer (27-30 s).
 *
 * Outputs:
 *   promo/reaper/midi/<TRACK>.mid      — importable MIDI, one file per part
 *   promo/reaper/build-data.lua        — data consumed by build-v2.lua in REAPER
 *   promo/audio/cues-v2.json           — frame/beat/accent map + melody analysis
 *
 * Everything here is deterministic and self-authored; no external samples.
 */
import fs from "node:fs";
import path from "node:path";

const BPM = 120;
const PPQ = 960;
const SR = 48000;
const BEATS = 80; // 40 s
const FRAMES = 1200;
const OUT_REAPER = path.resolve("promo/reaper");
const OUT_AUDIO = path.resolve("promo/audio");
fs.mkdirSync(path.join(OUT_REAPER, "midi"), {recursive: true});
fs.mkdirSync(OUT_AUDIO, {recursive: true});

/* ------------------------------------------------------------------ chords */
// 20 bars, 2 s each. `root` is the bass MIDI note; `pad` the pad voicing.
const CHORDS = [
  {name: "D", root: 38, pad: [50, 57, 62, 66]}, // 1
  {name: "Bm7", root: 47, pad: [47, 54, 57, 62]}, // 2
  {name: "G", root: 43, pad: [55, 59, 62, 66]}, // 3
  {name: "A7", root: 45, pad: [57, 61, 64, 67]}, // 4
  {name: "D", root: 38, pad: [50, 57, 62, 66]}, // 5
  {name: "Bm7", root: 47, pad: [47, 54, 57, 62]}, // 6
  {name: "G", root: 43, pad: [55, 59, 62, 66]}, // 7
  {name: "Em7", root: 40, pad: [52, 55, 59, 62]}, // 8
  {name: "A7", root: 45, pad: [57, 61, 64, 67]}, // 9
  {name: "D", root: 38, pad: [50, 57, 62, 66]}, // 10
  {name: "Bm7", root: 47, pad: [47, 54, 57, 62]}, // 11
  {name: "G", root: 43, pad: [55, 59, 62, 66]}, // 12
  {name: "A7", root: 45, pad: [57, 61, 64, 67]}, // 13
  {name: "Bm7", root: 47, pad: [47, 54, 57, 62]}, // 14
  {name: "G", root: 43, pad: [55, 59, 62, 66]}, // 15
  {name: "D", root: 38, pad: [50, 57, 62, 66]}, // 16
  {name: "Bm7", root: 47, pad: [47, 54, 57, 62]}, // 17
  {name: "G", root: 43, pad: [55, 59, 62, 66]}, // 18
  {name: "B7", root: 47, pad: [54, 57, 63, 66]}, // 19
  {name: "E", root: 40, pad: [52, 56, 59, 64]}, // 20
];
const chordAtBeat = (beat) => CHORDS[Math.max(0, Math.min(19, Math.floor(beat / 4)))];

/* -------------------------------------------------------------- the hook */
// 4 bars / 16 beats, D major. [startBeat, pitch, durationBeats, velocity]
const HOOK = [
  [0.0, 69, 0.5, 112],
  [0.5, 69, 0.5, 100],
  [1.0, 74, 1.0, 118],
  [2.0, 73, 0.5, 108],
  [2.5, 71, 0.5, 104],
  [3.0, 69, 1.0, 110],
  [4.0, 66, 1.0, 108],
  [5.0, 69, 0.5, 104],
  [5.5, 71, 0.5, 108],
  [6.0, 74, 2.0, 116],
  [8.0, 74, 0.5, 110],
  [8.5, 76, 0.5, 112],
  [9.0, 78, 1.0, 120],
  [10.0, 76, 0.5, 112],
  [10.5, 74, 0.5, 108],
  [11.0, 71, 1.0, 108],
  [12.0, 73, 1.5, 112],
  [13.5, 71, 0.5, 104],
  [14.0, 69, 0.5, 104],
  [14.5, 66, 0.5, 100],
  [15.0, 69, 1.0, 108],
];

// Counter-line for the hook (thirds/sixths below, contrary motion).
const COUNTER = [
  [0.0, 66, 1.0, 92],
  [1.0, 62, 1.0, 88],
  [2.0, 64, 0.5, 84],
  [2.5, 62, 0.5, 84],
  [3.0, 66, 1.0, 90],
  [4.0, 69, 1.0, 90],
  [5.0, 66, 0.5, 86],
  [5.5, 64, 0.5, 86],
  [6.0, 62, 2.0, 88],
  [8.0, 67, 1.0, 88],
  [9.0, 71, 1.0, 92],
  [10.0, 69, 0.5, 86],
  [10.5, 67, 0.5, 86],
  [11.0, 64, 1.0, 88],
  [12.0, 61, 1.5, 90],
  [13.5, 64, 0.5, 86],
  [14.0, 66, 0.5, 84],
  [14.5, 64, 0.5, 84],
  [15.0, 62, 1.0, 88],
];

// B section: descending triads, longer notes, mid register (contrast with A).
const BTHEME = [
  [0.0, 71, 1.5, 100], // B4 over G
  [1.5, 67, 1.0, 96], // G4
  [2.5, 62, 1.5, 98], // D4
  [4.0, 64, 1.5, 98], // E4 over Em7
  [5.5, 59, 1.0, 94], // B3
  [6.5, 67, 1.5, 96], // G4
  [8.0, 69, 1.0, 100], // A4 over A7
  [9.0, 73, 1.0, 104], // C#5
  [10.0, 76, 2.0, 108], // E5 (build into S4)
];

// B' answer (27-30 s, bars 14-15): shorter, more urgent.
const BPRIME = [
  [0.0, 66, 1.5, 98],
  [1.5, 69, 0.5, 94],
  [2.0, 71, 2.0, 102],
  [4.0, 74, 1.0, 102],
  [5.0, 71, 0.5, 96],
  [5.5, 69, 0.5, 94],
];

const addTransposed = (notes, offsetBeat, semitones = 0) =>
  notes.map(([b, p, d, v]) => [b + offsetBeat, p + semitones, d, v]);

/* --------------------------------------------------------------- tracks */
const tracks = [];

const lead = [];
lead.push(...addTransposed(HOOK, 0)); // A1: bars 1-4
lead.push(...addTransposed(HOOK.filter(([b]) => b < 8), 16)); // A2: bars 5-6
lead.push(...addTransposed(BTHEME, 24)); // B: bars 7-9
lead.push(...addTransposed(HOOK, 36)); // A3: bars 10-13 (S4 return)
lead.push([53.333, 71, 0.667, 108]); // snap accent B4
lead.push(...addTransposed(BPRIME, 54)); // B': bars 14-15
lead.push([60.0, 69, 0.5, 100], [60.5, 71, 0.5, 102], [61.0, 73, 0.5, 104], [61.5, 74, 0.5, 106]); // fill into S6
lead.push(...addTransposed(HOOK.filter(([b]) => b < 8), 62)); // A4: bars 16-17 (S6)
lead.push([70.0, 69, 0.5, 104], [70.5, 71, 0.5, 106], [71.0, 73, 0.5, 108], [71.5, 74, 0.5, 108]); // fill into S7
lead.push(...addTransposed(HOOK.filter(([b]) => b < 4), 72, 2)); // A5: bars 19, transposed to E
lead.push([76.0, 76, 2.0, 118]); // E5 resolution, ends 39.0 s (1 s natural tail)

const leadDbl = [];
// S4 unison double (different waveform), S7 octave double on the 4-beat hook.
leadDbl.push(...addTransposed(HOOK, 36).map(([b, p, d, v]) => [b, p, d, Math.min(100, v - 8)]));
leadDbl.push(...addTransposed(HOOK.filter(([b]) => b < 4), 72, 2).map(([b, p, d, v]) => [b, p + 12, d, 78]));
leadDbl.push([76.0, 88, 2.5, 70]); // E6 sparkle on the resolution

const counter = [];
counter.push(...addTransposed(COUNTER.filter(([b]) => b < 8), 16)); // A2
counter.push([24.0, 69, 4.0, 84], [28.0, 71, 4.0, 86], [32.0, 73, 4.0, 88]); // B long tones
counter.push(...addTransposed(COUNTER, 36)); // A3
counter.push([54.0, 74, 2.0, 88], [56.0, 66, 2.0, 86], [58.0, 71, 2.0, 88]); // B'
counter.push(...addTransposed(COUNTER.filter(([b]) => b < 8), 62)); // A4
counter.push([72.0, 66, 2.0, 88], [74.0, 69, 2.0, 90], [76.0, 68, 2.5, 86]); // S7

const pad = [];
CHORDS.forEach((c, i) => {
  const start = i * 4;
  const dur = i === 19 ? 2.0 : 3.95;
  const padVel = i === 19 ? 82 : i === 18 ? 74 : 64;
  for (const p of c.pad) pad.push([start, p, dur, padVel]);
});

const bass = [];
const bassBar = (bar, style) => {
  const s = bar * 4;
  const c = CHORDS[bar];
  if (style === "long") {
    bass.push([s, c.root, 2.0, 100], [s + 2, c.root + 7, 2.0, 94]);
  } else if (style === "groove") {
    bass.push(
      [s, c.root, 1.0, 112],
      [s + 1.5, c.root + 12, 0.5, 96],
      [s + 2.5, c.root + 7, 0.5, 100],
      [s + 3.0, c.root, 1.0, 106],
    );
  } else if (style === "push") {
    bass.push(
      [s, c.root, 0.75, 112],
      [s + 1.0, c.root, 0.5, 96],
      [s + 1.75, c.root + 12, 0.5, 96],
      [s + 2.5, c.root + 7, 0.5, 102],
      [s + 3.0, c.root, 0.75, 106],
      [s + 3.75, c.root + 7, 0.25, 92],
    );
  }
};
bassBar(0, "long");
bassBar(1, "long");
for (let b = 2; b <= 5; b++) bassBar(b, "groove");
for (let b = 6; b <= 8; b++) bassBar(b, "long");
for (let b = 9; b <= 12; b++) bassBar(b, "push");
bass.push([53.333, CHORDS[13].root, 2.0, 108]);
bassBar(14, "groove");
bassBar(15, "groove");
bassBar(16, "push");
bassBar(17, "push");
bassBar(18, "groove");
bass.push([72, 47, 2.0, 108], [74, 54, 2.0, 100]); // B7
bass.push([75.0667, 47, 1.0, 118]); // impact re-attack on B
bass.push([76, 40, 2.0, 112]); // E, ends 39.0 s

const drums = {CLOCK: [], KICK: [], SNARE: [], CLAP: [], HAT: [], OPENHAT: [], CRASH: [], TOM: []};
const hit = (tr, beat, vel = 100) => drums[tr].push([beat, 60, 0.1, vel]);

// intro pulse: a soft clock every two beats
for (let b = 0; b <= 8; b += 2) hit("CLOCK", b, 44);

// S2 lift (5 s = beat 10): crash + groove
hit("CRASH", 10, 98);
for (const b of [10, 12, 14]) hit("KICK", b, 120);
for (const b of [10.0, 10.5, 11.0, 11.5, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0, 15.5]) {
  hit("HAT", b, b % 1 === 0 ? 72 : 60);
}
for (const b of [11, 13, 15]) { hit("SNARE", b, 116); hit("CLAP", b, 96); }

const grooveBar = (s, opts = {}) => {
  hit("KICK", s, 122);
  hit("KICK", s + 1.75, 98);
  hit("KICK", s + 2.5, 112);
  if (opts.extraKick) hit("KICK", s + 3.75, 98);
  hit("SNARE", s + 1, 118);
  hit("SNARE", s + 3, 118);
  if (opts.ghost) hit("SNARE", s + 2.75, 40);
  hit("CLAP", s + 1, 98);
  hit("CLAP", s + 3, 98);
  const hv = [72, 61, 82, 63, 74, 63, 84, 65];
  for (let i = 0; i < 8; i++) hit("HAT", s + i * 0.5, hv[i]);
  if (opts.doubleHat) for (let i = 0; i < 8; i++) hit("HAT", s + i * 0.5 + 0.25, 48);
  if (opts.openHat) hit("OPENHAT", s + 3.5, 90);
};
for (const b of [16, 20]) grooveBar(b);
grooveBar(24, {ghost: true});
// fill into the B section (24-26 keeps groove, then drop)
hit("SNARE", 25.0, 70);
hit("SNARE", 25.25, 80);
hit("SNARE", 25.5, 90);
hit("SNARE", 25.75, 100);

// B section: drums out 26-34, heartbeat kicks
hit("KICK", 26.0, 70);
hit("KICK", 30.0, 64);
hit("HAT", 32.0, 52);
hit("HAT", 32.5, 46);
hit("HAT", 33.0, 52);
// 14-17 s: a quiet 16th hat roll keeps the import/detail breath moving
for (let b = 28; b < 34; b += 0.25) hit("HAT", b, 36 + Math.round((b - 28) * 3));
hit("SNARE", 34.0, 60);
for (let i = 0; i < 8; i++) hit("SNARE", 34.0 + i * 0.25, 62 + i * 6);
hit("KICK", 34.0, 100);
hit("KICK", 35.0, 100);

// S4 (18 s = beat 36): full return
hit("CRASH", 36, 104);
for (const b of [36, 40, 44]) grooveBar(b, {openHat: b === 40, extraKick: b === 44});
grooveBar(48, {ghost: true});
// fill 47-48 and drop at 50
for (let i = 0; i < 4; i++) hit("SNARE", 47.0 + i * 0.25, 80 + i * 8);
hit("KICK", 48.0, 112);
hit("SNARE", 49.0, 110);
for (const b of [48.0, 48.5, 49.0, 49.5]) hit("HAT", b, 60);
hit("TOM", 49.5, 96);
hit("TOM", 49.75, 104);

// pre-snap build 51.5-53.2
for (let i = 0; i < 7; i++) hit("SNARE", 51.5 + i * 0.25, 52 + i * 8);
hit("CRASH", 53.333, 108);
hit("KICK", 53.333, 124);
hit("SNARE", 53.333, 120);
hit("CLAP", 53.333, 104);
hit("TOM", 53.333, 100);

// S5 groove
grooveBar(54, {openHat: true});
grooveBar(56, {ghost: true});
grooveBar(58, {extraKick: true});

// fill into S6
for (let i = 0; i < 8; i++) hit("SNARE", 60.0 + i * 0.25, 58 + i * 7);
hit("TOM", 61.0, 100);
hit("TOM", 61.25, 104);
hit("TOM", 61.5, 108);
hit("TOM", 61.75, 112);

// S6: double hats, more motion
hit("CRASH", 62, 100);
grooveBar(62, {doubleHat: true, extraKick: true, openHat: true});
grooveBar(66, {doubleHat: true, ghost: true});
for (let i = 0; i < 4; i++) hit("SNARE", 68.0 + i * 0.25, 76 + i * 8);
hit("TOM", 69.0, 100);
hit("TOM", 69.25, 104);
hit("TOM", 69.5, 108);
hit("TOM", 69.75, 112);
hit("KICK", 69.0, 108);

// fill into S7
for (let i = 0; i < 8; i++) hit("SNARE", 70.0 + i * 0.25, 60 + i * 7);
hit("TOM", 71.0, 104);
hit("TOM", 71.25, 108);
hit("TOM", 71.5, 112);
hit("TOM", 71.75, 116);

// S7 build + impact at beat 75.0667 (frame 1126) + resolution
hit("CRASH", 72, 110);
hit("KICK", 72, 120);
hit("SNARE", 73, 118);
hit("KICK", 73.5, 104);
hit("HAT", 72, 70);
for (let b = 72.5; b < 75; b += 0.5) hit("HAT", b, b % 1 === 0 ? 66 : 58);
for (let i = 0; i < 10; i++) hit("SNARE", 74.0 + i * 0.125, 50 + i * 5);
hit("CRASH", 75.0667, 122);
hit("KICK", 75.0667, 127);
hit("TOM", 75.0667, 118);
hit("OPENHAT", 74.75, 80);
hit("CLAP", 75.0667, 112);
hit("CRASH", 76, 84);
for (const p of [54, 57, 63, 66]) pad.push([75.0667, p, 0.9, 92]);

const noteCount = (notes) => notes.length;

const tracksData = [
  {name: "LEAD", kind: "synth", preset: "lead", vol: 0.7, pan: 0.0, send: 0.16, notes: lead},
  {name: "LEAD DBL", kind: "synth", preset: "leadDbl", vol: 0.42, pan: -0.65, send: 0.1, notes: leadDbl},
  {name: "COUNTER", kind: "synth", preset: "counter", vol: 0.55, pan: -0.75, send: 0.18, notes: counter},
  {name: "PAD", kind: "synth", preset: "pad", vol: 0.19, pan: 0.0, send: 0.22, notes: pad},
  {name: "BASS", kind: "synth", preset: "bass", vol: 0.62, pan: 0.0, send: 0.03, notes: bass},
  {name: "CLOCK", kind: "sample", sample: "samples/hat-closed.wav", vol: 0.14, pan: 0.3, notes: drums.CLOCK},
  {name: "KICK", kind: "sample", sample: "samples/kick.wav", vol: 0.92, pan: 0.0, notes: drums.KICK},
  {name: "SNARE", kind: "sample", sample: "samples/snare.wav", vol: 0.7, pan: 0.0, notes: drums.SNARE},
  {name: "CLAP", kind: "sample", sample: "samples/clap.wav", vol: 0.55, pan: 0.65, notes: drums.CLAP},
  {name: "HAT", kind: "sample", sample: "samples/hat-closed.wav", vol: 0.45, pan: 0.75, notes: drums.HAT},
  {name: "OPENHAT", kind: "sample", sample: "samples/hat-open.wav", vol: 0.5, pan: -0.75, notes: drums.OPENHAT},
  {name: "CRASH", kind: "sample", sample: "samples/crash.wav", vol: 0.65, pan: 0.7, notes: drums.CRASH},
  {name: "TOM", kind: "sample", sample: "samples/tom-low.wav", vol: 0.65, pan: -0.7, notes: drums.TOM},
];

/* --------------------------------------------------------------- MIDI out */
const vlq = (n) => {
  const bytes = [n & 0x7f];
  n >>= 7;
  while (n > 0) {
    bytes.unshift((n & 0x7f) | 0x80);
    n >>= 7;
  }
  return Buffer.from(bytes);
};
const meta = (type, data) => {
  const len = vlq(data.length);
  return Buffer.concat([Buffer.from([0xff, type]), len, data]);
};
const writeMidi = (file, name, notes) => {
  const header = Buffer.alloc(14);
  header.write("MThd", 0);
  header.writeUInt32BE(6, 4);
  header.writeUInt16BE(1, 8); // format 1
  header.writeUInt16BE(2, 10); // two tracks
  header.writeUInt16BE(PPQ, 12);
  const conductor = [];
  const nameBuf = Buffer.from(name, "ascii");
  conductor.push({tick: 0, data: meta(0x03, nameBuf)});
  // tempo 120: 500000 us per quarter
  conductor.push({tick: 0, data: meta(0x51, Buffer.from([0x07, 0xa1, 0x20]))});
  // 4/4
  conductor.push({tick: 0, data: meta(0x58, Buffer.from([4, 2, 24, 8]))});
  conductor.push({tick: 0, data: meta(0x2f, Buffer.alloc(0))});
  const music = [{tick: 0, data: meta(0x03, nameBuf)}];
  for (const [b, p, d, v] of notes) {
    const on = Math.round(b * PPQ);
    const off = Math.round((b + d) * PPQ);
    music.push({tick: on, order: 1, data: Buffer.from([0x90, p & 0x7f, v & 0x7f])});
    music.push({tick: off, order: 0, data: Buffer.from([0x80, p & 0x7f, 0x00])});
  }
  const endTick = Math.round(BEATS * PPQ);
  music.push({tick: endTick, order: 2, data: meta(0x2f, Buffer.alloc(0))});
  const encode = (events, isConductor) => {
    events.sort((a, b) => a.tick - b.tick || (a.order ?? 0) - (b.order ?? 0));
    const chunks = [];
    let last = 0;
    for (const e of events) {
      chunks.push(vlq(e.tick - last), e.data);
      last = e.tick;
    }
    const body = Buffer.concat(chunks);
    const len = Buffer.alloc(4);
    len.writeUInt32BE(body.length, 0);
    return Buffer.concat([Buffer.from("MTrk", "ascii"), len, body]);
  };
  const buf = Buffer.concat([header, encode(conductor, true), encode(music, false)]);
  fs.writeFileSync(path.join(OUT_REAPER, "midi", file), buf);
};

for (const t of tracksData) {
  writeMidi(`${t.name.replace(/\s+/g, "-")}.mid`, t.name, t.notes);
}

/* ------------------------------------------------------------ Lua data out */
const luaNum = (n) => (Number.isInteger(n) ? String(n) : n.toFixed(4).replace(/0+$/, "").replace(/\.$/, ""));
const luaNotes = (notes) =>
  notes.map(([b, p, d, v]) => `{${luaNum(b)},${p},${luaNum(d)},${v}}`).join(",");
const luaTracks = tracksData.map((t) => {
  const parts = [
    `name=${JSON.stringify(t.name)}`,
    `kind=${JSON.stringify(t.kind)}`,
    `vol=${luaNum(t.vol)}`,
    `pan=${luaNum(t.pan)}`,
    `send=${luaNum(t.send || 0)}`,
  ];
  if (t.preset) parts.push(`preset=${JSON.stringify(t.preset)}`);
  if (t.sample) parts.push(`sample=${JSON.stringify(t.sample)}`);
  parts.push(`notes={${luaNotes(t.notes)}}`);
  return `{${parts.join(",")}}`;
});
const luaSrc = `-- generated by promo/reaper/compose-v2.mjs — do not hand-edit\nreturn {\n  bpm=${BPM},\n  sr=${SR},\n  tracks={\n    ${luaTracks.join(",\n    ")}\n  }\n}\n`;
fs.writeFileSync(path.join(OUT_REAPER, "build-data.lua"), luaSrc);

/* ------------------------------------------------------------ melody analysis */
const analyse = (notes, label) => {
  const sorted = [...notes].sort((a, b) => a[0] - b[0]);
  const pitches = sorted.map((n) => n[1]);
  const intervals = [];
  for (let i = 1; i < pitches.length; i++) intervals.push(pitches[i] - pitches[i - 1]);
  const nonZero = intervals.filter((v) => v !== 0);
  const dirChanges = nonZero.reduce((acc, v, i) => (i && Math.sign(v) !== Math.sign(nonZero[i - 1]) ? acc + 1 : acc), 0);
  const durationHistogram = {};
  for (const [, , d] of sorted) durationHistogram[d] = (durationHistogram[d] || 0) + 1;
  return {
    label,
    notes: sorted.length,
    rangeSemitones: Math.max(...pitches) - Math.min(...pitches),
    lowestMidi: Math.min(...pitches),
    highestMidi: Math.max(...pitches),
    firstPitch: pitches[0],
    contourIntervals: intervals,
    directionChanges: dirChanges,
    stepwiseRatio: +(nonZero.filter((v) => Math.abs(v) <= 2).length / Math.max(1, nonZero.length)).toFixed(2),
    durationHistogram,
  };
};

const hookAnalysis = analyse(HOOK, "hook A (16 beats)");
const bAnalysis = analyse(BTHEME, "B theme (12 beats)");
const hookTransposed = addTransposed(HOOK, 0, 2);
const hookTransposedAnalysis = analyse(hookTransposed, "hook A transposed +2 st (S7)");

const sections = [
  {
    id: "S1", name: "OPEN", from: 0, to: 150, bars: [1, 2],
    music: "Clock pulse + pad; hook phrase 1 (A1) stated on the lead from 0.0 s",
    energy: "low",
  },
  {
    id: "S2", name: "WEEK", from: 150, to: 390, bars: [2, 6],
    music: "Hook phrase 2 completes at 4.0 s; drums enter at 5.0 s (crash, kick/backbeat/hats); A2 restates the hook first half at 8.0 s with counter-line",
    energy: "medium",
  },
  {
    id: "S3", name: "DETAIL", from: 390, to: 540, bars: [7, 9],
    music: "B theme: descending triads B-G-D / E-B-G / A-C#-E in the mid register; drums out 13.0-17.0 s, heartbeat kicks, snare roll back in",
    energy: "medium-low",
  },
  {
    id: "S4", name: "IMPORT", from: 540, to: 750, bars: [10, 13],
    music: "Hook A3 returns full and doubled (lead + unison double + counter); strong groove; hook cadence continues over the drums dropping at 25.0 s",
    energy: "medium-high",
  },
  {
    id: "S5", name: "DRAG", from: 750, to: 930, bars: [13, 16],
    music: "Pre-snap snare build into the 800-frame snap (B4 + crash/kick/chord); B' answer 27-30 s",
    energy: "medium",
  },
  {
    id: "S6", name: "WIDGETS", from: 930, to: 1080, bars: [16, 18],
    music: "Hook A4 (first half) at 31.0 s with 16th hats / extra kick; tom fill into S7",
    energy: "medium-high",
  },
  {
    id: "S7", name: "OUTRO", from: 1080, to: 1200, bars: [19, 20],
    music: "Modulation to E: hook A transposed +2 st over B7, impact at 1126, E-major resolution at 1142 with held E5, release/reverb to 40.0 s",
    energy: "peak",
  },
];

const accents = [
  [0, "start", "首拍 · pad + 主旋律 hook 第 1 小节起"],
  [2, "foley", "纸滑落版（SFX）", "sfx"],
  [48, "foley", "字标升起 swish（SFX）", "sfx"],
  [70, "foley", "字标落定 stamp（SFX）", "sfx"],
  [150, "cut", "S2 切点 · 5.0 s：crash + 鼓组进入，hook 第 2 句继续", "both"],
  [300, "beat", "第 20 拍 · hook A1 完成（4.0 s 起第 2 句）"],
  [390, "cut", "S3 切点 · 13.0 s：鼓组退出，B 主题进入", "both"],
  [540, "cut", "S4 切点 · 18.0 s：hook A3 全编制回归（doubled）", "both"],
  [700, "beat", "第 46.67 拍 · 导入段尾"],
  [750, "cut", "S5 切点 · 25.0 s：鼓组抽空，hook 终止句留在旋律上", "both"],
  [800, "snap", "SNAP 重音 · B4 + crash/kick/chord stab（音乐层）", "both"],
  [860, "beat", "第 57.33 拍 · 归位 hold，B' 律动"],
  [930, "cut", "S6 切点 · 31.0 s：hook A4（前 2 小节）+ 16 分 hat", "both"],
  [1000, "beat", "第 66.67 拍 · 小组件段中"],
  [1080, "cut", "S7 切点 · 36.0 s：转 E 大调，hook 移调 +2 回归", "both"],
  [1126, "impact", "IMPACT · B7 上的 hook 音 B4 + crash/kick/tom", "both"],
  [1142, "resolve", "解决 · E 大调，E5 长音与 chime 同音", "both"],
  [1185, "hold", "字标 hold · 只剩 E5 释放与混响尾"],
  [1200, "end", "片尾 · 尾音衰减至静音"],
].map(([frame, type, desc, layer]) => ({
  frame,
  timeSec: +(frame / 30).toFixed(3),
  beat: +((frame / 30) * 2).toFixed(3),
  type,
  desc,
  layer: layer || "bgm",
}));

const cues = {
  $schema: "promo-bgm-cues/2",
  title: "课程表 · 40s promo BGM v2 (melody-first)",
  revision: 2,
  generatedBy: "promo/reaper/compose-v2.mjs",
  license: "CC0-1.0 (self-authored synthesis; MIDI in this repo)",
  fps: 30,
  durationFrames: 1200,
  durationSec: 40,
  bpm: BPM,
  beatsPerBar: 4,
  beatFrames: 15,
  key: {main: "D major", outro: "E major (bars 19-20)"},
  form: "A1 (bars 1-4) - A2 (5-6) - B (7-9) - A3 (10-13) - B' (14-15) - A4 (16-17) - A5 transposed (19-20)",
  audio: {
    file: "promo/audio/bgm-v2.wav",
    format: "PCM (REAPER render, 48 kHz stereo)",
    sampleRate: SR,
    channels: 2,
    durationSec: 40,
    render: "REAPER 7.82 offline render, action 42230",
  },
  melody: {
    hook: hookAnalysis,
    hookTransposed: hookTransposedAnalysis,
    bTheme: bAnalysis,
    statementBeats: {A1: 0, A2: 16, A3: 36, A4: 62, A5: 72},
    counterStatements: [16, 36, 62, 72],
    doubling: "S4 unison double (LEAD DBL), S7 octave double (+12) and E6 sparkle",
  },
  tracks: tracksData.map((t) => ({
    name: t.name,
    kind: t.kind,
    preset: t.preset || null,
    sample: t.sample || null,
    notes: noteCount(t.notes),
    volume: t.vol,
    pan: t.pan,
  })),
  sections,
  accents,
  source: {
    midi: "promo/reaper/midi/*.mid",
    project: "promo/reaper/bgm-v2.rpp",
    script: "promo/reaper/compose-v2.mjs",
    samples: "promo/reaper/samples/*.wav (self-authored one-shots)",
  },
};
fs.writeFileSync(path.join(OUT_AUDIO, "cues-v2.json"), JSON.stringify(cues, null, 2) + "\n");

console.log(JSON.stringify({
  tracks: tracksData.map((t) => `${t.name}:${t.notes.length}`),
  hook: {range: hookAnalysis.rangeSemitones, intervals: hookAnalysis.contourIntervals, steps: hookAnalysis.stepwiseRatio, dirChanges: hookAnalysis.directionChanges},
  bTheme: {range: bAnalysis.rangeSemitones, intervals: bAnalysis.contourIntervals},
  totalNotes: tracksData.reduce((a, t) => a + t.notes.length, 0),
  cues: path.join(OUT_AUDIO, "cues-v2.json"),
  lua: path.join(OUT_REAPER, "build-data.lua"),
}, null, 2));
