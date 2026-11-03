import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runCommand } from "./lib/run-command.ts";

const args = process.argv.slice(2);
const outputIndex = args.indexOf("--output");
if (outputIndex < 1 || outputIndex === args.length - 1) {
  console.error("Usage: join-audio.ts <input1> <input2> [...] --output <output.wav>");
  process.exit(2);
}
const inputs = args.slice(0, outputIndex);
const output = args[outputIndex + 1];
if (!output || inputs.length < 2) {
  console.error("At least two inputs and an output are required");
  process.exit(2);
}
const dir = await mkdtemp(join(tmpdir(), "music-join-"));
try {
  const listPath = join(dir, "concat.txt");
  const escaped = inputs.map((p) => `file '${p.replaceAll("'", "'\\''")}'`).join("\n");
  await writeFile(listPath, escaped + "\n", "utf8");
  const result = await runCommand("ffmpeg", ["-nostdin", "-hide_banner", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0", "-i", listPath, "-c:a", "pcm_s24le", output]);
  if (result.code !== 0) { console.error(result.stderr.trim() || "ffmpeg failed"); process.exit(1); }
  console.log(JSON.stringify({ output, inputs }, null, 2));
} finally {
  await rm(dir, { recursive: true, force: true });
}
