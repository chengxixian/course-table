# Changelog

All notable project changes should be recorded here.

## Unreleased - Stage 12

### Added — Music customisation packs specification

- Added `docs/05-customisation-packs-spec.md` as a supplemental normative specification.
- Defined optional peer customisation packs across format, use context, genre, production language, performance/vocal direction and delivery.
- Selected five initial packs: singer-songwriter single, melodic-techno club track, cinematic hybrid score, adaptive game score and premium brand music.
- Added pack-aware precedence, evaluation, handoff and anti-over-engineering rules.
- Integrated optional pack consumption into all three core Music skills and added core pack-integration eval cases.

### Added — Extension pack catalogue and pack authoring

- Added `docs/06-extension-pack-catalogue.md` with five initial packs and canonical showcase generation prompts.
- Added five extension-pack showcase example READMEs under `examples/packs/`.
- Added optional `music-pack-author` Agent Skill for creating, adapting and validating new extension packs and their showcase prompts.

### Added — Capability benchmark expansion

- Reworked `docs/04-testing-and-benchmark-spec.md` into a capability-assurance benchmark for agent behaviour, produced-artifact quality, evaluation/repair quality, extension-pack fidelity, technical delivery, cross-domain handoffs, and pack authoring, while retaining the operational runbook (testing layers, prerequisites, per-layer limits, standing rules and fixture generation).
- Added `tests/benchmark/taxonomy.json`, `rubrics.json`, `example-matrix.json`, `profiles.json`, and an explicit `UNMEASURED` baseline.
- Added deterministic benchmark checks for taxonomy integrity, evidence identity, extension-pack coverage, showcase prompts, pack-author validation, native-stem semantics, and the five-level/15-example genre matrix.
- Added benchmark reporting and prompt-inspection commands without embedding a provider API client.

### Added — Internal command decomposition specification

- Specified bounded, skill-local production commands in `docs/01`, `docs/02`, `docs/03` and `docs/04`.
- Commands are an execution view over the existing workflow: they are not installable skills, not first-class artifacts, and create no new lifecycle states.
- The `commands/` directories are specified but not yet implemented; `docs/03` records this as a gap to close before Stage 13.

### Changed

- Replaced four generic examples with 15 production examples: three genre-distinct examples across each of the five canonical consumer levels.
- Added full copyable prompts to every example README and aligned the root README with the canonical five-level progression.
- Moved the artifact specimens from the retired examples into the owning skills as runnable assets: `skills/music-compose/assets/selection.example.yaml`, `skills/music-evaluate/assets/preservation.example.json` and `skills/music-evaluate/assets/evaluation-evidence.example.json`.
- Configured Agent Skills CLI installation for project-local, global, selective, Claude Code, and Codex use.
- Documented official Replicate peer-skill installation for generative production.
- Documented runtime requirements per skill and current update commands.
- Added `docs/installation.md` as the canonical detailed installation guide.
- Configured the Stage 13 clean-project smoke command without claiming it has passed.

## [Unreleased]

### Added

- Stage 11 open-source repository scaffold.
- `music-compose`, `music-produce`, and `music-evaluate` skill packages.
- Strict TypeScript repository validation and deterministic tests.
- Progressive production examples and end-to-end eval fixtures.
- Supplemental testing and benchmark runbook.
