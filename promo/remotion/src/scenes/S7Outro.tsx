import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop} from "../ui/Backdrop";
import {Phone} from "../ui/Phone";
import {BLOCKS} from "../data";
import {WeekScreen} from "../ui/WeekScreen";
import {DEFAULT_ROLES, PALETTE_ROLES, ThemeCtx, mixRolesStaggered, useRoles} from "../ui/roles";
import {easeEmphasized, enter, fade, mix, prog} from "../lib/anim";
import {phoneX, type Frame, type Layout} from "../frame";

/** S7 — the whole surface retints with the system palette, then the brand lands. */
export const S7Outro: React.FC<{local: number; layout: Layout; f: Frame}> = ({local, layout, f}) => {
  const isV = layout === "vertical";
  const scale = f.phone.w / 412;

  const t1 = easeEmphasized(prog(local, 0, 20));
  const t2 = easeEmphasized(prog(local, 20, 20));
  const roles = t2 <= 0 ? mixRolesStaggered(DEFAULT_ROLES, PALETTE_ROLES.teal, t1) : mixRolesStaggered(PALETTE_ROLES.teal, PALETTE_ROLES.rose, t2);

  const phoneOut = fade(local, 0, 60, 1, 18);
  const kickerOut = fade(local, 0, 52, 1, 12);
  const markIn = enter({frame: local, start: 46, dur: 24, rise: 64});
  const lineIn = enter({frame: local, start: 58, dur: 22, rise: 32});
  const factIn = enter({frame: local, start: 62, dur: 22, rise: 24});
  const rule = easeEmphasized(prog(local, 60, 22));

  return (
    <AbsoluteFill>
      <ThemeCtx.Provider value={roles}>
        <Backdrop f={f} layout={layout} frame={local} draw={1} />
        <div
          style={{
            position: "absolute",
            left: phoneX(f, layout),
            top: f.phone.y - (1 - phoneOut) * 30,
            opacity: phoneOut,
            transform: `scale(${mix(1, 1.04, prog(local, 0, 60))})`,
            transformOrigin: "center top",
          }}
        >
          <Phone scale={scale} statusBar={false}>
            <WeekScreen frame={local} blocks={BLOCKS} heroHighlight={1} />
          </Phone>
        </div>

        {/* shot label */}
        <div
          style={{
            position: "absolute",
            left: f.margin,
            top: f.caption.y,
            display: "flex",
            alignItems: "center",
            gap: 14,
            opacity: kickerOut * 0.95,
          }}
        >
          <div style={{width: 40, height: 3, background: roles.primary, borderRadius: 2}} />
          <div
            style={{
              fontFamily: "var(--cn)",
              fontSize: isV ? 28 : 22,
              letterSpacing: 4,
              fontWeight: 700,
              color: roles.primary,
            }}
          >
            动态色彩 / DYNAMIC COLOR
          </div>
        </div>

        {/* final card */}
        <div
          style={{
            position: "absolute",
            left: 0,
            right: 0,
            top: isV ? 742 : 300,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
          }}
        >
          <div
            style={{
              fontFamily: "var(--cn)",
              fontSize: isV ? 212 : 150,
              fontWeight: 600,
              letterSpacing: -4,
              lineHeight: 1,
              color: roles.onSurface,
              opacity: markIn.opacity,
              transform: markIn.transform,
            }}
          >
            课程表
          </div>
          <div
            style={{
              marginTop: isV ? 34 : 24,
              width: 120 * rule,
              height: 3,
              background: roles.primary,
              borderRadius: 2,
            }}
          />
          <div
            style={{
              marginTop: isV ? 34 : 22,
              fontFamily: "var(--cn)",
              fontSize: isV ? 44 : 32,
              color: roles.onSurfaceVariant,
              letterSpacing: 1,
              opacity: lineIn.opacity,
              transform: lineIn.transform,
              whiteSpace: "nowrap",
            }}
          >
            跟随系统的颜色，也是你的颜色。
          </div>
          <div
            style={{
              marginTop: isV ? 26 : 16,
              display: "flex",
              alignItems: "center",
              gap: 18,
              fontFamily: "var(--cn)",
              fontSize: isV ? 27 : 20,
              color: roles.onSurfaceVariant,
              opacity: factIn.opacity * 0.86,
              transform: factIn.transform,
              letterSpacing: 1.2,
              whiteSpace: "nowrap",
            }}
          >
            <span>Material 3</span>
            <span style={{width: 5, height: 5, borderRadius: 3, background: roles.outline}} />
            <span>Android</span>
            <span style={{width: 5, height: 5, borderRadius: 3, background: roles.outline}} />
            <span>GPL-3.0</span>
          </div>
        </div>
      </ThemeCtx.Provider>
    </AbsoluteFill>
  );
};
