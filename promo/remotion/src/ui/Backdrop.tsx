import React from "react";
import {EASE} from "../theme";
import {easeEmphasized, prog} from "../lib/anim";
import type {Frame, Layout} from "../frame";
import {useRoles} from "./roles";

/**
 * Paper field: hairline column rules (the week grid, abstracted) drawn over
 * the app's own surface colour. No invented gradient skin.
 */
export const Backdrop: React.FC<{
  f: Frame;
  layout: Layout;
  frame: number;
  draw?: number; // 0..1 progress for the rules
  tone?: "surface" | "plain";
}> = ({f, layout, frame, draw = 1, tone = "surface"}) => {
  const roles = useRoles();
  const cols = 7;
  return (
    <div style={{position: "absolute", inset: 0, background: roles.surface, overflow: "hidden"}}>
      {tone === "surface" ? (
        <div
          style={{
            position: "absolute",
            inset: 0,
            background: `radial-gradient(120% 70% at 50% 8%, ${roles.primaryContainer}55 0%, transparent 62%)`,
            opacity: 0.55,
          }}
        />
      ) : null}
      <div style={{position: "absolute", inset: 0}}>
        {Array.from({length: cols + 1}).map((_, i) => {
          const x = (f.W / cols) * i;
          const p = easeEmphasized(prog(frame, 6 + i * 2, 22));
          return (
            <div
              key={`v${i}`}
              style={{
                position: "absolute",
                left: x,
                top: 0,
                width: 1,
                height: `${Math.min(1, p * draw) * 100}%`,
                background: roles.outlineVariant,
                opacity: 0.55,
              }}
            />
          );
        })}
        {[0.22, 0.5, 0.78].map((t, i) => {
          const p = easeEmphasized(prog(frame, 14 + i * 4, 26));
          return (
            <div
              key={`h${i}`}
              style={{
                position: "absolute",
                top: f.H * t,
                left: 0,
                height: 1,
                width: `${Math.min(1, p * draw) * 100}%`,
                background: roles.outlineVariant,
                opacity: 0.4,
              }}
            />
          );
        })}
      </div>
    </div>
  );
};

/** Reusable paper card used by the editorial layer (not an app screen). */
export const PaperCard: React.FC<{
  children: React.ReactNode;
  style?: React.CSSProperties;
  radius?: number;
  pad?: number;
}> = ({children, style, radius = 24, pad = 22}) => {
  const roles = useRoles();
  return (
    <div
      style={{
        background: roles.surfaceContainerLowest,
        border: `1px solid ${roles.outlineVariant}`,
        borderRadius: radius,
        padding: pad,
        boxSizing: "border-box",
        boxShadow: "0 10px 30px rgba(20,20,32,0.05)",
        transition: `all 200ms ${EASE.standard}`,
        ...style,
      }}
    >
      {children}
    </div>
  );
};
