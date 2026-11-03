# Preservation

Preservation is a separate success criterion from whether the requested change worked.

For refinement, compare the requested change with decision states and lineage.

Example:

```text
requested: heavier drums
approved/locked: melody, lyrics, structure
```

A result that improves drums but changes the approved melody fails preservation.

`assets/preservation.example.json` is a sample `production_refinement` envelope in this shape. Check
it with:

```bash
node --experimental-strip-types scripts/validate-preservation.ts assets/preservation.example.json
```

The validator rejects a `requestedChanges` entry that touches a locked decision without a matching
`reopenedDecisions` entry, and rejects a decision listed as both locked and open.

Structural metadata checks can prove that constraints were carried forward; they cannot prove audio-semantic preservation by themselves. Use semantic/audio evaluation when that distinction matters.
