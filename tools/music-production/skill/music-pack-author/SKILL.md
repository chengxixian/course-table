---
name: music-pack-author
description: Create, adapt, review, and validate reusable Music Production customisation or extension packs. Use when defining a new music production profile, deciding whether a new pack is justified, writing pack contracts, adding pack-aware evals, or creating canonical showcase examples with full generation prompts.
---

# Music Pack Author

Create reusable extension packs for Music Production Skills without turning the catalogue into a collection of genre labels.

## Scope

Own:

- checking whether an existing pack already covers the requested production grammar;
- defining a new pack's format, use context, genre guidance and production language;
- defining optional performance/vocal and audience profiles;
- defining hard delivery requirements;
- defining integration with `music-compose`, `music-produce`, and `music-evaluate`;
- defining pack-aware evaluation;
- creating a self-contained Agent Skill pack;
- creating behavioural evals;
- creating at least one showcase example with a full generation prompt;
- preparing a catalogue entry.

Do not own music generation, provider execution, DAW functionality, or final music production.

## When a new pack is justified

Create a new pack only when the requested profile materially changes one or more of:

```text
composition grammar
arrangement grammar
draft strategy
production realisation
delivery artifacts
cross-project handoff
preservation rules
evaluation target
```

If the difference can be expressed cleanly as a project brief against an existing pack, adapt the existing pack instead.

Example:

```text
dark progressive techno
→ normally use melodic-techno-club-track with project-specific direction
```

not a new `dark-progressive-techno` pack.

## Authoring workflow

1. Read `references/pack-contract.md`.
2. Read `references/authoring-workflow.md`.
3. Compare the request against the existing catalogue supplied by the project or user.
4. Write a one-paragraph justification for why the production grammar is not already covered.
5. Define the pack dimensions and precedence behaviour.
6. Write the operational production profile.
7. Define how each core Music skill should consume relevant guidance.
8. Define pack-aware evaluation, including `preserve`, `do_not_penalise`, and `reject` behaviour where useful.
9. Create the smallest self-contained pack directory that is sufficient.
10. Add at least one showcase example using `references/showcase-examples.md`.
11. Ensure the showcase README contains the full copyable generation prompt.
12. Add normal, draft, refinement, final, and boundary evals.
13. Run `scripts/validate-pack.ts <pack-directory>` when Node.js 22+ is available.

## Pack precedence

Every pack must preserve:

```text
1. explicit user/project instructions
2. approved and locked music artifacts / decisions
3. selected extension pack
4. core Music Production Skills defaults
```

A pack must never silently reopen approved or locked work.

## Required pack content

Minimum useful pack:

```text
skills/<pack-name>/
├── SKILL.md
├── references/
│   └── production-profile.md
└── evals/
    └── evals.json
```

Create extra references/assets/scripts only when the pack genuinely needs them.

Every pack `SKILL.md` should make the following explicit:

```text
pack identity
intended use
format
use context
genre guidance
production language
performance/vocal profile where relevant
audience where relevant
delivery requirements
must-preserve traits
integration with music-compose
integration with music-produce
integration with music-evaluate
cross-project handoffs where relevant
external tool/provider requirements
```

## Showcase requirement

A new pack is incomplete without at least one realistic showcase example.

The example README must contain:

```text
# Example name
short production description
## Prompt
full generation prompt
## What this showcases
```

The prompt should exercise the pack's distinctive production behaviour rather than merely ask for a track in the named genre.

Do not fabricate generated results, model provenance, costs, evaluation findings, or benchmark scores before the example is actually run.

## Evals

Pack evals must prove:

- correct activation;
- correct application of hard and soft pack guidance;
- preservation of explicit and approved decisions;
- pack-aware evaluation;
- non-activation when the pack is irrelevant;
- correct boundary behaviour;
- no provider/API reimplementation.

## Do not

- create one skill per genre, instrument, mood, vocal adjective, or delivery variant;
- create a pack whose only definition is a living artist/producer/composer name;
- create a pack whose only difference is a prompt adjective;
- embed credentials or private/copyrighted assets;
- implement model routing or provider APIs;
- claim source-separated material is native production stems;
- add inheritance, mixins, composition engines, registries, or pack marketplaces before real use proves the need.

## References

Read only what is needed:

- `references/pack-contract.md`
- `references/authoring-workflow.md`
- `references/showcase-examples.md`
