import React from "react";
import {Audio, Sequence, staticFile, interpolate} from "remotion";
import {DURATION, FS, SHOTS} from "./timeline";

type Hit = {from: number; src: string; volume: number; note: string};

/**
 * Foley table in AUTHORED frames (30fps beats), derived from SHOTS so a
 * timeline change moves the sound with the picture. `SfxLayer` converts to
 * delivery frames (60fps) at render time.
 *
 * Samples are the project's own synthesized set (scripts/make-audio.mjs,
 * self-authored, CC0). A recorded Freesound set was tried in between and
 * reverted: the recordings were individually fine but changed the *character*
 * of the design (a pitched wood block, an octave-up bubble pop, a bass-boom
 * riser, a mid-heavy impact), which read as "odd" against a Material 3 promo.
 * The kept copies live in promo/.work/sfx-final/ for reference.
 */
export const SFX: Hit[] = [
  // S1 — typesetting: numerals, then the wordmark
  {from: SHOTS.open.from + 2, src: "paper-slide.wav", volume: 0.32, note: "数字落版"},
  {from: SHOTS.open.from + 48, src: "swish.wav", volume: 0.34, note: "字标升起"},
  {from: SHOTS.open.from + 70, src: "stamp.wav", volume: 0.24, note: "字标落定"},

  // S2 — phone rises, 8 blocks stamp, grid slips to the weekend
  {from: SHOTS.week.from + 1, src: "swish.wav", volume: 0.40, note: "手机入画"},
  ...[0, 1, 2, 3, 4, 5, 6, 7].map((i) => ({
    from: SHOTS.week.from + 30 + i * 7,
    src: "stamp.wav",
    volume: 0.36 - i * 0.028,
    note: `课块落版 ${i + 1}`,
  })),
  {from: SHOTS.week.from + 96, src: "paper-slide.wav", volume: 0.27, note: "栅格下滑"},

  // S3 — tap, then the anchored popup grows
  {from: SHOTS.detail.from + 9, src: "pop.wav", volume: 0.48, note: "点按课块"},
  {from: SHOTS.detail.from + 24, src: "paper-slide.wav", volume: 0.34, note: "弹层展开"},

  // S4 — typing, then eight import cards land
  {from: SHOTS.import.from + 18, src: "paper-slide.wav", volume: 0.24, note: "搜索卡入列"},
  ...[0, 1, 2, 3, 4, 5, 6, 7].map((i) => ({
    from: SHOTS.import.from + 34 + i * 7,
    src: i % 2 === 0 ? "paper-slide.wav" : "stamp.wav",
    volume: 0.24 - i * 0.011,
    note: `导入来源 ${i + 1}`,
  })),
  ...[0, 1, 2, 3, 4, 5].map((i) => ({
    from: SHOTS.import.from + 30 + i * 8,
    src: "key.wav",
    volume: 0.24,
    note: "输入",
  })),

  // S5 — lift, drag, snap
  {from: SHOTS.drag.from + 6, src: "swish.wav", volume: 0.34, note: "抬起"},
  {from: SHOTS.drag.from + 50, src: "snap.wav", volume: 0.54, note: "落槽"},
  {from: SHOTS.drag.from + 56, src: "stamp.wav", volume: 0.27, note: "归位"},

  // S6 — four widgets land
  ...[8, 34, 42, 50].map((d, i) => ({
    from: SHOTS.widgets.from + d,
    src: i === 0 ? "stamp.wav" : "paper-slide.wav",
    volume: 0.34 - i * 0.04,
    note: `小组件 ${i + 1}`,
  })),

  // S7 — riser → impact → chime
  {from: SHOTS.outro.from, src: "riser.wav", volume: 0.40, note: "铺底渐强"},
  {from: SHOTS.outro.from + 46, src: "impact.wav", volume: 0.70, note: "字标落地"},
  {from: SHOTS.outro.from + 62, src: "chime.wav", volume: 0.38, note: "收束余韵"},
];

/**
 * Single foley bus gain.
 *
 * History: this started at 1.0, was raised to 1.45 to satisfy an internal
 * "BGM↔SFX peak gap ≥4 dB" rule, and is now back to 1.0 because that rule
 * optimised a number instead of the result — the dense cascades (8 course
 * blocks, 8 import cards, 6 keystrokes) read as too loud at 1.45. The
 * per-cue volumes above were trimmed a further ~2 dB at the same time.
 * If the mix ever needs re-balancing, change this one number and re-measure
 * with scripts/check-mix.mjs; do not re-tune the cue table by ear-less guesswork.
 */
export const SFX_GAIN = 1.0;

export const SfxLayer: React.FC = () => (
  <>
    {SFX.map((hit, i) => (
      <Sequence key={`${hit.src}-${hit.from}-${i}`} from={hit.from * FS} name={`sfx ${hit.note}`}>
        <Audio src={staticFile(`audio/sfx/${hit.src}`)} volume={hit.volume * SFX_GAIN} />
      </Sequence>
    ))}
  </>
);

/**
 * BGM is a render parameter, not a hard-coded file: `file` is a posix path
 * relative to public/ (staticFile), `volume` is the sustained level after a
 * 24-frame (0.4s) fade-in. `enabled: false` mounts no <Audio> at all, so the
 * no-BGM delivery keeps only the SFX layer.
 */
export const DEFAULT_BGM_FILE = "audio/bgm/bgm-final.wav";
export const DEFAULT_BGM_VOLUME = 0.5;

export const Bgm: React.FC<{
  enabled?: boolean;
  file?: string;
  volume?: number;
}> = ({enabled = true, file = DEFAULT_BGM_FILE, volume = DEFAULT_BGM_VOLUME}) => {
  if (!enabled) return null;
  const target = Math.max(0, Math.min(1, volume));
  return (
    <Audio
      src={staticFile(file)}
      volume={(f) =>
        interpolate(f, [0, 24, DURATION - 1], [0, target, target], {
          extrapolateLeft: "clamp",
          extrapolateRight: "clamp",
        })
      }
    />
  );
};
