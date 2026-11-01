# Classy parser coverage

- Upstream: https://github.com/IMSX3D/Classy
- Commit: `8a2499dfa258bb5daba37d6d7f0bbd74b6ae73b9`
- License: GPL-3.0
- Integration: Kotlin parser classes compiled into the Android app; Flutter calls `ClassyParserBridge` via `com.hsu.hsu_schedule/classy_parser`.
- Coverage: **42 parser classes / 41 Kotlin files**, all registry factory references present (checked by class-name diff).

## Parser classes

- `JwBjtuParser`
- `JwBnuzParser`
- `JwBoyaPpParser`
- `JwCfNewParser`
- `JwChaoxingLegacyParser`
- `JwChaoxingParser`
- `JwChengFangParser`
- `JwClassicEamsParser`
- `JwCquParser`
- `JwCumtbParser`
- `JwEams5Parser`
- `JwGxzyxysyParser`
- `JwHnustParser`
- `JwJzParser`
- `JwKingoParser`
- `JwKustParser`
- `JwNeuParser`
- `JwNewUrpParser`
- `JwNewZfParser`
- `JwNuitParser`
- `JwOldQzParser`
- `JwOldZfParser`
- `JwPekingParser`
- `JwQzAppParser`
- `JwQzBrParser`
- `JwQzCrazyParser`
- `JwQzIeasParser`
- `JwQzParser`
- `JwQzWithNodeParser`
- `JwScuParser`
- `JwSeuParser`
- `JwShuweiParser`
- `JwSouthSoftParser`
- `JwSudaParser`
- `JwUcasParser`
- `JwUrpParser`
- `JwUstcParser`
- `JwWhutParser`
- `JwWiseduParser`
- `JwXjuParser`
- `JwYethanParser`
- `JwZjuParser`

## Protocol type strings

- `bjtu`
- `bnuz`
- `boya_pp`
- `cf`
- `cf_new`
- `chaoxing`
- `classic_eams`
- `cqu`
- `cumtb`
- `eams5`
- `gxzyxysy`
- `help`
- `hniu`
- `hnust`
- `jz`
- `kingo_new`
- `kust`
- `login`
- `login_chaoxing`
- `maintain`
- `neu`
- `nuit`
- `pku`
- `qz`
- `qz_app`
- `qz_br`
- `qz_crazy`
- `qz_ieas`
- `qz_old`
- `qz_with_node`
- `scu`
- `seu`
- `shuwei_json`
- `south_soft`
- `suda_post`
- `ucas`
- `urp`
- `urp_new`
- `ustc`
- `whut`
- `wisedu`
- `xju_post`
- `yethan`
- `zf`
- `zf_1`
- `zf_new`
- `zju`

## Boundary

These are HTML parser implementations. Some school types also require a WebView fetch/JS step (for example dynamic week JSON); those fetch adapters are not copied, so an empty result falls back to the generic HTML/AI path. No Compose UI code was copied.
