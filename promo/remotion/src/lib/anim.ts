/** Deterministic animation helpers. No Date.now(), no Math.random(). */

export const clamp = (v: number, lo = 0, hi = 1) => Math.max(lo, Math.min(hi, v));
export const mix = (a: number, b: number, t: number) => a + (b - a) * t;

/** Normalised progress of `frame` through [start, start+dur], clamped. */
export const prog = (frame: number, start: number, dur: number) =>
  dur <= 0 ? (frame >= start ? 1 : 0) : clamp((frame - start) / dur);

/** mulberry32 — fixed-seed pseudo random, safe for frame-by-frame renders. */
export const mulberry32 = (seed: number) => {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
};

/** Cubic-bezier evaluator, so the film uses Flutter's exact curves. */
export const bezier = (x1: number, y1: number, x2: number, y2: number) => {
  const curveX = (t: number) => 3 * (1 - t) ** 2 * t * x1 + 3 * (1 - t) * t ** 2 * x2 + t ** 3;
  const curveY = (t: number) => 3 * (1 - t) ** 2 * t * y1 + 3 * (1 - t) * t ** 2 * y2 + t ** 3;
  const solveT = (x: number) => {
    let lo = 0;
    let hi = 1;
    let t = x;
    for (let i = 0; i < 24; i++) {
      const cx = curveX(t);
      if (Math.abs(cx - x) < 1e-5) break;
      if (cx < x) lo = t;
      else hi = t;
      t = (lo + hi) / 2;
    }
    return t;
  };
  return (x: number) => curveY(solveT(clamp(x)));
};

/** lib/ui/motion.dart · Curves.easeOutCubic */
export const easeOutCubic = bezier(0.215, 0.61, 0.355, 1);
/** lib/ui/motion.dart · Curves.easeInOutCubicEmphasized (0.05,0.7,0.1,1) */
export const easeEmphasized = bezier(0.05, 0.7, 0.1, 1);
/** week_screen.dart · Curves.easeOutCubic on the 200ms drop snap */
export const easeSnap = bezier(0.33, 1, 0.68, 1);
/** Physical landing: allowed overshoot (aesthetic-rules: landing may bounce). */
export const easeLand = bezier(0.18, 1.32, 0.36, 1);

export type EnterOpts = {
  frame: number;
  start: number;
  dur?: number;
  rise?: number;
  scaleFrom?: number;
  curve?: (x: number) => number;
};

/** Opacity + translateY + scale entrance. */
export const enter = ({
  frame,
  start,
  dur = 24,
  rise = 40,
  scaleFrom = 1,
  curve = easeEmphasized,
}: EnterOpts) => {
  const p = prog(frame, start, dur);
  const e = curve(p);
  return {
    opacity: clamp(p * 3),
    transform: `translateY(${(1 - e) * rise}px) scale(${mix(scaleFrom, 1, e)})`,
  };
};

/** Fade in/out window. */
export const fade = (frame: number, start: number, end: number, inDur = 10, outDur = 10) => {
  const a = clamp((frame - start) / inDur);
  const b = end < 0 ? 1 : clamp((end - frame) / outDur);
  return Math.min(a, b);
};

export const stagger = (i: number, base: number, step: number) => base + i * step;

/** Hex colour blend (#rrggbb). */
export const mixHex = (a: string, b: string, t: number) => {
  const pa = a.replace("#", "");
  const pb = b.replace("#", "");
  const ch = (hex: string, i: number) => parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  const out = [0, 1, 2].map((i) => Math.round(mix(ch(pa, i), ch(pb, i), clamp(t))));
  return `#${out.map((v) => v.toString(16).padStart(2, "0")).join("")}`;
};

/** Damped spring 0→1 with overshoot (scale/landing metaphors). */
export const spring = (t: number, damping = 5.6, freq = 9.4) => {
  const x = clamp(t);
  return 1 - Math.exp(-damping * x) * Math.cos(freq * x);
};

/** Lagged copy of a 0..1 progress, for ghost trails. */
export const lag = (p: number, amount: number) => clamp(p - amount) / (1 - amount);