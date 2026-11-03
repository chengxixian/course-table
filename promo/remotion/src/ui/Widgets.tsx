import React from "react";
import {BLOCKS, DAYS, SEMESTER} from "../data";
import {PALETTE} from "../theme";
import {useRoles} from "./roles";
import {Icon} from "./Icon";

/**
 * Widgets are authored at their real dp size (250dp for a 4-column widget,
 * 112dp for 2×2) and scaled up as a whole, so the internal type scale stays
 * exactly the one the home-screen widget uses.
 */
const BASE4 = 250;
const BASE2 = 112;

const Scale: React.FC<{w: number; baseW: number; baseH: number; children: React.ReactNode}> = ({
  w,
  baseW,
  baseH,
  children,
}) => {
  const s = w / baseW;
  return (
    <div style={{width: w, height: baseH * s, position: "relative"}}>
      <div style={{width: baseW, height: baseH, transform: `scale(${s})`, transformOrigin: "top left"}}>{children}</div>
    </div>
  );
};

const Shell: React.FC<{children: React.ReactNode; w: number; h: number}> = ({children, w, h}) => {
  const roles = useRoles();
  return (
    <div
      style={{
        width: w,
        height: h,
        borderRadius: 26,
        background: roles.surfaceContainerLowest,
        border: `1px solid ${roles.outlineVariant}`,
        boxSizing: "border-box",
        overflow: "hidden",
        fontFamily: "var(--cn)",
        color: roles.onSurface,
        boxShadow: "0 8px 22px rgba(20,20,32,0.10)",
      }}
    >
      {children}
    </div>
  );
};

/** 4×4 · 周视图 */
export const WeekWidget: React.FC<{w: number}> = ({w}) => {
  const roles = useRoles();
  const cell = (BASE4 - 20) / 7;
  return (
    <Scale w={w} baseW={BASE4} baseH={BASE4}>
      <Shell w={BASE4} h={BASE4}>
        <div style={{padding: "12px 10px", height: "100%", boxSizing: "border-box", display: "flex", flexDirection: "column"}}>
          <div style={{display: "flex", alignItems: "baseline", gap: 6}}>
            <div style={{fontSize: 9.5, fontWeight: 700, letterSpacing: 1, color: roles.onSurfaceVariant}}>第 8 周</div>
            <div style={{fontSize: 7, color: roles.onSurfaceVariant, opacity: 0.65}}>{SEMESTER.range}</div>
          </div>
          <div style={{display: "flex", marginTop: 7, paddingLeft: 0}}>
            {DAYS.map((d, i) => (
              <div
                key={d}
                style={{
                  width: cell,
                  textAlign: "center",
                  fontSize: 7.5,
                  fontWeight: i === 3 ? 700 : 400,
                  color: i === 3 ? roles.primary : roles.onSurfaceVariant,
                }}
              >
                {d}
              </div>
            ))}
          </div>
          <div style={{position: "relative", flex: 1, marginTop: 4}}>
            {Array.from({length: 5}).map((_, r) => (
              <div
                key={r}
                style={{
                  position: "absolute",
                  top: `${(r / 5) * 100}%`,
                  left: 0,
                  right: 0,
                  height: 1,
                  background: roles.outlineVariant,
                  opacity: 0.35,
                }}
              />
            ))}
            {[0, 1, 2, 3, 4, 5, 6].map((d) => (
              <div
                key={d}
                style={{
                  position: "absolute",
                  left: d * cell,
                  top: 0,
                  bottom: 0,
                  width: 1,
                  background: roles.outlineVariant,
                  opacity: 0.22,
                }}
              />
            ))}
            {BLOCKS.filter((b) => b.start <= 8).map((b) => {
              const pal = PALETTE[b.course.colorIndex];
              return (
                <div
                  key={b.key}
                  style={{
                    position: "absolute",
                    left: (b.day - 1) * cell + 2,
                    width: cell - 4,
                    top: `${((b.start - 1) / 8) * 100}%`,
                    height: `${(b.span / 8) * 100}%`,
                    background: pal.container,
                    borderLeft: `2px solid ${pal.accent}`,
                    borderRadius: 3,
                    boxSizing: "border-box",
                  }}
                />
              );
            })}
          </div>
        </div>
      </Shell>
    </Scale>
  );
};

