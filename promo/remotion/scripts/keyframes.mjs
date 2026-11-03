/**
 * Renders the 12 key frames used by the contact sheet into public/qa/kNN.png
 * and copies them to docs/promo/keyframes/ for delivery.
 *   node scripts/keyframes.mjs
 */
import {bundle} from "@remotion/bundler";
import {renderStill, selectComposition, openBrowser} from "@remotion/renderer";
import path from "node:path";
import fs from "node:fs";

const CHROME =
  process.env.REMOTION_BROWSER ??
  "C:\\Users\\Admin（无密码）\\AppData\\Local\\Google\\Chrome\\Application\\chrome.exe";

// 60fps delivery: authored frame × 2 keeps the same timestamps (4.0s, 10.0s, …)
const FRAMES = [
  ["k01", 240],
  ["k02", 600],
  ["k03", 720],
  ["k04", 1040],
  ["k05", 1180],
  ["k06", 1400],
  ["k07", 1560],
  ["k08", 1720],
  ["k09", 2000],
  ["k10", 2210],
  ["k11", 2280],
  ["k12", 2370],
];

const pubQa = path.resolve("public/qa");
const outQa = path.resolve("out/qa");
fs.mkdirSync(pubQa, {recursive: true});
fs.mkdirSync(outQa, {recursive: true});

const serveUrl = await bundle({entryPoint: path.resolve("src/index.ts"), onProgress: () => {}});
const browser = await openBrowser("chrome", {browserExecutable: CHROME});
const composition = await selectComposition({serveUrl, id: "HsuPromoVertical", puppeteerInstance: browser});

for (const [name, frame] of FRAMES) {
  const out = path.join(pubQa, `${name}.png`);
  await renderStill({composition, serveUrl, frame, output: out, puppeteerInstance: browser, overwrite: true});
  fs.copyFileSync(out, path.join(outQa, `HsuPromoVertical-${String(frame).padStart(4, "0")}.png`));
  console.log("keyframe", name, frame);
}
await browser.close({silent: true});
