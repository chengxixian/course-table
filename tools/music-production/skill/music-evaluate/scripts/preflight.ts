import { runCommand } from "./lib/run-command.ts";

async function check(command: string): Promise<boolean> {
  try { return (await runCommand(command, ["-version"])).code === 0; } catch { return false; }
}
const ffmpeg = await check("ffmpeg");
const ffprobe = await check("ffprobe");
const token = Boolean(process.env.REPLICATE_API_TOKEN);
const reviewer = Boolean(process.env.MUSIC_BENCHMARK_REVIEWER);
console.log(`node: available [required]`);
console.log(`ffmpeg: ${ffmpeg ? "available" : "MISSING"} [required]`);
console.log(`ffprobe: ${ffprobe ? "available" : "MISSING"} [required]`);
console.log(`replicate token: ${token ? "available" : "MISSING"} [optional semantic benchmark]`);
console.log(`semantic reviewer: ${reviewer ? "available" : "MISSING"} [optional semantic benchmark]`);
console.log(`semantic collection: ${token && reviewer ? "AVAILABLE" : "NOT AVAILABLE"}`);
if (!ffmpeg || !ffprobe) process.exit(1);
