import React from "react";
import {AbsoluteFill} from "remotion";
import {Backdrop} from "../ui/Backdrop";
import {Caption} from "../ui/Caption";
import {Phone} from "../ui/Phone";
import {BLOCKS, blockOf} from "../data";
import {WeekScreen, blockRect} from "../ui/WeekScreen";
import {FloatingBlock} from "../ui/CoursePopup";
import {clamp, easeEmphasized, easeOutCubic, easeSnap, lag, mix, prog} from "../lib/anim";
import {phoneX, type Frame, type Layout} from "../frame";

const DRAGGED = "c3-1-5"; // 大学物理 · 星期一 5-6  -> 星期三 7-8
const TARGET = {day: 3, start: 7, span: 2};

/**
 * S5 — long-press, lift, drag, drop.
 * Motion: lift with elevation, two lagging ghosts behind the carried card,
 * a breathing drop-target, then the app's real 200ms snap.
 */
export const S5Drag: React.FC<{local: number; layout: Layout; f: Frame}> = ({local, layout, f}) => {
  const scale = f.phone.w / 412;
  const block = BLOCKS.find((b) => b.key === DRAGGED)!;
  const src = blockRect(block);
  const dst = blockRect({day: TARGET.day, start: TARGET.start, span: TARGET.span});

  const lift = easeOutCubic(prog(local, 6, 10));
  const move = easeEmphasized(prog(local, 16, 34));
  const snap = easeSnap(prog(local, 50, 6));

  // ghosts trail the carried card
  const ghost1 = easeEmphasized(lag(prog(local, 16, 34), 0.22));
  const ghost2 = easeEmphasized(lag(prog(local, 16, 34), 0.42));

  const arc = Math.sin(Math.PI * move) * -14;
  const pos = (m: number) => ({x: mix(src.x, dst.x, m), y: mix(src.y, dst.y, m) + Math.sin(Math.PI * m) * -14});
  const g1 = pos(ghost1);
  const g2 = pos(ghost2);
  const cur = pos(move);
  const landed = local >= 56;

  const hover = prog(local, 24, 8) * (1 - prog(local, 50, 6));
  const pulse = 1 + Math.sin(Math.PI * 2 * prog(local, 24, 26)) * 0.014;

  const zoom = 1.5;
  const origin = {x: 197, y: 470};

  const blocks = BLOCKS.map((b) =>
    b.key === DRAGGED && landed ? {...b, day: TARGET.day, start: TARGET.start, key: `${b.key}-moved`} : b,
  );

  return (
    <AbsoluteFill>
      <Backdrop f={f} layout={layout} frame={local} />
      <div style={{position: "absolute", left: phoneX(f, layout), top: f.phone.y}}>
        <Phone scale={scale} statusBar={false}>
          <div
            style={{
              position: "absolute",
              inset: 0,
              transform: `scale(${zoom})`,
              transformOrigin: `${origin.x}px ${origin.y}px`,
            }}
          >
            <WeekScreen
              frame={local}
              blocks={blocks}
              lifted={local >= 8 && local < 56 ? [DRAGGED] : []}
              highlight={local >= 24 && local < 58 ? TARGET : null}
            />

            {/* breathing drop target on top of the base highlight */}
            {hover > 0 && local < 58 ? (
              <div
                style={{
                  position: "absolute",
                  left: dst.x + 2,
                  top: dst.y + 2,
                  width: dst.w - 4,
                  height: dst.h - 4,
                  borderRadius: 12,
                  border: "2px solid rgba(66,133,244,0.9)",
                  boxSizing: "border-box",
                  transform: `scale(${pulse})`,
                  transformOrigin: "center center",
                  opacity: hover * 0.9,
                  boxShadow: "0 0 0 6px rgba(66,133,244,0.10)",
                }}
              />
            ) : null}

            {/* ghost trail */}
            {local >= 16 && local < 56 ? (
              <>
                <div style={{position: "absolute", left: g2.x, top: g2.y, opacity: 0.11, transform: "scale(0.97)"}}>
                  <FloatingBlock block={block} x={0} y={0} lift={0} shadow={false} />
                </div>
                <div style={{position: "absolute", left: g1.x, top: g1.y, opacity: 0.2, transform: "scale(0.985)"}}>
                  <FloatingBlock block={block} x={0} y={0} lift={0} shadow={false} />
                </div>
              </>
            ) : null}

            {local >= 6 && local < 58 ? (
              <FloatingBlock block={block} x={cur.x} y={cur.y} lift={lift * (1 - snap * 0.6)} />
            ) : null}

            {landed ? (
              <div
                style={{
                  position: "absolute",
                  left: dst.x,
                  top: dst.y,
                  width: dst.w,
                  height: dst.h,
                  borderRadius: 12,
                  boxShadow: "0 0 0 2px rgba(11,87,208,0.28)",
                  opacity: 1 - clamp((local - 56) / 16),
                  pointerEvents: "none",
                }}
              />
            ) : null}
          </div>
        </Phone>
      </div>
      <Caption shot="drag" local={local} layout={layout} f={f} />
    </AbsoluteFill>
  );
};
