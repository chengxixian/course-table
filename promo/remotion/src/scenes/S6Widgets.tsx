import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop} from "../ui/Backdrop";
import {Caption} from "../ui/Caption";
import {SmallTodayWidget, TodayWidget, TwoDayWidget, WeekWidget} from "../ui/Widgets";
import {easeLand, prog} from "../lib/anim";
import type {Frame, Layout} from "../frame";
import {useRoles} from "../ui/roles";

type Spec = {
  id: string;
  label: string;
  note: string;
  w: number;
  x: number;
  y: number;
  node: (w: number) => React.ReactNode;
  delay: number;
};

/** S6 — one hero widget, then the three that go with it: a specimen sheet. */
export const S6Widgets: React.FC<{local: number; layout: Layout; f: Frame}> = ({local, layout, f}) => {
  const roles = useRoles();
  const isV = layout === "vertical";

  const specs: Spec[] = isV
    ? [
        {id: "w44", label: "4 × 4 · 周视图", note: "", w: 700, x: 84, y: 330, node: (w) => <WeekWidget w={w} />, delay: 6},
        {id: "w43", label: "4 × 3 · 今日课程", note: "", w: 340, x: 84, y: 1178, node: (w) => <TodayWidget w={w} />, delay: 26},
        {id: "w42", label: "4 × 2 · 两日", note: "", w: 340, x: 448, y: 1178, node: (w) => <TwoDayWidget w={w} />, delay: 32},
        {id: "w22", label: "2 × 2 · 今日", note: "", w: 184, x: 812, y: 1178, node: (w) => <SmallTodayWidget w={w} />, delay: 38},
      ]
    : [
        {id: "w44", label: "4 × 4 · 周视图", note: "", w: 360, x: 120, y: 232, node: (w) => <WeekWidget w={w} />, delay: 8},
        {id: "w43", label: "4 × 3 · 今日课程", note: "", w: 320, x: 520, y: 232, node: (w) => <TodayWidget w={w} />, delay: 30},
        {id: "w42", label: "4 × 2 · 两日", note: "", w: 320, x: 880, y: 232, node: (w) => <TwoDayWidget w={w} />, delay: 40},
        {id: "w22", label: "2 × 2 · 今日", note: "", w: 240, x: 1240, y: 232, node: (w) => <SmallTodayWidget w={w} />, delay: 48},
      ];

  return (
    <AbsoluteFill>
      <Backdrop f={f} layout={layout} frame={local} />
      {specs.map((s, i) => {
        const e = easeLand(prog(local, s.delay, 14));
        if (e <= 0) return null;
        return (
          <div
            key={s.id}
            style={{
              position: "absolute",
              left: s.x,
              top: s.y,
              opacity: Math.min(1, e),
              transform: `translateY(${(1 - e) * -46}px) scale(${0.965 + 0.035 * e})`,
            }}
          >
            {s.node(s.w)}
            <div
              style={{
                marginTop: isV ? (i === 0 ? 16 : 10) : 8,
                display: "flex",
                baseline: "auto",
                alignItems: "baseline",
                gap: 10,
              } as React.CSSProperties}
            >
              <div
                style={{
                  fontFamily: "var(--cn)",
                  fontSize: isV ? (i === 0 ? 26 : 20) : 15,
                  fontWeight: 600,
                  color: roles.onSurface,
                  whiteSpace: "nowrap",
                }}
              >
                {s.label}
              </div>
            </div>
          </div>
        );
      })}
      <Caption shot="widgets" local={local} layout={layout} f={f} />
    </AbsoluteFill>
  );
};
