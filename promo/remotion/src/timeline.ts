/** Single source of truth for the film timeline. */

/** Delivery frame rate. Scenes are authored in 30fps "beats" and sampled at FS×. */
export const FPS = 60;
export const FS = FPS / 30; // 2 — authored-frame -> delivery-frame factor

export const DURATION = 1200 * FS; // 2400 frames = 40.0s @60fps

/** Shot boundaries in AUTHORED frames (30fps). Multiply by FS for Sequence. */
export const SHOTS = {
  open: {from: 0, dur: 150},
  week: {from: 150, dur: 240},
  detail: {from: 390, dur: 150},
  import: {from: 540, dur: 210},
  drag: {from: 750, dur: 180},
  widgets: {from: 930, dur: 150},
  outro: {from: 1080, dur: 120},
} as const;

export type ShotName = keyof typeof SHOTS;

/** Authored frame -> delivery frame. */
export const toDelivery = (authoredFrame: number) => authoredFrame * FS;

export const CAPTIONS: Record<
  ShotName,
  {kicker: string; main: string; sub?: string}
> = {
  open: {kicker: "MATERIAL 3 · 课程表", main: ""},
  week: {kicker: "周课表 / WEEK", main: "每天第几节，一眼看清。"},
  detail: {kicker: "课程详情 / COURSE", main: "点开一节课，时间地点。"},
  import: {
    kicker: "导入 / IMPORT",
    main: "350 所学校，搜到就导。",
    sub: "HSU 同步 · 网页 AI 兜底 · 7 种格式",
  },
  drag: {kicker: "拖拽调整 / SNAP", main: "长按拖动，落槽即存。"},
  widgets: {kicker: "桌面小组件 / WIDGETS", main: "四种小组件，抬眼就是。"},
  outro: {kicker: "动态色彩 / DYNAMIC COLOR", main: "跟随系统的颜色。"},
};
