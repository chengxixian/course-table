/**
 * Renders QA stills from one bundle (fast iteration).
 * Usage: node scripts/stills.mjs [comp] frame1 frame2 ...
 *   comp defaults to HsuPromoVertical
 */
import {bundle} from "@remotion/bundler";
import {renderStill, selectComposition, openBrowser} from "@remotion/renderer";
import path from "node:path";
import fs from "node:fs";

const args = process.argv.slice(2);
const comp = args[0]?.startsWith("Hsu") ? args[0] : "HsuPromoVertical";
const frames = (args[0]?.startsWith("Hsu") ? args.slice(1) : args).map(Number).filter((n) => !Number.isNaN(n));

const CHROME =
  process.env.REMOTION_BROWSER ??
  "C:\\Users\\Admin（无密码）\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe";

const outDir = path.resolve("out/qa");
fs.mkdirSync(outDir, {recursive: true});

const serveUrl = await bundle({
  entryPoint: path.resolve("src/index.ts"),
  onProgress: () => {},
});

const browser = await openBrowser("chrome", {browserExecutable: CHROME});
const composition = await selectComposition({serveUrl, id: comp, puppeteerInstance: browser});

for (const frame of frames) {
  const output = path.join(outDir, `${comp}-${String(frame).padStart(4, "0")}.png`);
  await renderStill({
    composition,
    serveUrl,
    frame,
    output,
    puppeteerInstance: browser,
    overwrite: true,
  });
  console.log("still", frame, output);
}
await browser.close({silent: true});
