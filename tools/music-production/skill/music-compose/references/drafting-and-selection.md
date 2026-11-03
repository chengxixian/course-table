# Drafting and Selection

A draft is a representation created to answer an unresolved production question. It is not simply low-quality final audio.

Use the smallest useful unit:

```text
hook question        → hook fragment
harmony question     → chords / MIDI
chorus energy        → pre-chorus + chorus
song pacing          → full structural demo
```

Generate alternatives only where there is genuine creative uncertainty. Alternatives should differ materially.

## Selection

Support both whole-artifact and component-level selection.

```yaml
selectionSources:
  melody: hook-draft-b
  harmony: harmony-draft-c
  groove: groove-draft-a
```

After selection, explicitly decide whether each choice is merely selected, approved, or locked.

`assets/selection.example.yaml` shows the resulting envelope: `decisionState: selected`, every
candidate draft retained in `parents`, and `selectionSources` recording which component came from
which draft.
