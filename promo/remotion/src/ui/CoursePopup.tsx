import React from "react";
import {COURSES, timeRange, type Block} from "../data";
import {PALETTE} from "../theme";
import {Icon} from "./Icon";
import {useRoles} from "./roles";
import {mix, mixHex, clamp} from "../lib/anim";
import type {Course} from "../theme";

export type Rect = {x: number; y: number; w: number; h: number};

/**
 * Course detail popup, rebuilt from lib/ui/components.dart CourseDetailSheet:
 * 24 radius, 22px insets, 48px icon tile, 3-up fact cells, schedule rows,
 * outlined "加入 Google 日历" + filled "关闭".
 */
export const CoursePopup: React.FC<{
  course: Course;
  rect: Rect;
  scale: number;
  opacity: number;
}> = ({course, rect, scale, opacity}) => {
  const roles = useRoles();
  const pal = PALETTE[course.colorIndex];
  return (
    <div
      style={{
        position: "absolute",
        left: rect.x,
        top: rect.y,
        width: rect.w,
        height: rect.h,
        borderRadius: 24,
        background: roles.surfaceContainerHigh,
        boxShadow: "0 18px 44px rgba(16,16,24,0.24)",
        transform: `scale(${scale})`,
        transformOrigin: "center center",
        opacity,
        boxSizing: "border-box",
        overflow: "hidden",
        padding: "8px 22px 20px",
        display: "flex",
        flexDirection: "column",
      }}
    >
      {/* header */}
      <div style={{display: "flex", alignItems: "center", gap: 12, paddingTop: 6}}>
        <div
          style={{
            width: 48,
            height: 48,
            borderRadius: 15,
            background: pal.container,
            borderLeft: `4px solid ${pal.accent}`,
            display: "grid",
            placeItems: "center",
            boxSizing: "border-box",
          }}
        >
          <Icon name="book" size={22} color={pal.ink} />
        </div>
        <div style={{display: "flex", flexDirection: "column", gap: 2, minWidth: 0}}>
          <div style={{fontSize: 16, fontWeight: 600, letterSpacing: -0.2, color: roles.onSurface, whiteSpace: "nowrap"}}>
            {course.name}
          </div>
          <div style={{fontSize: 9.5, color: roles.onSurfaceVariant}}>
            {course.teacher} · 专业必修 · 2 学分
          </div>
        </div>
      </div>

      {/* fact cells */}
      <div
        style={{
          marginTop: 14,
          padding: 13,
          borderRadius: 16,
          background: roles.surfaceContainerLowest,
          border: `1px solid ${roles.outlineVariant}`,
          display: "flex",
        }}
      >
        {[
          {label: "周次", value: course.weeks},
          {label: "地点", value: course.room},
          {label: "课程代码", value: course.code},
        ].map((c) => (
          <div key={c.label} style={{flex: 1, minWidth: 0}}>
            <div style={{fontSize: 8.5, color: roles.onSurfaceVariant}}>{c.label}</div>
            <div style={{marginTop: 2, fontSize: 10, fontWeight: 600, color: roles.onSurface, whiteSpace: "nowrap"}}>
              {c.value}
            </div>
          </div>
        ))}
      </div>

      <div style={{marginTop: 13, fontSize: 9, letterSpacing: 1.3, fontWeight: 800, color: roles.primary}}>
        时间安排
      </div>

      <div style={{marginTop: 6, display: "flex", flexDirection: "column", gap: 6}}>
        {course.meets.map((m) => (
          <div
            key={`${m.day}-${m.start}`}
            style={{
              padding: "9px 11px",
              borderRadius: 11,
              background: roles.surfaceContainerLowest,
              display: "flex",
              alignItems: "center",
              gap: 8,
            }}
          >
            <div style={{width: 6, height: 6, borderRadius: 3, background: pal.accent, flex: "none"}} />
            <div style={{fontSize: 9.5, fontWeight: 500, color: roles.onSurface, flex: 1, whiteSpace: "nowrap"}}>
              星期{"一二三四五六日"[m.day - 1]} 第 {m.start}-{m.start + m.span - 1} 节{" "}
              <span style={{fontFamily: "var(--latin)"}}>{timeRange(m.start, m.span)}</span>
            </div>
            <div style={{fontSize: 8, color: roles.onSurfaceVariant}}>{course.room}</div>
          </div>
        ))}
      </div>

      <div style={{marginTop: 12, display: "flex", gap: 8}}>
        <div
          style={{
            flex: 1,
            height: 38,
            borderRadius: 19,
            border: `1px solid ${roles.outlineVariant}`,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 6,
            fontSize: 12,
            fontWeight: 600,
            color: roles.onSurface,
          }}
        >
          <Icon name="event_ok" size={16} color={roles.onSurface} />
          加入 Google 日历
        </div>
        <div
          style={{
            width: 92,
            height: 38,
            borderRadius: 19,
            background: roles.primary,
            color: roles.onPrimary,
            display: "grid",
            placeItems: "center",
            fontSize: 12,
            fontWeight: 600,
          }}
        >
          关闭
        </div>
      </div>
    </div>
  );
};

/** The floating block that the drag gesture carries (week_screen.dart elevation:10). */
export const FloatingBlock: React.FC<{
  block: Block;
  x: number;
  y: number;
  lift: number;
  shadow?: boolean;
}> = ({block, x, y, lift, shadow = true}) => {
  const pal = PALETTE[block.course.colorIndex];
  const w = 88 - 4;
  const h = block.span * 56 + (block.span - 1) * 4 - 4;
  return (
    <div
      style={{
        position: "absolute",
        left: x,
        top: y,
        width: w,
        height: h,
        borderRadius: 12,
        background: pal.container,
        borderLeft: `3px solid ${pal.accent}`,
        boxSizing: "border-box",
        padding: "6px 5px 6px 7px",
        display: "flex",
        flexDirection: "column",
        justifyContent: "center",
        gap: 2,
        transform: `scale(${mix(1, 1.035, lift)})`,
        boxShadow: shadow
          ? `0 ${mix(2, 26, lift)}px ${mix(6, 44, lift)}px rgba(20,20,32,${mix(0.12, 0.34, lift)}), 0 0 0 ${mix(0, 1.5, lift)}px ${pal.accent}55`
          : "none",
        zIndex: 40,
      }}
    >
      <div
        style={{
          fontFamily: "var(--latin)",
          fontSize: 8.5,
          fontWeight: 700,
          color: pal.ink,
          opacity: 0.7,
          lineHeight: 1.1,
          whiteSpace: "nowrap",
        }}
      >
        {timeRange(block.start, block.span)}
      </div>
      <div style={{fontSize: 11, fontWeight: 700, lineHeight: 1.2, letterSpacing: -0.1, color: pal.ink}}>
        {block.course.name}
      </div>
      <div style={{fontSize: 8, lineHeight: 1.1, color: pal.ink, opacity: 0.72}}>{block.course.room}</div>
    </div>
  );
};
