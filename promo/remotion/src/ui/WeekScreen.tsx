import React from "react";
import {DAYS, DAY_DATES, PERIODS, SEMESTER, TODAY_INDEX, timeRange, type Block} from "../data";
import {PALETTE} from "../theme";
import {easeOutCubic, mix, prog} from "../lib/anim";
import {Icon} from "./Icon";
import {useRoles} from "./roles";

export const GEO = {
  appbarH: 52,
  heroTop: 62,
  heroH: 78,
  cardLeft: 16,
  cardW: 380,
  cardTop: 162,
  timeW: 48,
  dayW: 88,
  rowH: 56,
  brk: 4,
  headerH: 48,
  gridLeft: 16 + 48 + 1,
  gridTop: 162 + 48 + 1,
  navTop: 835,
};

export const blockRect = (b: {day: number; start: number; span: number}) => ({
  x: GEO.gridLeft + (b.day - 1) * GEO.dayW + 2,
  y: GEO.gridTop + (b.start - 1) * (GEO.rowH + GEO.brk) + 2,
  w: GEO.dayW - 4,
  h: b.span * GEO.rowH + (b.span - 1) * GEO.brk - 4,
});

export type WeekScreenProps = {
  frame: number;
  blocks: Block[];
  stampOn?: boolean;
  stampStart?: number;
  stampStep?: number;
  shiftX?: number;
  highlight?: {day: number; start: number; span: number} | null;
  lifted?: string[];
  tapKey?: string | null;
  tapPulse?: {x: number; y: number; r: number; opacity: number} | null;
  dim?: number;
  children?: React.ReactNode;
  heroHighlight?: number;
  hideChrome?: boolean;
};

