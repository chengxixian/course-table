import React from "react";
import {useRoles} from "./roles";

export const SCREEN_W = 412;
export const SCREEN_H = 915;
const BEZEL = 12;

/**
 * Android device mock. Screen contents are laid out in dp (412×915) and the
 * whole screen is scaled by the caller, so every in-app size stays the same
 * number as the Flutter source (11dp course name, 30dp headline, ...).
 */
export const Phone: React.FC<{
  scale: number;
  children: React.ReactNode;
  statusBar?: boolean;
  style?: React.CSSProperties;
}> = ({scale, children, statusBar = true, style}) => {
  const roles = useRoles();
  return (
    <div
      style={{
        width: (SCREEN_W + BEZEL * 2) * scale,
        height: (SCREEN_H + BEZEL * 2) * scale,
        position: "relative",
        borderRadius: 46 * scale,
        background: "#0C0C0F",
        boxShadow: "0 26px 60px rgba(16,16,24,0.24)",
        ...style,
      }}
    >
      <div
        style={{
          position: "absolute",
          left: BEZEL * scale,
          top: BEZEL * scale,
          width: SCREEN_W * scale,
          height: SCREEN_H * scale,
          borderRadius: 34 * scale,
          overflow: "hidden",
          background: roles.surface,
        }}
      >
        <div
          style={{
            width: SCREEN_W,
            height: SCREEN_H,
            transform: `scale(${scale})`,
            transformOrigin: "top left",
            position: "relative",
            overflow: "hidden",
            background: roles.surface,
          }}
        >
          {children}
          {statusBar ? <StatusBar /> : null}
        </div>
      </div>
    </div>
  );
};

const StatusBar: React.FC = () => {
  const roles = useRoles();
  return (
    <div
      style={{
        position: "absolute",
        top: 0,
        left: 0,
        right: 0,
        height: 28,
        display: "flex",
        alignItems: "center",
        padding: "0 14px",
        justifyContent: "space-between",
        zIndex: 60,
      }}
    >
      <div style={{fontSize: 11, fontWeight: 600, letterSpacing: 0.2, color: roles.onSurface}}>18:32</div>
      <div style={{display: "flex", alignItems: "center", gap: 4}}>
        <div style={{display: "flex", alignItems: "flex-end", gap: 1.4, height: 9}}>
          {[3, 4.5, 6, 7.5].map((h, i) => (
            <div
              key={i}
              style={{width: 2, height: h, background: roles.onSurface, borderRadius: 1}}
            />
          ))}
        </div>
        <svg width="13" height="10" viewBox="0 0 13 10">
          <path d="M1 3.2 A8 8 0 0 1 12 3.2" stroke={roles.onSurface} strokeWidth="1.4" fill="none" strokeLinecap="round" />
          <path d="M3.6 5.6 A4.6 4.6 0 0 1 9.4 5.6" stroke={roles.onSurface} strokeWidth="1.4" fill="none" strokeLinecap="round" />
          <circle cx="6.5" cy="8.4" r="1.1" fill={roles.onSurface} />
        </svg>
        <div style={{display: "flex", alignItems: "center", gap: 1}}>
          <div
            style={{
              width: 15,
              height: 8,
              borderRadius: 2,
              border: `1px solid ${roles.onSurface}`,
              padding: 1,
              boxSizing: "border-box",
            }}
          >
            <div style={{width: "76%", height: "100%", background: roles.onSurface, borderRadius: 1}} />
          </div>
          <div style={{width: 1.4, height: 3.4, background: roles.onSurface, borderRadius: 1}} />
        </div>
      </div>
    </div>
  );
};
