import { readFile } from "node:fs/promises";

interface Finding { severity?: unknown; owningStage?: unknown; message?: unknown; recommendedCorrection?: unknown; }
interface Evidence { artifact?: unknown; workflowState?: unknown; checksNotRun?: unknown; findings?: unknown; preservation?: unknown; }

const input = process.argv[2];
if (!input) { console.error("Usage: generate-report.ts <evidence.json>"); process.exit(2); }
let evidence: Evidence;
try { evidence = JSON.parse(await readFile(input, "utf8")) as Evidence; }
catch (error) { console.error(`Invalid evidence JSON: ${error instanceof Error ? error.message : String(error)}`); process.exit(1); }
const findings = Array.isArray(evidence.findings) ? evidence.findings as Finding[] : [];
const allowedSeverity = new Set(["info", "warn", "fail"]);
for (const finding of findings) {
  if (!allowedSeverity.has(String(finding.severity))) { console.error("Finding severity must be info/warn/fail"); process.exit(1); }
  if (typeof finding.message !== "string" || typeof finding.owningStage !== "string") { console.error("Each finding needs message and owningStage"); process.exit(1); }
}
const checksNotRun = Array.isArray(evidence.checksNotRun) ? evidence.checksNotRun : [];
const recommendation = findings.some((f) => f.severity === "fail") ? "fail" : findings.some((f) => f.severity === "warn") || checksNotRun.length > 0 ? "warn" : "pass";
console.log(JSON.stringify({
  type: "evaluation_report",
  artifact: evidence.artifact ?? null,
  workflowState: evidence.workflowState ?? null,
  findings,
  preservation: evidence.preservation ?? null,
  checksNotRun,
  recommendation,
}, null, 2));
