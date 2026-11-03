import { runCommand } from "./lib/run-command.ts";

function fail(message: string): never { console.error(message); process.exit(2); }
const [input, output, startRaw, durationRaw] = process.argv.slice(2);
if (!input || !output || startRaw === undefined || durationRaw === undefined) {
  fail("Usage: extract-region.ts <input> <output> <start-seconds> <duration-seconds>");
}
const start = Number(startRaw);
const duration = Number(durationRaw);
if (!Number.isFinite(start) || start < 0 || !Number.isFinite(duration) || duration <= 0) fail("start/duration must be valid non-negative numbers");
const result = await runCommand("ffmpeg", ["-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-ss", String(start), "-i", input, "-t", String(duration), "-c:a", "pcm_s24le", output]);
if (result.code !== 0) { console.error(result.stderr.trim() || "ffmpeg failed"); process.exit(1); }
console.log(JSON.stringify({ input, output, start, duration }, null, 2));
