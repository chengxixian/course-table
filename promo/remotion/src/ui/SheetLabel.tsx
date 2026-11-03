import React from "react";

export const FrameLabel: React.FC<{frame: number; note: string}> = ({frame, note}) => (
  <div style={{marginTop: 8, display: "flex", alignItems: "baseline", gap: 8}}>
    <div
      style={{
        fontFamily: '"LiberationSerif", serif',
        fontSize: 16,
        fontWeight: 700,
        color: "#0B57D0",
        minWidth: 46,
      }}
    >
      f{frame}
    </div>
    <div style={{fontFamily: '"FandolFang", serif', fontSize: 16, color: "#45464F"}}>{note}</div>
  </div>
);
