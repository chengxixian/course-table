import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop} from "../ui/Backdrop";
import {Caption} from "../ui/Caption";
import {Phone} from "../ui/Phone";
import {BLOCKS} from "../data";
import {GEO, WeekScreen} from "../ui/WeekScreen";
import {easeEmphasized, easeSnap, mix, prog} from "../lib/anim";
import {phoneX, type Frame, type Layout} from "../frame";
import {useRoles} from "../ui/roles";

/**
 * S2 — the week grid stamps itself into place.
 * Motion: gentle dolly (1.000 → 1.014) + backdrop parallax, blocks stamp in,
 * one clipped scan line crosses the grid while they land, then the grid slips
 * to the weekend.
 */
export const S2Week: React.FC<{frame: number; layout: Layout; f: Frame}> = ({frame, layout, f}) => {
  const roles = useRoles();
  const scale = f.phone.w / 412;
  const inP = easeEmphasized(prog(frame, 0, 26));
  const shift = mix(0, 264, easeSnap(prog(frame, 98, 30)));
  const heroHi = prog(frame, 6, 22);
  const drift = mix(1, 1.014, easeEmphasized(prog(frame, 0, 240)));

  const scanP = easeEmphasized(prog(frame, 22, 40));
  const scanY = mix(-180, 705, scanP);
  const scanO = scanP <= 0 || scanP >= 1 ? 0 : Math.sin(Math.PI * scanP) * 0.9;

  return (
    <AbsoluteFill>
      {/* backdrop: moves slower than the phone (parallax) */}
      <div
        style={{
          position: "absolute",
          inset: -40,
          transform: `scale(${mix(1.02, 1.005, easeEmphasized(prog(frame, 0, 240)))}) translateY(${mix(-18, 0, inP)}px)`,
        }}
      >
        <Backdrop f={f} layout={layout} frame={frame} />
      </div>

      <div
        style={{
          position: "absolute",
          left: phoneX(f, layout),
          top: f.phone.y + (1 - inP) * 300,
          opacity: mix(0, 1, prog(frame, 0, 14)),
          transform: `scale(${drift})`,
          transformOrigin: "center 40%",
        }}
      >
        <Phone scale={scale}>
          <WeekScreen
            frame={frame}
            blocks={BLOCKS}
            stampOn
            stampStart={30}
            stampStep={7}
            shiftX={shift}
            heroHighlight={heroHi}
          >
            {scanO > 0 ? (
              <div
                style={{
                  position: "absolute",
                  left: GEO.cardLeft,
                  top: GEO.cardTop,
                  width: GEO.cardW,
                  height: 705,
                  borderRadius: 24,
                  overflow: "hidden",
                  pointerEvents: "none",
                }}
              >
                <div
                  style={{
                    position: "absolute",
                    left: 0,
                    right: 0,
                    top: scanY,
                    height: 180,
                    background: `linear-gradient(to bottom, rgba(11,87,208,0) 0%, ${roles.primary}2e 50%, rgba(11,87,208,0) 100%)`,
                    opacity: scanO,
                  }}
                />
                <div
                  style={{
                    position: "absolute",
                    left: 0,
                    right: 0,
                    top: scanY + 88,
                    height: 1.5,
                    background: roles.primary,
                    opacity: scanO * 0.5,
                  }}
                />
              </div>
            ) : null}
          </WeekScreen>
        </Phone>
      </div>
      <Caption shot="week" local={frame} layout={layout} f={f} />
    </AbsoluteFill>
  );
};
