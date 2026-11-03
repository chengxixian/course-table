import React from "react";
import {Composition} from "remotion";
import {Main} from "./Main";
import {Cover} from "./Cover";
import {ContactSheet} from "./ContactSheet";
import {DURATION, FPS} from "./timeline";

export const Root: React.FC = () => (
  <>
    <Composition
      id="HsuPromoVertical"
      component={Main}
      durationInFrames={DURATION}
      fps={FPS}
      width={1080}
      height={1920}
      defaultProps={{
        layout: "vertical" as const,
        bgm: true,
        bgmFile: "audio/bgm/bgm-final.wav",
        bgmVolume: 0.5,
      }}
    />
    <Composition
      id="HsuPromoWide"
      component={Main}
      durationInFrames={DURATION}
      fps={FPS}
      width={1920}
      height={1080}
      defaultProps={{
        layout: "wide" as const,
        bgm: true,
        bgmFile: "audio/bgm/bgm-final.wav",
        bgmVolume: 0.5,
      }}
    />
    <Composition
      id="HsuCoverVertical"
      component={Cover}
      durationInFrames={1}
      fps={FPS}
      width={1080}
      height={1920}
      defaultProps={{layout: "vertical" as const}}
    />
    <Composition
      id="HsuCoverWide"
      component={Cover}
      durationInFrames={1}
      fps={FPS}
      width={1920}
      height={1080}
      defaultProps={{layout: "wide" as const}}
    />
    <Composition
      id="ContactSheet"
      component={ContactSheet}
      durationInFrames={1}
      fps={FPS}
      width={1226}
      height={1740}
    />
  </>
);
