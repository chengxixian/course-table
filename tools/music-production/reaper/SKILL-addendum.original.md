# Music production skill (installed)

Upstream: https://github.com/sb-dev/music-production-skills
License: MIT
Installed subskills: `music-compose/`, `music-produce/`, `music-evaluate/`.

Use these for composition/arrangement/QC. The upstream skills are oriented to
structured/MIDI drafts and optional Replicate generation; this project does NOT
use Replicate. Local production is done in REAPER.

## REAPER

Installed at:

`C:\Program Files\REAPER (x64)\reaper.exe`

Rules for this promo:

- Compose in MIDI first (melody, counter-melody, bass, drums), then render in
  REAPER. Do not use the previous Node-only pad bed.
- 40.000 s, 120 BPM, 4/4, 48 kHz stereo.
- This revision must be **melody-led**: a memorable 4-bar motif that returns
  transposed/doubled, call-and-response with a counter line, and a clear hook.
- Drums must be stronger than v1: solid kick, backbeat/clap, syncopated hats,
  fills at section boundaries; keep 4 dB+ headroom and do not mask SFX.
- Structure: clock/typewriter intro → week-grid lift → detail/popup break →
  import groove → drag snap accent → widget cascade → palette morph/outro.
- Deliver `promo/audio/bgm-v2.wav`, `promo/audio/cues-v2.json`,
  `docs/promo/08-bgm-v2.md`, and ideally the `.rpp` project + MIDI files.
- Do not overwrite `bgm.wav` or the existing v1 cues; the video producer will
  A/B and remix only after Lead approval.
- If REAPER offline render cannot be automated, deliver the `.rpp` + MIDI and
  a clearly labeled fallback render, and tell Lead exactly which command/action
  is needed to render.