/** 4×3 · 今日课程 */
export const TodayWidget: React.FC<{w: number}> = ({w}) => {
  const roles = useRoles();
  const H = 194;
  return (
    <Scale w={w} baseW={BASE4} baseH={H}>
      <Shell w={BASE4} h={H}>
        <div style={{padding: "12px 13px", height: "100%", boxSizing: "border-box", display: "flex", flexDirection: "column"}}>
          <div style={{display: "flex", alignItems: "center", gap: 5}}>
            <div style={{width: 5, height: 5, borderRadius: 3, background: roles.primary}} />
            <div style={{fontSize: 8, fontWeight: 700, letterSpacing: 1.1, color: roles.onSurfaceVariant}}>课程表 · 今天</div>
            <div style={{flex: 1}} />
            <div style={{fontSize: 8, color: roles.onSurfaceVariant}}>第 8 周</div>
          </div>
          <div style={{marginTop: 6, fontSize: 17, fontWeight: 600, letterSpacing: -0.4}}>10月22日 · 星期四</div>
          <div style={{marginTop: 1, fontSize: 8.5, color: roles.onSurfaceVariant}}>4 节课</div>

          <div style={{marginTop: 7, padding: "9px 10px", borderRadius: 16, background: roles.primaryContainer, color: roles.onPrimaryContainer}}>
            <div style={{fontSize: 7.5, fontWeight: 600, opacity: 0.72}}>下一节课 · 16:00</div>
            <div style={{marginTop: 1, fontSize: 13.5, fontWeight: 600}}>机械工程导论</div>
            <div style={{marginTop: 2, fontSize: 8.5, opacity: 0.9}}>文渊 1105 · 第 7-8 节</div>
          </div>

          <div style={{marginTop: 6, display: "flex", flexDirection: "column", gap: 3}}>
            {[
              {t: "08:00", n: "机械制图 A", c: 1},
              {t: "14:00", n: "数据结构", c: 4},
            ].map((r) => (
              <div
                key={r.t}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 6,
                  padding: "4px 8px",
                  borderRadius: 9,
                  background: PALETTE[r.c].container,
                  color: PALETTE[r.c].ink,
                }}
              >
                <div style={{fontSize: 8, fontWeight: 700, fontFamily: "var(--latin)"}}>{r.t}</div>
                <div style={{fontSize: 9}}>{r.n}</div>
              </div>
            ))}
          </div>
        </div>
      </Shell>
    </Scale>
  );
};

/** 2×2 · 今日小卡 */
export const SmallTodayWidget: React.FC<{w: number}> = ({w}) => {
  const roles = useRoles();
  return (
    <Scale w={w} baseW={BASE2} baseH={BASE2}>
      <Shell w={BASE2} h={BASE2}>
        <div style={{padding: 11, height: "100%", boxSizing: "border-box", display: "flex", flexDirection: "column"}}>
          <div style={{display: "flex", alignItems: "center", gap: 4}}>
            <div style={{width: 4, height: 4, borderRadius: 2, background: roles.primary}} />
            <div style={{fontSize: 7.5, letterSpacing: 0.9, fontWeight: 700, color: roles.onSurfaceVariant}}>今天</div>
          </div>
          <div style={{marginTop: 3, fontSize: 24, fontWeight: 600, lineHeight: 1, fontFamily: "var(--latin)"}}>22</div>
          <div style={{fontSize: 8, color: roles.onSurfaceVariant, marginTop: 1}}>10月 · 第 8 周</div>
          <div style={{marginTop: 5, fontSize: 8.5, color: roles.onSurfaceVariant}}>4 节课</div>
          <div style={{marginTop: "auto", fontSize: 8.5, fontWeight: 600, color: roles.primary, lineHeight: 1.25}}>
            16:00
            <br />
            机械工程导论
          </div>
        </div>
      </Shell>
    </Scale>
  );
};

/** 4×2 · 两日 */
export const TwoDayWidget: React.FC<{w: number}> = ({w}) => {
  const roles = useRoles();
  const H = 116;
  const cols = [
    {label: "今天 · 22", rows: [["08:00", "机械制图 A", 1], ["14:00", "数据结构", 4], ["16:00", "机械工程导论", 3]]},
    {label: "明天 · 23", rows: [["10:00", "英语听说", 5], ["16:00", "体育（篮球）", 6]]},
  ] as const;
  return (
    <Scale w={w} baseW={BASE4} baseH={H}>
      <Shell w={BASE4} h={H}>
        <div style={{padding: "11px 12px", display: "flex", gap: 12, height: "100%", boxSizing: "border-box"}}>
          {cols.map((col) => (
            <div key={col.label} style={{flex: 1, minWidth: 0}}>
              <div style={{fontSize: 8, fontWeight: 700, letterSpacing: 0.6, color: roles.onSurfaceVariant}}>{col.label}</div>
              <div style={{marginTop: 5, display: "flex", flexDirection: "column", gap: 4}}>
                {col.rows.map((r) => (
                  <div key={r[0] as string} style={{display: "flex", alignItems: "center", gap: 5}}>
                    <div style={{width: 3, height: 10, borderRadius: 2, background: PALETTE[r[2] as number].accent}} />
                    <div style={{fontSize: 7.5, fontFamily: "var(--latin)", color: roles.onSurfaceVariant, width: 24}}>{r[0]}</div>
                    <div style={{fontSize: 8.5, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis"}}>{r[1]}</div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </Shell>
    </Scale>
  );
};
