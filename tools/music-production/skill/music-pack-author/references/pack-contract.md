# Pack Contract

A Music Production extension pack is an optional peer Agent Skill that provides a coherent production profile to `music-compose`, `music-produce`, and `music-evaluate`.

## Required semantics

Define:

```text
format
use_context
genre
production_language
performance_or_vocal_profile (optional)
audience (optional)
delivery_requirements
must_preserve
core_skill_integration
pack_aware_evaluation
```

The profile must be operational. "Warm indie" is not sufficient; specify the musical, arrangement, production, performance and evaluation behaviour it implies.

## Precedence

```text
explicit instructions
> approved/locked artifacts
> pack
> core defaults
```

## Hard versus soft guidance

Treat format/use-context/delivery requirements as hard only where the deliverable depends on them. Genre and style/production-language guidance are normally soft unless the pack declares a specific identity trait that must be preserved.

## Boundaries

A pack may require or recommend external provider/tool skills, but does not reimplement them. It may define handoff artifacts for Video, Advertising or game runtimes, but does not absorb those domains.
