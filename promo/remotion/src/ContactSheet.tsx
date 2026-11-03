import React from "react";
import {AbsoluteFill, Img, staticFile} from "remotion";
import {FrameLabel} from "./ui/SheetLabel";

export const SHEET_FRAMES = [
  {n: "k01", f: 240, note: "S1 开场字标"},
  {n: "k02", f: 600, note: "S2 周课表 · 课块落版"},
  {n: "k03", f: 720, note: "S2 栅格滑到周末"},
  {n: "k04", f: 1040, note: "S3 课程详情弹层"},
  {n: "k05", f: 1180, note: "S4 搜索 + 350 所"},
  {n: "k06", f: 1400, note: "S4 七种导入 + 日历"},
  {n: "k07", f: 1560, note: "S5 拖拽中 · 落点高亮"},
  {n: "k08", f: 1720, note: "S5 落槽归位"},
  {n: "k09", f: 2000, note: "S6 四种小组件"},
  {n: "k10", f: 2210, note: "S7 青瓷色迁移"},
  {n: "k11", f: 2280, note: "S7 山茶粉 + 字标"},
  {n: "k12", f: 2370, note: "S7 尾卡 hold"},
];

const COLS = 4;
const CELL_W = 270;
const CELL_H = 480;
const GAP = 22;
const PAD = 40;

export const ContactSheet: React.FC = () => (
  <AbsoluteFill style={{background: "#FBF9FF", fontFamily: "var(--cn)"}}>
    <div style={{position: "absolute", left: PAD, top: 34, fontSize: 30, letterSpacing: 1, color: "#1A1B20"}}>
      课程表 · 宣传片关键帧
    </div>
    <div style={{position: "absolute", left: PAD, top: 74, fontSize: 17, letterSpacing: 2, color: "#0B57D0"}}>
      1080 × 1920 · 60fps · 40.0s · 12 帧
    </div>
    <div
      style={{
        position: "absolute",
        left: PAD,
        top: 120,
        display: "grid",
        gridTemplateColumns: `repeat(${COLS}, ${CELL_W}px)`,
        gap: GAP,
      }}
    >
      {SHEET_FRAMES.map(({n, f, note}) => (
        <div key={n} style={{width: CELL_W}}>
          <Img
            src={staticFile(`qa/${n}.png`)}
            style={{width: CELL_W, height: CELL_H, borderRadius: 8, border: "1px solid #C6C5D0"}}
          />
          <FrameLabel frame={f} note={note} />
        </div>
      ))}
    </div>
  </AbsoluteFill>
);