export const WeekScreen: React.FC<WeekScreenProps> = ({
  frame,
  blocks,
  stampOn = false,
  stampStart = 0,
  stampStep = 6,
  shiftX = 0,
  highlight = null,
  lifted = [],
  tapKey = null,
  tapPulse = null,
  dim = 0,
  children,
  heroHighlight = 0,
  hideChrome = false,
}) => {
  const roles = useRoles();
  return (
    <div style={{position: "absolute", inset: 0, background: roles.surface, fontFamily: "var(--cn)", color: roles.onSurface}}>
      {/* AppBar */}
      <div
        style={{
          position: "absolute",
          top: 28,
          left: 0,
          right: 0,
          height: GEO.appbarH,
          display: "flex",
          alignItems: "center",
          padding: "0 8px 0 4px",
          display: hideChrome ? "none" : "flex",
        }}
      >
        <div style={{width: 36, height: 36, display: "grid", placeItems: "center", opacity: 0.9}}>
          <Icon name="chevron_left" size={19} color={roles.onSurface} />
        </div>
        <div
          style={{
            minWidth: 52,
            height: 34,
            borderRadius: 999,
            background: roles.secondaryContainer,
            color: roles.onSecondaryContainer,
            display: "grid",
            placeItems: "center",
            fontSize: 11,
            fontWeight: 600,
            padding: "0 12px",
            fontFamily: "var(--cn)",
          }}
        >
          本周
        </div>
        <div style={{width: 36, height: 36, display: "grid", placeItems: "center", opacity: 0.9}}>
          <Icon name="chevron_right" size={19} color={roles.onSurface} />
        </div>
        <div style={{flex: 1}} />
        <div style={{width: 36, height: 36, display: "grid", placeItems: "center"}}>
          <Icon name="sync" size={19} color={roles.onSurfaceVariant} />
        </div>
      </div>

      {/* WeekHero */}
      <div
        style={{
          position: "absolute",
          left: GEO.cardLeft,
          top: GEO.heroTop,
          width: GEO.cardW,
          height: GEO.heroH,
          boxSizing: "border-box",
          padding: "16px 16px 16px 18px",
          borderRadius: 22,
          background: roles.surfaceContainerLowest,
          border: `1px solid ${roles.outlineVariant}`,
          display: hideChrome ? "none" : "flex",
          alignItems: "center",
          gap: 12,
        }}
      >
        <div
          style={{
            width: 5,
            height: 44,
            borderRadius: 3,
            background: roles.primary,
            transform: `scaleY(${mix(0.2, 1, heroHighlight)})`,
            transformOrigin: "center",
            opacity: mix(0.35, 1, heroHighlight),
          }}
        />
        <div style={{flex: 1, display: "flex", flexDirection: "column", gap: 3}}>
          <div style={{fontSize: 11.5, color: roles.onSurfaceVariant, fontFamily: "var(--latin)", letterSpacing: 0.1}}>
            {SEMESTER.range}
          </div>
          <div style={{fontSize: 24, fontWeight: 600, letterSpacing: -0.7, lineHeight: 1.05}}>
            第 {SEMESTER.week} 周
          </div>
        </div>
        <div style={{fontSize: 9.5, color: roles.onSurfaceVariant, fontFamily: "var(--latin)"}}>
          {SEMESTER.week} / {SEMESTER.weeks}
        </div>
      </div>

      {/* Timetable card */}
      <div
        style={{
          position: "absolute",
          left: GEO.cardLeft,
          top: GEO.cardTop,
          width: GEO.cardW,
          height: 705,
          borderRadius: 24,
          background: roles.surfaceContainerLowest,
          border: `1px solid ${roles.outlineVariant}`,
          overflow: "hidden",
          display: "flex",
        }}
      >
        {/* time column */}
        <div style={{width: GEO.timeW, flex: "none"}}>
          <div style={{height: GEO.headerH, display: "grid", placeItems: "center", fontSize: 9, color: roles.onSurfaceVariant}}>
            节
          </div>
          <div style={{height: 1, background: roles.outlineVariant}} />
          {PERIODS.map((p) => (
            <React.Fragment key={p.i}>
              <div
                style={{
                  height: GEO.rowH,
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: 1,
                  fontFamily: "var(--latin)",
                }}
              >
                <div style={{fontSize: 11, fontWeight: 700, color: roles.onSurfaceVariant}}>{p.i}</div>
                <div style={{fontSize: 6.5, color: roles.onSurfaceVariant, opacity: 0.62}}>
                  {p.start}
                </div>
              </div>
              {p.i !== PERIODS.length ? <div style={{height: GEO.brk}} /> : null}
            </React.Fragment>
          ))}
        </div>
        <div style={{width: 1, background: roles.outlineVariant, flex: "none"}} />

        {/* day grid viewport */}
        <div style={{flex: 1, overflow: "hidden", position: "relative"}}>
          <div style={{width: GEO.dayW * 7, transform: `translateX(${-shiftX}px)`}}>
            {/* day headers */}
            <div style={{display: "flex"}}>
              {DAYS.map((d, i) => {
                const today = i === TODAY_INDEX;
                return (
                  <div
                    key={d}
                    style={{
                      width: GEO.dayW,
                      height: GEO.headerH,
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: 2,
                      borderLeft: `1px solid ${roles.outlineVariant}`,
                      background: today ? roles.primaryContainer + "55" : "transparent",
                    }}
                  >
                    <div style={{fontSize: 9.5, fontWeight: 500, color: today ? roles.primary : roles.onSurfaceVariant}}>
                      {d}
                    </div>
                    <div
                      style={{
                        width: 22,
                        height: 22,
                        borderRadius: 11,
                        display: "grid",
                        placeItems: "center",
                        fontSize: 10,
                        fontWeight: 600,
                        fontFamily: "var(--latin)",
                        background: today ? roles.primary : "transparent",
                        color: today ? roles.onPrimary : roles.onSurface,
                      }}
                    >
                      {DAY_DATES[i]}
                    </div>
                  </div>
                );
              })}
            </div>
            <div style={{height: 1, background: roles.outlineVariant}} />

            {/* grid */}
            <div style={{position: "relative", display: "flex", height: 656}}>
              {DAYS.map((d, i) => {
                const pal = (b: Block) => PALETTE[b.course.colorIndex];
                return (
                  <div
                    key={d}
                    style={{
                      width: GEO.dayW,
                      height: 656,
                      borderLeft: `1px solid ${roles.outlineVariant}`,
                      background:
                        i === TODAY_INDEX
                          ? roles.primaryContainer + "12"
                          : i >= 5
                            ? roles.surfaceContainerLow
                            : "transparent",
                      position: "relative",
                    }}
                  >
                    {PERIODS.map((p) => (
                      <React.Fragment key={p.i}>
                        <div style={{height: GEO.rowH, borderBottom: `1px solid ${roles.outlineVariant}55`}} />
                        {p.i !== PERIODS.length ? <div style={{height: GEO.brk}} /> : null}
                      </React.Fragment>
                    ))}

                    {/* drop target inside this column */}
                    {highlight && highlight.day === i + 1 ? (
                      <div
                        style={{
                          position: "absolute",
                          left: 2,
                          top: (highlight.start - 1) * (GEO.rowH + GEO.brk) + 2,
                          width: GEO.dayW - 4,
                          height: highlight.span * GEO.rowH + (highlight.span - 1) * GEO.brk - 4,
                          borderRadius: 12,
                          background: "rgba(66,133,244,0.20)",
                          border: "2px solid #4285F4",
                          boxSizing: "border-box",
                        }}
                      />
                    ) : null}

                    {/* blocks for this day */}
                    {blocks
                      .filter((b) => b.day === i + 1)
                      .map((b) => {
                        const idx = blocks.indexOf(b);
                        const p = stampOn ? prog(frame, stampStart + idx * stampStep, 11) : 1;
                        if (p <= 0) return null;
                        const e = easeOutCubic(p);
                        const c = pal(b);
                        const isLifted = lifted.includes(b.key);
                        const tapped = tapKey === b.key;
                        return (
                          <div
                            key={b.key}
                            style={{
                              position: "absolute",
                              left: 2,
                              top: (b.start - 1) * (GEO.rowH + GEO.brk) + 2,
                              width: GEO.dayW - 4,
                              height: b.span * GEO.rowH + (b.span - 1) * GEO.brk - 4,
                              borderRadius: 12,
                              background: c.container,
                              borderLeft: `3px solid ${c.accent}`,
                              boxSizing: "border-box",
                              padding: "6px 5px 6px 7px",
                              display: "flex",
                              flexDirection: "column",
                              justifyContent: "center",
                              gap: 2,
                              opacity: isLifted ? 0 : e,
                              transform: `translateY(${(1 - e) * -10}px) scale(${mix(1.055, 1, e)})`,
                              boxShadow: tapped ? "0 0 0 2px rgba(11,87,208,0.45)" : "none",
                            }}
                          >
                            <div
                              style={{
                                fontFamily: "var(--latin)",
                                fontSize: 8.5,
                                fontWeight: 700,
                                color: c.ink,
                                opacity: 0.7,
                                lineHeight: 1.1,
                                whiteSpace: "nowrap",
                              }}
                            >
                              {timeRange(b.start, b.span)}
                            </div>
                            <div
                              style={{
                                fontSize: b.span === 1 ? 10 : 11,
                                fontWeight: 700,
                                lineHeight: 1.2,
                                letterSpacing: -0.1,
                                color: c.ink,
                                display: "-webkit-box",
                                WebkitLineClamp: b.span === 1 ? 1 : 2,
                                WebkitBoxOrient: "vertical",
                                overflow: "hidden",
                              }}
                            >
                              {b.course.name}
                            </div>
                            {b.span > 1 ? (
                              <div style={{fontSize: 8, lineHeight: 1.1, color: c.ink, opacity: 0.72}}>
                                {b.course.room}
                              </div>
                            ) : null}
                          </div>
                        );
                      })}
                  </div>
                );
              })}

              {/* now line on today's column */}
              <div
                style={{
                  position: "absolute",
                  left: TODAY_INDEX * GEO.dayW,
                  top: 8 * (GEO.rowH + GEO.brk) - 4,
                  width: GEO.dayW,
                  height: 1.5,
                  background: "#BA1A1A",
                  opacity: 0.85,
                }}
              >
                <div
                  style={{
                    width: 5,
                    height: 5,
                    borderRadius: 3,
                    background: "#BA1A1A",
                    marginTop: -1.8,
                  }}
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      {tapPulse ? (
        <div
          style={{
            position: "absolute",
            left: tapPulse.x - tapPulse.r,
            top: tapPulse.y - tapPulse.r,
            width: tapPulse.r * 2,
            height: tapPulse.r * 2,
            borderRadius: tapPulse.r,
            border: "2px solid rgba(11,87,208,0.55)",
            opacity: tapPulse.opacity,
            background: "rgba(11,87,208,0.10)",
          }}
        />
      ) : null}

      {dim > 0 ? (
        <div style={{position: "absolute", inset: 0, background: roles.surface, opacity: dim, pointerEvents: "none"}} />
      ) : null}

      {children}

      {/* NavigationBar */}
      <div
        style={{
          position: "absolute",
          left: 0,
          right: 0,
          top: GEO.navTop,
          height: 80,
          background: roles.surfaceContainer,
          display: "flex",
          borderTop: `1px solid ${roles.outlineVariant}66`,
        }}
      >
        {[
          {label: "课表", icon: "calendar"},
          {label: "今天", icon: "today"},
          {label: "课程", icon: "book"},
          {label: "设置", icon: "tune"},
        ].map((it, i) => (
          <div key={it.label} style={{flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 4}}>
            <div
              style={{
                width: 64,
                height: 32,
                borderRadius: 16,
                display: "grid",
                placeItems: "center",
                background: i === 0 ? roles.secondaryContainer : "transparent",
              }}
            >
              <Icon
                name={it.icon}
                size={22}
                color={i === 0 ? roles.onSecondaryContainer : roles.onSurfaceVariant}
              />
            </div>
            <div
              style={{
                fontSize: 11,
                fontWeight: 600,
                color: i === 0 ? roles.onSurface : roles.onSurfaceVariant,
              }}
            >
              {it.label}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
