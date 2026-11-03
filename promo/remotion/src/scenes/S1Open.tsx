import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop} from "../ui/Backdrop";
import {easeEmphasized, easeOutCubic, enter, prog} from "../lib/anim";
import type {Frame, Layout} from "../frame";
import {useRoles} from "../ui/roles";

const KICKER = "MATERIAL 3 · 课程表";
const POINTS = ["0 广告", "流畅", "简洁", "美观", "方便"];

/**
 * S1 — 08:00 → 课程表.
 * Motion: the numerals are pressed in through a rising mask (letterpress),
 * the running head types on character by character, then the wordmark lands.
 */
export const S1Open: React.FC<{frame: number; layout: Layout; f: Frame}> = ({frame, layout, f}) => {
  const roles = useRoles();
  const isV = layout === "vertical";

  const L = isV
    ? {
        kicker: {x: 84, y: 196, size: 32, rule: 44},
        hero: {x: 84, y: 300, size: 300, bar: {w: 8, h: 168}},
        line: {x: 84, y: 700, size: 38},
        mark: {x: 84, y: 1178, size: 240},
        tag: {x: 88, y: 1500, size: 54, rule: 96},
        points: {x: 90, y: 1638, size: 34},
      }
    : {
        kicker: {x: 120, y: 262, size: 24, rule: 32},
        hero: {x: 120, y: 320, size: 210, bar: {w: 6, h: 120}},
        line: {x: 122, y: 578, size: 28},
        mark: {x: 1010, y: 372, size: 176},
        tag: {x: 1012, y: 676, size: 36, rule: 80},
        points: {x: 1012, y: 764, size: 24},
      };

  const kIn = enter({frame, start: 0, dur: 14, rise: 16, curve: easeOutCubic});
  const hIn = enter({frame, start: 4, dur: 26, rise: 40});
  const lIn = enter({frame, start: 30, dur: 22, rise: 26});
  const mIn = enter({frame, start: 46, dur: 30, rise: 64});
  const tIn = enter({frame, start: 68, dur: 24, rise: 30});
  const pIn = enter({frame, start: 86, dur: 24, rise: 24});
  const bar = easeEmphasized(prog(frame, 2, 26));
  const rule = easeEmphasized(prog(frame, 72, 26));
  const baseline = easeEmphasized(prog(frame, 26, 24));
  // letterpress mask: the numeral block is uncovered bottom-up
  const mask = easeEmphasized(prog(frame, 4, 26));

  return (
    <AbsoluteFill>
      <Backdrop f={f} layout={layout} frame={frame} />

      {/* running head — types on */}
      <div
        style={{
          position: "absolute",
          left: L.kicker.x,
          top: L.kicker.y,
          display: "flex",
          alignItems: "center",
          gap: 16,
          opacity: kIn.opacity,
          transform: kIn.transform,
        }}
      >
        <div style={{width: L.kicker.rule * bar, height: isV ? 4 : 3, background: roles.primary, borderRadius: 2}} />
        <div
          style={{
            display: "flex",
            fontFamily: "var(--cn)",
            fontSize: L.kicker.size,
            fontWeight: 700,
            color: roles.primary,
          }}
        >
          {KICKER.split("").map((ch, i) => {
            const p = easeOutCubic(prog(frame, 2 + i * 1.05, 9));
            return (
              <span
                key={`${ch}-${i}`}
                style={{
                  display: "inline-block",
                  opacity: p,
                  transform: `translateY(${(1 - p) * L.kicker.size * 0.42}px)`,
                  letterSpacing: L.kicker.size * 0.14,
                  width: ch === " " ? L.kicker.size * 0.34 : undefined,
                }}
              >
                {ch === " " ? "" : ch}
              </span>
            );
          })}
        </div>
      </div>

      {/* 08:00 with the WeekHero bar — pressed through a mask */}
      <div style={{position: "absolute", left: L.hero.x, top: L.hero.y, display: "flex", alignItems: "flex-start", gap: isV ? 24 : 16}}>
        <div
          style={{
            width: L.hero.bar.w,
            height: L.hero.bar.h * bar,
            background: roles.primary,
            borderRadius: 3,
            marginTop: L.hero.size * 0.24,
            opacity: bar,
          }}
        />
        <div style={{opacity: hIn.opacity, transform: hIn.transform}}>
          <div
            style={{
              clipPath: `inset(0 0 ${(1 - mask) * 100}% 0)`,
            }}
          >
            <div
              style={{
                fontFamily: "var(--latin)",
                fontSize: L.hero.size,
                lineHeight: 1,
                letterSpacing: -L.hero.size * 0.035,
                fontWeight: 400,
                color: roles.onSurface,
              }}
            >
              08:00
            </div>
          </div>
          {/* baseline rule draws under the numerals */}
          <div
            style={{
              marginTop: L.hero.size * 0.06,
              width: (isV ? 560 : 392) * baseline,
              height: 3,
              background: roles.outlineVariant,
              opacity: 0.9,
            }}
          />
        </div>
      </div>

      {/* course line */}
      <div
        style={{
          position: "absolute",
          left: L.line.x,
          top: L.line.y,
          fontFamily: "var(--cn)",
          fontSize: L.line.size,
          color: roles.onSurfaceVariant,
          letterSpacing: 0.6,
          whiteSpace: "nowrap",
          opacity: lIn.opacity,
          transform: lIn.transform,
        }}
      >
        第 1–2 节 · 高等数学 A1 · 文渊 1201
      </div>

      {/* wordmark */}
      <div
        style={{
          position: "absolute",
          left: L.mark.x,
          top: L.mark.y,
          opacity: mIn.opacity,
          transform: mIn.transform,
        }}
      >
        <div
          style={{
            fontFamily: "var(--cn)",
            fontSize: L.mark.size,
            fontWeight: 600,
            letterSpacing: -L.mark.size * 0.012,
            lineHeight: 1,
            color: roles.onSurface,
          }}
        >
          课程表
        </div>
      </div>

      {/* rule + tagline */}
      <div style={{position: "absolute", left: L.tag.x, top: L.tag.y - (isV ? 44 : 34)}}>
        <div style={{width: L.tag.rule * rule, height: 3, background: roles.primary, borderRadius: 2}} />
      </div>
      <div
        style={{
          position: "absolute",
          left: L.tag.x,
          top: L.tag.y,
          fontFamily: "var(--cn)",
          fontSize: L.tag.size,
          color: roles.onSurface,
          letterSpacing: 1,
          opacity: tIn.opacity,
          transform: tIn.transform,
          whiteSpace: "nowrap",
        }}
      >
        一学期的课，排成一张表。
      </div>

      {/* selling points */}
      <div
        style={{
          position: "absolute",
          left: L.points.x,
          top: L.points.y,
          display: "flex",
          alignItems: "center",
          gap: L.points.size * 0.55,
          opacity: pIn.opacity,
          transform: pIn.transform,
          whiteSpace: "nowrap",
        }}
      >
        {POINTS.map((w, i) => (
          <React.Fragment key={w}>
            {i > 0 ? (
              <div
                style={{
                  width: L.points.size * 0.15,
                  height: L.points.size * 0.15,
                  borderRadius: 999,
                  background: roles.outline,
                  opacity: 0.7,
                }}
              />
            ) : null}
            <div
              style={{
                fontFamily: "var(--cn)",
                fontSize: L.points.size,
                letterSpacing: i === 0 ? L.points.size * 0.08 : L.points.size * 0.14,
                fontWeight: i === 0 ? 700 : 500,
                color: i === 0 ? roles.primary : roles.onSurface,
              }}
            >
              {w}
            </div>
          </React.Fragment>
        ))}
      </div>
    </AbsoluteFill>
  );
};
