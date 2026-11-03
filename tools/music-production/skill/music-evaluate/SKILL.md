---
name: music-evaluate
description: Evaluate music-production artifacts by lifecycle stage, compare drafts, verify refinements, check preservation of approved decisions, run technical audio QC, identify the responsible production stage, and recommend the smallest useful correction.
---

# Music Evaluate

Evaluate what the current artifact is supposed to prove.

## Scope

Own draft comparison, intent evaluation, composition evaluation, arrangement evaluation, performance/production evaluation where evidence supports it, refinement verification, approved/locked-decision preservation checks, technical audio QC, delivery checks, failure routing, and persistent evaluation reports.

Do not invent observations unavailable from the supplied artifacts.


## Execution prerequisites

Creative evaluation can operate from supplied artifacts and host reasoning without a separate model-provider credential.

Technical audio QC helpers require Node.js 22+, `ffmpeg`, and `ffprobe`.

## Optional customisation pack

This skill remains fully usable without a customisation pack.

When a selected peer music customisation pack is available, evaluate with this precedence:

```text
1. explicit user/project requirements
2. approved and locked artifact decisions
3. selected customisation-pack criteria
4. music-evaluate defaults
```

Use pack `preserve`, `do_not_penalise`, and `reject` guidance only where relevant to the artifact being evaluated. Intentional pack traits may change the quality target, but they never justify ignoring technical failures, preservation regressions, broken delivery requirements, or unrelated musical defects.

Do not infer a pack when none was selected.

## Determine artifact and lifecycle

Identify artifact type, workflow state, brief/criteria, parent artifact, requested refinement, decision states, and available evidence. Only apply criteria that the artifact can support.

## Draft evaluation

Check whether the draft answers the intended question, differs materially from alternatives, violates the brief, contains catastrophic musical/technical defects, and is useful to continue.

Do not judge a MIDI composition draft as though it were a final master.

## Refinement evaluation

Check in this order:

1. did the requested change succeed?;
2. were approved and locked decisions preserved?;
3. did the changed region introduce boundary/regression problems?;
4. do prior approvals still hold?

## Final evaluation

Run applicable dimensions: intent, composition, arrangement, performance, production, preservation, technical QC, and delivery.

## Failure routing

For every material finding, identify the most likely owning stage:

- brief / intent;
- composition;
- arrangement;
- performance;
- production;
- editing/refinement;
- mix;
- mastering/technical finishing;
- delivery;
- model/execution.

Then recommend the smallest correction. Do not automatically recommend a more expensive model.

## Open-ended first

For semantic review, inspect the artifact openly before walking a closed checklist. Use the checklist to organise and verify findings rather than assuming it will discover every defect.

## Technical QC

Use deterministic scripts/FFmpeg for objective properties before semantic judgement.

Never claim a technical property was checked if the required dependency or artifact is unavailable.

## Reporting

Produce an `evaluation_report` containing artifact, lifecycle stage, evidence used, findings, severity, owning stage, preservation result, recommended correction, pass/warn/fail recommendation, and checks not run with reasons.

Avoid unsupported universal quality scores.

## Do not

- invent audio observations from text-only inputs;
- declare PASS when a required check did not run;
- treat source-separated audio as native stems;
- route every defect to prompting/model choice;
- silently approve artifacts on behalf of a human when human approval is required.

## References

Read as needed:

- `references/evaluation-lifecycle.md`
- `references/composition-rubric.md`
- `references/arrangement-rubric.md`
- `references/production-rubric.md`
- `references/preservation.md`
- `references/technical-qc.md`
- `references/failure-routing.md`
