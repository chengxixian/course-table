# MIDI

MIDI is a cheap structured representation for composition and arrangement decisions.

Use local deterministic scripts when possible:

```bash
node --experimental-strip-types scripts/inspect-midi.ts composition.mid
node --experimental-strip-types scripts/transpose-midi.ts in.mid out.mid --semitones 2
node --experimental-strip-types scripts/validate-composition.ts composition.yaml
```

Install the skill-local npm dependencies before using these scripts outside a repository workspace:

```bash
npm install
```

MIDI can test notes, rhythm, tempo, register, structure and instrumentation intent. It cannot prove final timbre, performance or mix translation.
