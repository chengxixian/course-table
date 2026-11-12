/**
 * ask-gyro.mjs — one-shot delegation to the local Gyro-S model (http://127.0.0.1:8090).
 *
 * Feeds a prompt plus a list of source files, saves the answer to a file.
 * Slow (14-25 tok/s) but strong; intended for audit questions where the
 * mechanical part is "read N files, report findings" and the judgement is
 * done later by the cloud agent reading the saved answer.
 *
 *   node tools/gyro/ask-gyro.mjs --prompt-file q.txt --files a.dart b.dart --out answer.md
 *
 * The API key comes from STRATA_API_KEY, defaulting to the local launch key.
 */
import fs from "node:fs";
import path from "node:path";

const BASE = "http://127.0.0.1:8090";
const KEY = process.env.STRATA_API_KEY || "strata-local";
const AUTH = {Authorization: `Bearer ${KEY}`};

const argv = process.argv.slice(2);
const flagOf = (name, dflt) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && argv[i + 1] !== undefined ? argv[i + 1] : dflt;
};

const promptFile = flagOf("prompt-file", null);
const outFile = flagOf("out", "answer.md");
const filesIdx = argv.indexOf("--files");
const files = [];
if (filesIdx >= 0) {
  for (let i = filesIdx + 1; i < argv.length && !argv[i].startsWith("--"); i++) files.push(argv[i]);
}
if (!promptFile) {
  console.error("usage: node ask-gyro.mjs --prompt-file q.txt [--files f1 f2 ...] [--out a.md] [--max-tokens N]");
  process.exit(2);
}

const instructions = fs.readFileSync(promptFile, "utf8");
let context = "";
for (const f of files) {
  const abs = path.resolve(f);
  const src = fs.readFileSync(abs, "utf8");
  context += `\n===== FILE ${f} (${src.split("\n").length} lines) =====\n${src}\n`;
}
if (context.length > 480000) context = context.slice(0, 480000) + "\n[truncated]\n";

const maxTokens = Number(flagOf("max-tokens", "6000"));

const modelsRes = await fetch(`${BASE}/v1/models`, {headers: AUTH});
if (!modelsRes.ok) {
  console.error(`models endpoint HTTP ${modelsRes.status}: ${await modelsRes.text()}`);
  process.exit(1);
}
const models = await modelsRes.json();
const modelId = models.data?.[0]?.id;
if (!modelId) {
  console.error("no model served on 8090");
  process.exit(1);
}

const body = JSON.stringify({
  model: modelId,
  messages: [
    {role: "system", content: "你是资深 Flutter/Android 代码审计员。只依据给出的文件回答，用中文，输出紧凑的 Markdown 表格或列表；不要建议超出文件内容的重构；每条发现必须带 文件:行号。"},
    {role: "user", content: `${instructions}\n\n${context}`},
  ],
  temperature: 0.2,
  max_tokens: maxTokens,
});

const t0 = Date.now();
const res = await fetch(`${BASE}/v1/chat/completions`, {
  method: "POST",
  headers: {"Content-Type": "application/json", ...AUTH},
  body,
});
if (!res.ok) {
  console.error(`HTTP ${res.status}: ${await res.text()}`);
  process.exit(1);
}
const data = await res.json();
const msg = data.choices?.[0]?.message ?? {};
const text = (msg.content && msg.content.trim()) ? msg.content : (msg.reasoning_content ?? "(empty)");
fs.writeFileSync(outFile, text, "utf8");
const secs = ((Date.now() - t0) / 1000).toFixed(0);
console.log(JSON.stringify({out: outFile, chars: text.length, seconds: +secs, usage: data.usage}));
