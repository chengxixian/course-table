import {useEffect, useState} from "react";
import {continueRender, delayRender, staticFile} from "remotion";

/**
 * Loads the two faces the app itself bundles (pubspec.yaml):
 *   FangSongCN -> FandolFang-Regular.otf   (GPL-3.0 + font exception)
 *   TimesNewRoman -> LiberationSerif       (SIL OFL 1.1)
 * Copied from D:\hsu_flutter\assets\fonts_ofl\ into public/fonts/.
 */
const FACES: {family: string; file: string; weight?: string}[] = [
  {family: "FandolFang", file: "fonts/FandolFang-Regular.otf"},
  {family: "LiberationSerif", file: "fonts/LiberationSerif-Regular.ttf"},
];

export const useAppFonts = () => {
  const [handle] = useState(() => delayRender("Loading app fonts"));
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const run = async () => {
      try {
        await Promise.all(
          FACES.map(async (face) => {
            const font = new FontFace(face.family, `url(${staticFile(face.file)})`, {
              weight: face.weight ?? "400",
            });
            const loadedFace = await font.load();
            document.fonts.add(loadedFace);
          }),
        );
        await document.fonts.ready;
      } catch (err) {
        // Never block a render on a font: fall back to the serif stack.
        console.error("font load failed", err);
      }
      if (!cancelled) {
        setLoaded(true);
        continueRender(handle);
      }
    };
    run();
    return () => {
      cancelled = true;
    };
  }, [handle]);

  return loaded;
};
