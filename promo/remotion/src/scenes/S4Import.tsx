import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop, PaperCard} from "../ui/Backdrop";
import {Caption} from "../ui/Caption";
import {Phone} from "../ui/Phone";
import {BLOCKS, IMPORT_SOURCES} from "../data";
import {WeekScreen} from "../ui/WeekScreen";
import {Icon} from "../ui/Icon";
import {easeEmphasized, easeOutCubic, enter, mix, prog} from "../lib/anim";
import {phoneX, type Frame, type Layout} from "../frame";
import {useRoles} from "../ui/roles";

/** S4 — the source shelf: seven real import formats + the 350-school registry. */
export const S4Import: React.FC<{local: number; layout: Layout; f: Frame}> = ({local, layout, f}) => {
  const roles = useRoles();
  const isV = layout === "vertical";

  const phoneScale = (isV ? 420 : 520) / 412;
  const phoneY = isV ? 44 : 20;
  const pIn = enter({frame: local, start: 0, dur: 22, rise: 40, scaleFrom: 0.94});

  const search = {
    x: isV ? 84 : 120,
    y: isV ? 1012 : 70,
    w: isV ? 912 : 820,
    h: isV ? 96 : 76,
  };
  const grid = {
    x: isV ? 84 : 120,
    y: isV ? 1128 : 176,
    colW: isV ? 444 : 398,
    rowH: isV ? 96 : 76,
    gapX: isV ? 24 : 24,
    gapY: isV ? 10 : 10,
  };

  const searchIn = enter({frame: local, start: 16, dur: 20, rise: 28});
  const typed = Math.round(Math.min(2, Math.max(0, (local - 30) / 8)));
  const count = Math.round(350 * easeOutCubic(prog(local, 16, 16)));

  return (
    <AbsoluteFill>
      <Backdrop f={f} layout={layout} frame={local} />
      <div
        style={{
          position: "absolute",
          left: isV ? (1080 - 420) / 2 : 1256,
          top: phoneY,
          opacity: pIn.opacity,
          transform: pIn.transform,
        }}
      >
        <Phone scale={phoneScale} statusBar={false}>
          <WeekScreen frame={local} blocks={BLOCKS} shiftX={isV ? 0 : 0} />
        </Phone>
      </div>

      {/* school search */}
      <PaperCard
        style={{
          position: "absolute",
          left: search.x,
          top: search.y,
          width: search.w,
          height: search.h,
          borderRadius: 22,
          padding: "0 24px",
          display: "flex",
          alignItems: "center",
          gap: 16,
          opacity: searchIn.opacity,
          transform: searchIn.transform,
        }}
      >
        <Icon name="search" size={isV ? 34 : 30} color={roles.onSurfaceVariant} />
        <div
          style={{
            fontFamily: "var(--cn)",
            fontSize: isV ? 34 : 28,
            color: roles.onSurface,
            letterSpacing: 0.5,
            display: "flex",
            alignItems: "center",
          }}
        >
          {"黄山学院".slice(0, typed)}
          <div
            style={{
              width: 2,
              height: isV ? 34 : 28,
              background: roles.primary,
              marginLeft: 4,
              opacity: local % 20 < 12 ? 1 : 0,
            }}
          />
        </div>
        <div style={{flex: 1}} />
        <div
          style={{
            fontFamily: "var(--cn)",
            fontSize: isV ? 26 : 22,
            color: roles.primary,
            border: `1px solid ${roles.outlineVariant}`,
            background: roles.surfaceContainerLow,
            padding: isV ? "8px 18px" : "6px 16px",
            borderRadius: 999,
            whiteSpace: "nowrap",
          }}
        >
          {count} 所高校
        </div>
      </PaperCard>

      {/* seven sources */}
      {IMPORT_SOURCES.map((s, i) => {
        const col = i % 2;
        const row = Math.floor(i / 2);
        const x = grid.x + col * (grid.colW + grid.gapX);
        const y = grid.y + row * (grid.rowH + grid.gapY);
        const e = prog(local, 30 + i * 6, 16);
        if (e <= 0) return null;
        const ee = easeOutCubic(e);
        const rot = -1.3 + (i % 3) * 1.0;
        return (
          <div
            key={s.tag}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: grid.colW,
              height: grid.rowH,
              boxSizing: "border-box",
              display: "flex",
              alignItems: "center",
              gap: 14,
              padding: isV ? "0 18px" : "0 16px",
              borderRadius: 16,
              background: roles.surfaceContainerLowest,
              border: `1px solid ${roles.outlineVariant}`,
              opacity: ee,
              transform: `translate3d(${(1 - ee) * -64}px, ${(1 - ee) * 18}px, 0) rotate(${(1 - ee) * rot}deg) scale(${0.985 + 0.015 * ee})`,
            }}
          >
            <div
              style={{
                minWidth: isV ? 62 : 54,
                height: isV ? 34 : 30,
                padding: "0 8px",
                borderRadius: 8,
                background: roles.surfaceContainer,
                color: roles.onSurfaceVariant,
                fontFamily: "var(--latin)",
                fontSize: isV ? 16 : 14,
                fontWeight: 700,
                letterSpacing: 0.4,
                display: "grid",
                placeItems: "center",
                boxSizing: "border-box",
              }}
            >
              {s.tag}
            </div>
            <div style={{minWidth: 0}}>
              <div style={{fontFamily: "var(--cn)", fontSize: isV ? 26 : 22, color: roles.onSurface, whiteSpace: "nowrap"}}>
                {s.label}
              </div>
              <div style={{fontFamily: "var(--cn)", fontSize: isV ? 18 : 15, color: roles.onSurfaceVariant, whiteSpace: "nowrap"}}>
                {s.note}
              </div>
            </div>
          </div>
        );
      })}

      {/* 8th slot: whole-semester calendar write-out (calendar_export.dart) */}
      {(() => {
        const i = 7;
        const col = i % 2;
        const row = Math.floor(i / 2);
        const x = grid.x + col * (grid.colW + grid.gapX);
        const y = grid.y + row * (grid.rowH + grid.gapY);
        const e = easeOutCubic(prog(local, 30 + i * 6, 16));
        if (e <= 0) return null;
        return (
          <div
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: grid.colW,
              height: grid.rowH,
              boxSizing: "border-box",
              display: "flex",
              alignItems: "center",
              gap: 14,
              padding: isV ? "0 18px" : "0 16px",
              borderRadius: 16,
              background: roles.primaryContainer,
              border: `1px solid ${roles.primaryContainer}`,
              opacity: e,
              transform: `translate3d(${(1 - e) * -64}px, ${(1 - e) * 18}px, 0) rotate(${(1 - e) * 0.9}deg)`,
            }}
          >
            <Icon name="event_ok" size={isV ? 30 : 26} color={roles.onPrimaryContainer} />
            <div style={{minWidth: 0}}>
              <div style={{fontFamily: "var(--cn)", fontSize: isV ? 26 : 22, color: roles.onPrimaryContainer, whiteSpace: "nowrap"}}>
                写入系统日历
              </div>
              <div style={{fontFamily: "var(--cn)", fontSize: isV ? 18 : 15, color: roles.onPrimaryContainer, opacity: 0.75, whiteSpace: "nowrap"}}>
                整学期一次导出 · 42 个事件
              </div>
            </div>
          </div>
        );
      })()}

      <Caption shot="import" local={local} layout={layout} f={f} />
    </AbsoluteFill>
  );
};
