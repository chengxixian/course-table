# Third-party notices

## Classy

- Project: Classy
- Author: IMSX3D
- Source: https://github.com/IMSX3D/Classy
- Upstream commit: `8a2499dfa258bb5daba37d6d7f0bbd74b6ae73b9`
- License: GNU General Public License v3.0
- Copyright: IMSX3D and contributors
- Used material: `app/src/main/assets/schools.json` school preset data — 348 of the 350 entries in `schools/index.json` (the other two are 黄山学院's native flow and one community submission).
- Copied code scope: 41 Kotlin files / 42 parser classes under `android/app/src/main/java/com/imsx3d/classy/data/jw/` (per-class list: [CLASSY_PARSERS.md](CLASSY_PARSERS.md)), the bridge `android/app/src/main/kotlin/com/hsu/hsu_schedule/ClassyParserBridge.kt`, and the Dart `zf_new` fallback in `lib/classy_parser.dart` (Flutter-side bridge: `lib/classy_bridge_service.dart`).
- Modifications: package/application integration, a Flutter MethodChannel bridge, conversion from Classy `JwCourse` records to this app's timetable HTML, removal of unused Compose/ViewModel/database code, and consolidation of the duplicated even/odd-week endpoint fix into one shared helper (`JwParity.kt`, used by the ZJU/USTC/SEU/NEU/EAMS5 parsers).

The school list was transformed into `schools/index.json` for this project. Classy's Kotlin parser layer under `com.imsx3d.classy.data.jw` is compiled into this Android app and exposed through `ClassyParserBridge`/MethodChannel. Dart also contains a minimal `zf_new` fallback in `lib/classy_parser.dart`. No Compose UI, ViewModel or Room/database code was copied: the copied files import only Jsoup, `kotlinx.serialization` and `org.json` (zero `androidx.compose`/`androidx.lifecycle.viewmodel`/`androidx.room` imports). Unknown school types fall back to this app's generic web/AI import. Each copied Kotlin/Dart file carries an attribution header naming upstream commit `8a2499d`; the root [NOTICE](../NOTICE) records the upstream commit, copyright and modifications.

Several parser files also keep in-file provenance notes for upstreams that Classy itself derives from — notably [`dIT8Zv/WakeupSchedule_BUPT`](https://github.com/dIT8Zv/WakeupSchedule_BUPT) (Apache-2.0), plus `wakeup` (Apache-2.0) and paper/JS references in individual KDoc blocks. Those notices are preserved verbatim; Apache-2.0 is one-way compatible with GPL-3.0, so the combined work is distributed here under GPL-3.0 without removing the Apache-2.0 attribution.

Classy is licensed under GPL-3.0; this project is also GPL-3.0. See the upstream repository for the original data and license.

## Fonts

### Fandol fonts — FangSong body typeface

- Project: Fandol fonts (Song / Hei / Kai / Fang)
- Authors: Fandol team — Clerk Ma, Jie Su
- Source: https://ctan.org/pkg/fandol (`fandol.zip`, member `fandol/FandolFang-Regular.otf`)
- Version: 1.300
- License: GNU GPL v3.0 **with font exception** (upstream README: “These fonts's licensing is GPL + GPL font exception”)
- License text: [`assets/fonts_ofl/Fandol-COPYING.txt`](../assets/fonts_ofl/Fandol-COPYING.txt) — GPL-3.0 plus the font-embedding exception appended at the end
- Bundled as: `assets/fonts_ofl/FandolFang-Regular.otf`, `android/app/src/main/assets/FandolFang-Regular.otf`
- Flutter family name: `FangSongCN` (kept unchanged; the file is FandolFang)
- Integrity: SHA-256 `D838AD32CE2244D8144F408C37FE71065ABA6FBBC80759A4D2AA2033948D5BC9`, identical to the member inside CTAN `fandol.zip` (verified 2026-11-01, unmodified upstream binary)

### Liberation Fonts — Liberation Serif (Latin serif)

- Project: Liberation Fonts 2.1.5
- Copyright: digitized data © 2010 Google Corporation (based on Tinos, designed by Steve Matteson); © 2012 Red Hat, Inc.
- Source: https://github.com/liberationfonts/liberation-fonts
- Distribution used: Debian package `fonts-liberation` 2.1.5-3 — https://deb.debian.org/debian/pool/main/f/fonts-liberation/fonts-liberation_2.1.5-3_all.deb (SHA-256 `3D5C47480067B9615F6BF9B0EDA6EEFCAB9D837AF609827015445E8E759B5B8C`). The upstream GitHub releases publish `.sfd` sources only (they need FontForge to build), so the unmodified packaged binary was used.
- License: SIL Open Font License 1.1, with reserved font names *Liberation*, *Arimo*, *Tinos*, *Cousine*; redistributed unmodified.
- License text: [`assets/fonts_ofl/LiberationSerif-OFL.txt`](../assets/fonts_ofl/LiberationSerif-OFL.txt)
- Bundled as: `assets/fonts_ofl/LiberationSerif-Regular.ttf`, `android/app/src/main/assets/LiberationSerif-Regular.ttf`
- Flutter family name: `TimesNewRoman` (kept unchanged; the file is Liberation Serif)
- Why: metric-compatible with Times New Roman (same 2048 upem, same ascender/descender/line gap, identical advance widths for the sampled Latin characters), so the existing layout contract holds.
- Integrity: SHA-256 `9CAEF765D2E891C10DD73658894F01E660FE0C1C83E0BDA7D6EDF561D8F623D4`

### Removed proprietary fonts

Until 2026-11-01 the app bundled `assets/FangSongCN.ttf` (Beijing ZhongYi “FangSong”; name table: “Microsoft supplied font … Any other use is prohibited”), `assets/TimesNewRoman.ttf` and `android/app/src/main/assets/TimesNewRoman.ttf` (Monotype Times New Roman, same Microsoft-supplied terms), and `android/app/src/main/assets/FangSongGB.ttf`. All four files were removed from the working tree; no build reference remains.

The intermediate files used by the old `tool/merge_fangsong*.py` scripts — `assets/_fangsong_cjk.ttf` (a byte-identical copy of the removed FangSongCN.ttf) and `assets/_times_latin.ttf` (a 377-glyph Times New Roman subset) — were removed as well. No Microsoft/Monotype font data remains in the repository or in the build inputs.
