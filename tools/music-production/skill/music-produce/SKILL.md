---
name: music-produce
description: Turn approved musical direction into produced audio using Replicate as the primary model provider. Use for demos, full music generation, production refinement, continuation, local section repair, vocals, final audio, technical finishing, delivery, and music production handoffs.
---

# Music Produce

Produce audio from approved musical direction while preserving approved decisions.

## Scope

Own demos, production realisation, Replicate model routing, model-native music input construction, local continuation/inpainting/refinement where supported, production provenance, deterministic audio processing, technical QC, delivery packaging, and mixes/masters/stems only where the execution path genuinely supports them.

Do not own composition changes unless the workflow explicitly reopens composition.


## Execution prerequisites

For Replicate-backed generation, require the official Replicate peer skills:

```text
find-models
compare-models
run-models
```

and `REPLICATE_API_TOKEN`.

If the peer skills are unavailable, report the missing execution dependency. Do not replace them with a custom Replicate client.

Deterministic local audio helpers require Node.js 22+, `ffmpeg`, and `ffprobe`.

## Optional customisation pack

This skill remains fully usable without a customisation pack.

When a selected peer music customisation pack is available, use this precedence:

```text
1. explicit user/project instructions
2. approved and locked music artifacts / decisions
3. selected customisation pack
4. music-produce defaults
```

Apply only relevant pack guidance to production realisation, instrumentation/timbre, performance/vocal direction, mix priorities, delivery variants, and use-context requirements.

The pack does not own provider execution. Replicate discovery, comparison, execution, provenance, and fallback behaviour remain governed by this skill and the official Replicate peer skills.

A pack must not reopen locked music or force unsupported outputs such as genuine stems when the production does not contain them.

## Inputs

Use available music brief, reference analysis, composition, arrangement, existing demo/audio, decision states, delivery requirements, budget, and optional pinned model. Do not require every artifact for simple fast-path tasks.

## Lifecycle and generation policy

Keep these independent:

```text
workflowState: draft | refine | final
generationPolicy: economy | balanced | quality
```

Do not equate lifecycle with model cost.

## Draft / demo

1. Produce only enough fidelity/duration to answer the current production question.
2. Prefer partial sections when they can validate the production direction.
3. Preserve composition and arrangement lineage.
4. Do not over-finish demos.

## Replicate routing

For every generative operation:

1. define the production requirement;
2. define hard capabilities;
3. honour a compatible pinned model if present;
4. otherwise use `find-models`;
5. use `compare-models`;
6. prefer compatible Replicate official models;
7. inspect the selected model's current schema;
8. construct model-native inputs;
9. use `run-models`;
10. store execution provenance.

Capability comes before cost. Do not maintain static pricing, model scores, or a custom Replicate client.

## Prompt / input construction

Express only relevant musical intent, potentially including purpose, tempo/meter, tonal character, instrumentation, structure, section behaviour, lyrics/vocal direction, groove/energy, production aesthetic, duration, reference material, preserved properties, and editable region/properties.

Follow the selected model's native schema rather than a universal request object.

## Refine

1. identify the defect;
2. identify the responsible production decision;
3. identify the smallest affected region/unit;
4. prefer local edit, continuation, inpainting, or reference-conditioned generation when supported;
5. if the current model lacks the capability, rediscover Replicate candidates;
6. use external secondary execution only when explicitly configured and genuinely necessary;
7. verify approved/locked decisions and surrounding material after the change.

Whole-track regeneration requires justification when a smaller repair is possible.

## Deterministic audio tools

Use local scripts and FFmpeg/ffprobe for inspection, trim/extract, concatenation, conversion, technical measurements, and delivery validation.

Do not claim these operations constitute professional creative mixing/mastering.

## Stems

Only label outputs as stems when they are genuine grouped production submixes. If source separation is used by an optional workflow, label the results explicitly as separated estimates.

## Final

1. preserve approved musical direction;
2. satisfy delivery requirements;
3. run technical QC;
4. request/run final music evaluation;
5. retain provenance.

## Do not

- create a custom Replicate SDK;
- build a generic multi-provider router;
- silently switch to an external provider;
- regenerate a whole track for a local defect without justification;
- claim true multitrack/stems when only stereo audio exists;
- use mastering to hide an upstream musical defect.

## References

Read as needed:

- `references/production-workflow.md`
- `references/replicate-routing.md`
- `references/prompting.md`
- `references/refinement.md`
- `references/delivery.md`
