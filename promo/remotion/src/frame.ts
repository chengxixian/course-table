export type Layout = "vertical" | "wide";

/**
 * Two output frames share one timeline. The vertical cut is the master
 * (1080×1920); the wide cut reframes the same scenes with the phone on the
 * right and the caption block bottom-left.
 *
 * Geometry contract (vertical): phone is 680 wide including a 12dp bezel, so
 * its bottom edge lands at 12 + 939×(680/412) ≈ 1562 and the caption block
 * starts at 1664 — a ≥100px clear gap, no caption ever sits on the mockup.
 */
export const FRAMES = {
  vertical: {
    W: 1080,
    H: 1920,
    margin: 84,
    phone: {w: 680, y: 12},
    caption: {x: 84, y: 1664, w: 912, kicker: 28, main: 78, sub: 52, gap: 8},
    captionBottom: 44,
  },
  wide: {
    W: 1920,
    H: 1080,
    margin: 120,
    phone: {w: 560, y: 56, x: 1240},
    caption: {x: 120, y: 730, w: 1000, kicker: 28, main: 58, sub: 38, gap: 10},
    captionBottom: 0,
  },
} as const;

export type Frame = (typeof FRAMES)[Layout];

export const phoneH = (f: Frame) => ((915 + 24) * f.phone.w) / 412;
export const phoneX = (f: Frame, layout: Layout) =>
  layout === "vertical" ? (f.W - f.phone.w) / 2 : (f.phone as {x: number}).x;
/** dp -> video pixels inside the phone mock. */
export const dpScale = (f: Frame) => f.phone.w / 412;
