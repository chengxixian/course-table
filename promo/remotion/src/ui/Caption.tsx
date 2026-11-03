import React from "react";
import {CAPTIONS, SHOTS, type ShotName} from "../timeline";
import {enter} from "../lib/anim";
import type {Frame, Layout} from "../frame";
import {useRoles} from "./roles";
import {easeOutCubic} from "../lib/anim";

/**
 * Caption grammar taken from the product's own PageHeader:
 * a 22×2 primary rule, a 9px/1.5-tracking kicker, then the headline.
 * At video scale: 44×4 rule, letterspaced kicker, 72px headline.
 */
export const Caption: React.FC<{
  shot: ShotName;
  local: number;
  layout: Layout;
  f: Frame;
}> = ({shot, local, layout, f}) => {
  const roles = useRoles();
  const {kicker, main, sub} = CAPTIONS[shot];
  const k = f.caption;
  const inK = enter({frame: local, start: 6, dur: 18, rise: 24, curve: easeOutCubic});
  const inM = enter({frame: local, start: 12, dur: 20, rise: 32});
  const inS = enter({frame: local, start: 20, dur: 20, rise: 24});
  const outP = Math.min(1, Math.max(0, (SHOTS[shot].dur - local) / 8));
  if (!main) return null;

  return (
    <div style={{position: "absolute", left: k.x, top: k.y, width: k.w, opacity: outP}}>
      <div style={{display: "flex", alignItems: "center", gap: 16, opacity: inK.opacity, transform: inK.transform}}>
        <div style={{width: layout === "vertical" ? 44 : 32, height: layout === "vertical" ? 4 : 3, background: roles.primary, borderRadius: 2}} />
        <div
          style={{
            fontSize: k.kicker,
            letterSpacing: k.kicker * 0.13,
            fontWeight: 700,
            color: roles.primary,
            fontFamily: "var(--cn)",
          }}
        >
          {kicker}
        </div>
      </div>
      <div
        style={{
          marginTop: k.gap,
          fontSize: k.main,
          lineHeight: 1.26,
          letterSpacing: -k.main * 0.012,
          fontWeight: 500,
          color: roles.onSurface,
          fontFamily: "var(--cn)",
          opacity: inM.opacity,
          transform: inM.transform,
          whiteSpace: "nowrap",
        }}
      >
        {main}
      </div>
      {sub ? (
        <div
          style={{
            marginTop: layout === "vertical" ? 10 : 8,
            fontSize: k.sub,
            lineHeight: 1.3,
            color: roles.onSurfaceVariant,
            fontFamily: "var(--cn)",
            opacity: inS.opacity,
            transform: inS.transform,
            whiteSpace: "nowrap",
          }}
        >
          {sub}
        </div>
      ) : null}
    </div>
  );
};
