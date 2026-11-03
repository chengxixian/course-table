# Replicate Routing

Replicate is the primary model execution provider.

Use the official Agent Skills:

```text
find-models
compare-models
run-models
```

Do not build a custom Replicate client or model database.

Routing order:

```text
hard capability requirements
→ compatible Replicate official models preferred
→ compatible other Replicate models
→ optional external secondary execution only for a proven gap
```

Capabilities may include vocals, lyrics, reference audio, continuation, inpainting, duration, instrumental-only generation, section controls or precise output constraints.

A pinned model must be honoured when compatible. If incompatible, report the conflict rather than silently substituting another model.
