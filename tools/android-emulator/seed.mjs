/**
 * seed.mjs — turn demo-schedule.json into the SharedPreferences XML the app reads
 * on first launch, so the week grid has courses to drag without going through
 * the HSU portal.
 *
 * The app stores its parsed portal scrape under the `raw_scrape` key as a
 * RawScrape JSON whose `rawSchedule.kbList` mirrors the portal's field names
 * (kcmc / xqj / jc / zcd / cdmc / xm ...). This script writes that shape into
 * `flutter.raw_scrape` in `shared_prefs/FlutterSharedPreferences.xml`, which is
 * the file the legacy SharedPreferences API on Android uses.
 *
 *   node tools/android-emulator/seed.mjs [--in demo-schedule.json] [--out prefs.xml]
 */
import fs from "node:fs";
import path from "node:path";
import {fileURLToPath} from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const argOf = (name, dflt) => {
  const i = process.argv.indexOf(`--${name}`);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : dflt;
};

const input = argOf("in", path.join(here, "demo-schedule.json"));
const output = argOf("out", path.join(here, "prefs.xml"));

const demo = JSON.parse(fs.readFileSync(input, "utf8"));

const raw = {
  rawSchedule: {
    xsxx: {XM: "测试同学", XH: "20260000", BJMC: "软件工程 2026-1 班"},
    kbList: demo.courses.map((c) => ({
      kcmc: c.name,
      xqj: String(c.day),
      jc: c.periods,
      zcd: c.weeks,
      cdmc: c.room,
      xm: c.teacher,
      kch: c.code,
      xf: c.credits,
      jxbmc: "01",
    })),
  },
  rawPeriods: [],
  semesterText: demo.semesterText ?? "",
  portalInfo: null,
  scrapedAt: new Date().toISOString(),
};

const json = JSON.stringify(raw);
const escaped = json.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

const xml = [
  "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>",
  "<map>",
  `    <string name="flutter.raw_scrape">${escaped}</string>`,
  '    <string name="flutter.source_mode">native</string>',
  "</map>",
  "",
].join("\n");

fs.writeFileSync(output, xml, "utf8");
console.log(JSON.stringify({input, output, courses: demo.courses.length, bytes: xml.length}, null, 1));
