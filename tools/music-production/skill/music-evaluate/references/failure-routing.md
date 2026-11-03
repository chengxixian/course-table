# Failure Routing

A useful evaluation says where the correction belongs.

Possible owning stages:

```text
brief / intent
composition
arrangement
performance
production
editing / refinement
mix
mastering / technical finishing
delivery
model / execution
```

Examples:

```text
weak chorus lift       → composition or arrangement, based on evidence
pronunciation defect   → performance/local production region
clipping               → production/technical finishing
wrong file format      → delivery
provider timeout       → model/execution
```

Do not route every failure to prompting, model choice or increased generation cost.

## Recording a routed finding

Every finding carries the defective `region`, a `severity` of `info`/`warn`/`fail`, the
`owningStage` that must perform the correction, and a `recommendedCorrection` scoped to the smallest
affected unit. `assets/evaluation-evidence.example.json` is a complete evidence envelope in this
shape. Turn it into a report with:

```bash
node --experimental-strip-types scripts/generate-report.ts assets/evaluation-evidence.example.json
```

A finding without an `owningStage` is rejected: detecting a defect without naming the stage that
owns it is not a routed evaluation.
