import React from "react";
import {AbsoluteFill, Sequence, useCurrentFrame} from "remotion";
import {FRAMES, type Layout} from "./frame";
import {FS, SHOTS} from "./timeline";
import {useAppFonts} from "./fonts";
import {ThemeCtx, DEFAULT_ROLES} from "./ui/roles";
import {S1Open} from "./scenes/S1Open";
import {S2Week} from "./scenes/S2Week";
import {S3Detail} from "./scenes/S3Detail";
import {S4Import} from "./scenes/S4Import";
import {S5Drag} from "./scenes/S5Drag";
import {S6Widgets} from "./scenes/S6Widgets";
import {S7Outro} from "./scenes/S7Outro";
import {Bgm, DEFAULT_BGM_FILE, DEFAULT_BGM_VOLUME, SfxLayer} from "./audio";

/**
 * Scenes are authored in 30fps beats; at delivery we divide the current frame
 * by FS so every curve is evaluated twice as often. Same timing, twice the
 * temporal resolution.
 */
const Shot: React.FC<{
  children: (local: number) => React.ReactNode;
}> = ({children}) => {
  const local = useCurrentFrame();
  return <AbsoluteFill>{children(local / FS)}</AbsoluteFill>;
};

type MainProps = {
  layout?: Layout;
  bgm?: boolean;
  bgmFile?: string;
  bgmVolume?: number;
};

export const Main: React.FC<MainProps> = ({
  layout = "vertical",
  bgm = true,
  bgmFile = DEFAULT_BGM_FILE,
  bgmVolume = DEFAULT_BGM_VOLUME,
}) => {
  const f = FRAMES[layout];
  useAppFonts();

  return (
    <ThemeCtx.Provider value={DEFAULT_ROLES}>
      <AbsoluteFill
        style={
          {
            width: f.W,
            height: f.H,
            background: DEFAULT_ROLES.surface,
            "--cn": '"FandolFang", "Noto Serif CJK SC", serif',
            "--latin": '"LiberationSerif", "Times New Roman", serif',
            fontFamily: '"FandolFang", "LiberationSerif", serif',
            fontKerning: "normal",
            textRendering: "geometricPrecision",
            WebkitFontSmoothing: "antialiased",
          } as React.CSSProperties
        }
      >
        <Sequence from={SHOTS.open.from * FS} durationInFrames={SHOTS.open.dur * FS} name="S1 open">
          <Shot>{(l) => <S1Open frame={l} layout={layout} f={f} />}</Shot>
        </Sequence>
        <Sequence from={SHOTS.week.from * FS} durationInFrames={SHOTS.week.dur * FS} name="S2 week">
          <Shot>{(l) => <S2Week frame={l} layout={layout} f={f} />}</Shot>
        </Sequence>
        <Sequence from={SHOTS.detail.from * FS} durationInFrames={SHOTS.detail.dur * FS} name="S3 detail">
          <Shot>{(l) => <S3Detail local={l} layout={layout} f={f} />}</Shot>
        </Sequence>
        <Sequence from={SHOTS.import.from * FS} durationInFrames={SHOTS.import.dur * FS} name="S4 import">
          <Shot>{(l) => <S4Import local={l} layout={layout} f={f} />}</Shot>
        </Sequence>
        <Sequence from={SHOTS.drag.from * FS} durationInFrames={SHOTS.drag.dur * FS} name="S5 drag">
          <Shot>{(l) => <S5Drag local={l} layout={layout} f={f} />}</Shot>
        </Sequence>
        <Sequence from={SHOTS.widgets.from * FS} durationInFrames={SHOTS.widgets.dur * FS} name="S6 widgets">
          <Shot>{(l) => <S6Widgets local={l} layout={layout} f={f} />}</Shot>
        </Sequence>
        <Sequence from={SHOTS.outro.from * FS} durationInFrames={SHOTS.outro.dur * FS} name="S7 outro">
          <Shot>{(l) => <S7Outro local={l} layout={layout} f={f} />}</Shot>
        </Sequence>
        <Bgm enabled={bgm} file={bgmFile} volume={bgmVolume} />
        <SfxLayer />
      </AbsoluteFill>
    </ThemeCtx.Provider>
  );
};
