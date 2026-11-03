import { access } from "node:fs/promises";
import { runCommand } from "./lib/run-command.ts";

const input = process.argv[2];
if (!input) {
  console.error("Usage: inspect-audio.ts <audio-file>");
  process.exit(2);
}

try { await access(input); } catch { console.error(`Audio file not found: ${input}`); process.exit(1); }
const result = await runCommand("ffprobe", ["-v", "error", "-show_entries", "format=duration,format_name:stream=index,codec_name,codec_type,sample_rate,channels,channel_layout", "-of", "json", input]);
if (result.code !== 0) {
  console.error(result.stderr.trim() || "ffprobe failed");
  process.exit(1);
}
console.log(result.stdout.trim());
