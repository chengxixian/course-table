import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop} from "./ui/Backdrop";
import {WeekWidget} from "./ui/Widgets";
import {ThemeCtx, DEFAULT_ROLES, useRoles} from "./ui/roles";
import {useAppFonts} from "./fonts";
import type {Layout} from "./frame";

/** 卖点行：0 广告 + 观感 + 易用，按产品事实排列。 */
const POINTS = ["0 广告", "流畅", "简洁", "美观", "方便"];

const Points: React.FC<{size: number; color?: string}> = ({size, color}) => {
  const roles = useRoles();
  return (
    <div style={{display: "flex", alignItems: "center", gap: size * 0.55, whiteSpace: "nowrap"}}>
      {POINTS.map((p, i) => (
        <React.Fragment key={p}>
          {i > 0 ? (
            <div style={{width: size * 0.16, height: size * 0.16, borderRadius: 999, background: roles.outline, opacity: 0.7}} />
          ) : null}
          <div
            style={{
              fontFamily: "var(--cn)",
              fontSize: size,
              letterSpacing: i === 0 ? size * 0.08 : size * 0.14,
              fontWeight: i === 0 ? 700 : 500,
              color: i === 0 ? (color ?? roles.primary) : roles.onSurface,
            }}
          >
            {p}
          </div>
        </React.Fragment>
      ))}
    </div>
  );
};

export const Cover: React.FC<{layout?: Layout}> = ({layout = "vertical"}) => {
  useAppFonts();
  const isV = layout === "vertical";

  return (
    <ThemeCtx.Provider value={DEFAULT_ROLES}>
      <AbsoluteFill
        style={
          {
            background: DEFAULT_ROLES.surface,
            fontFamily: '"FandolFang", serif',
            "--cn": '"FandolFang", "Noto Serif CJK SC", serif',
            "--latin": '"LiberationSerif", "Times New Roman", serif',
          } as React.CSSProperties
        }
      >
        <CoverBody isV={isV} />
      </AbsoluteFill>
    </ThemeCtx.Provider>
  );
};

const CoverBody: React.FC<{isV: boolean}> = ({isV}) => {
  const roles = useRoles();
  const L = isV
    ? {
        kicker: {x: 84, y: 150, size: 30, rule: 44},
        mark: {x: 84, y: 246, size: 280},
        tag: {x: 88, y: 640, size: 56},
        points: {x: 88, y: 762, size: 42},
        widget: {x: 110, y: 900, w: 860},
        foot: {x: 88, y: 1830, size: 26},
      }
    : {
        kicker: {x: 120, y: 150, size: 24, rule: 32},
        mark: {x: 120, y: 214, size: 196},
        tag: {x: 122, y: 500, size: 40},
        points: {x: 122, y: 594, size: 30},
        widget: {x: 1084, y: 140, w: 700},
        foot: {x: 122, y: 900, size: 20},
      };

  return (
    <>
      <Backdrop f={{W: isV ? 1080 : 1920, H: isV ? 1920 : 1080} as never} layout={isV ? "vertical" : "wide"} frame={999} draw={1} />
      <div style={{position: "absolute", inset: 0}}>
        {/* kicker */}
        <div
          style={{
            position: "absolute",
            left: L.kicker.x,
            top: L.kicker.y,
            display: "flex",
            alignItems: "center",
            gap: 16,
          }}
        >
          <div style={{width: L.kicker.rule, height: isV ? 4 : 3, background: roles.primary, borderRadius: 2}} />
          <div
            style={{
              fontFamily: "var(--cn)",
              fontSize: L.kicker.size,
              letterSpacing: L.kicker.size * 0.14,
              fontWeight: 700,
              color: roles.primary,
            }}
          >
            MATERIAL 3 · 课程表
          </div>
        </div>

        {/* wordmark */}
        <div
          style={{
            position: "absolute",
            left: L.mark.x,
            top: L.mark.y,
            fontFamily: "var(--cn)",
            fontSize: L.mark.size,
            lineHeight: 1,
            fontWeight: 600,
            letterSpacing: -L.mark.size * 0.012,
            color: roles.onSurface,
          }}
        >
          课程表
        </div>

        {/* tagline */}
        <div
          style={{
            position: "absolute",
            left: L.tag.x,
            top: L.tag.y,
            fontFamily: "var(--cn)",
            fontSize: L.tag.size,
            letterSpacing: 0.6,
            color: roles.onSurfaceVariant,
            whiteSpace: "nowrap",
          }}
        >
          一学期的课，排成一张表。
        </div>

        {/* selling points */}
        <div style={{position: "absolute", left: L.points.x, top: L.points.y}}>
          <Points size={L.points.size} />
        </div>

        {/* real widget as the visual */}
        <div style={{position: "absolute", left: L.widget.x, top: L.widget.y}}>
          <WeekWidget w={L.widget.w} />
        </div>

        {/* footer */}
        <div
          style={{
            position: "absolute",
            left: L.foot.x,
            top: L.foot.y,
            fontFamily: "var(--cn)",
            fontSize: L.foot.size,
            letterSpacing: 2,
            color: roles.onSurfaceVariant,
            opacity: 0.8,
            whiteSpace: "nowrap",
          }}
        >
          开源 · GPL-3.0 · Android
        </div>
      </div>
    </>
  );
};
