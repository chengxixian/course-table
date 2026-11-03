# Technical QC

Use deterministic evidence for objective properties before semantic judgement.

Typical checks:

- file decodes;
- duration;
- sample rate;
- channel count/layout;
- clipping/peak evidence where configured;
- loudness measurements where a delivery target exists;
- required output files;
- declared stem semantics;
- edit-boundary integrity where measurable.

Do not mark a check PASS if FFmpeg/ffprobe or the required artifact is unavailable.
