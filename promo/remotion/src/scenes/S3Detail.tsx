import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop} from "../ui/Backdrop";
import {Caption} from "../ui/Caption";
import {Phone} from "../ui/Phone";
import {BLOCKS, blockOf, courseById} from "../data";
import {GEO, WeekScreen, blockRect} from "../ui/WeekScreen";
import {CoursePopup, type Rect} from "../ui/CoursePopup";
import {easeEmphasized, mix, prog, spring} from "../lib/anim";
import {phoneX, type Frame, type Layout} from "../frame";

const POPUP_W = 320;
const POPUP_H = 328;

/**
 * S3 — tap a block; the anchored popup grows out of it (product popup:
 * 400ms, position curve cubic-bezier(0.05,0.7,0.1,1), 0.5→1.02→1.0 scale).
 * The push-in is framed so the left screen edge lands exactly on a grid column
 * and the day header sits at the top: no half-cut text.
 */
export const S3Detail: React.FC<{local: number; layout: Layout; f: Frame}> = ({local, layout, f}) => {
  const scale = f.phone.w / 412;
  const block = blockOf("c2", 2, 3);
  const src = blockRect(block); // dp, in a 412×915 screen

  const t = easeEmphasized(prog(local, 4, 26));
  const z = mix(1, 1.49, t);
  const wx0 = mix(0, GEO.gridLeft, t);
  const wy0 = mix(0, GEO.cardTop - 16, t);

  const bs = {x: (src.x - wx0) * z, y: (src.y - wy0) * z, w: src.w * z, h: src.h * z};
  const bCx = bs.x + bs.w / 2;
  const bCy = bs.y + bs.h / 2;

  const target: Rect = {
    x: Math.min(Math.max(bCx - POPUP_W / 2, 16), 412 - POPUP_W - 16),
    y: Math.min(Math.max(bCy - POPUP_H / 2, 34), 915 - 26 - POPUP_H),
    w: POPUP_W,
    h: POPUP_H,
  };

  const tp = easeEmphasized(prog(local, 24, 14));
  const morph: Rect = {
    x: mix(bs.x, target.x, tp),
    y: mix(bs.y, target.y, tp),
    w: mix(bs.w, target.w, tp),
    h: mix(bs.h, target.h, tp),
  };
  const sp = spring(prog(local, 24, 20), 6.2, 10.4);
  const popupScale = tp <= 0 ? 0.5 : mix(0.5, 1, sp);

  const tapR = mix(26, 58, prog(local, 10, 14));
  const tapO = 1 - prog(local, 12, 22);
  const showPopup = local >= 23;

  return (
    <AbsoluteFill>
      <Backdrop f={f} layout={layout} frame={local} draw={1} />
      <div style={{position: "absolute", left: phoneX(f, layout), top: f.phone.y}}>
        <Phone scale={scale} statusBar={false}>
          <div
            style={{
              position: "absolute",
              inset: 0,
              transformOrigin: "0 0",
              transform: `translate(${-wx0 * z}px, ${-wy0 * z}px) scale(${z})`,
            }}
          >
            <WeekScreen
              frame={local}
              blocks={BLOCKS}
              hideChrome
              tapKey={local > 8 && local < 40 ? block.key : null}
              tapPulse={{x: bCx / z + wx0, y: bCy / z + wy0, r: tapR / z, opacity: Math.max(0, tapO)}}
            />
          </div>
          {showPopup ? (
            <CoursePopup
              course={courseById("c2")}
              rect={morph}
              scale={popupScale}
              opacity={Math.min(1, tp * 3)}
            />
          ) : null}
        </Phone>
      </div>
      <Caption shot="detail" local={local} layout={layout} f={f} />
    </AbsoluteFill>
  );
};
