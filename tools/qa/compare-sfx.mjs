/**
 * compare-sfx.mjs — side-by-side band/level profile of the two SFX sets.
 * Reads two JSON arrays produced by sfx-analyze.mjs and prints a delta table.
 *
 *   node compare-sfx.mjs old.json new.json
 */
import fs from "node:fs";

const [oldPath, newPath] = process.argv.slice(2);
const oldRows = JSON.parse(fs.readFileSync(oldPath, "utf8"));
const newRows = JSON.parse(fs.readFileSync(newPath, "utf8"));

const byName = (rows) => Object.fromEntries(rows.map((r) => [r.file, r]));
const O = byName(oldRows);
const N = byName(newRows);

const names = Object.keys(O).sort();
const pad = (s, n) => String(s).padEnd(n);
console.log(
  pad("cue", 17) + pad("dur old→new", 16) + pad("rms Δ", 9) + pad("body Δ", 9) +
  pad("low Δ", 9) + pad("pres Δ", 9) + pad("air Δ", 9) + "f0 old → new",
);
console.log("-".repeat(110));
for (const n of names) {
  const o = O[n], x = N[n];
  if (!x) { console.log(`${pad(n, 17)}(not replaced)`); continue; }
  const d = (a, b) => (b - a >= 0 ? "+" : "") + (b - a).toFixed(1);
  console.log(
    pad(n, 17) +
    pad(`${o.dur}s → ${x.dur}s`, 16) +
    pad(d(o.rms, x.rms), 9) +
    pad(d(o.body, x.body), 9) +
    pad(d(o.low, x.low), 9) +
    pad(d(o.presence, x.presence), 9) +
    pad(d(o.air, x.air), 9) +
    `${o.f0} → ${x.f0}`,
  );
}
