# Third-party notices

## Classy

- Project: Classy
- Author: IMSX3D
- Source: https://github.com/IMSX3D/Classy
- License: GNU General Public License v3.0
- Used material: `app/src/main/assets/schools.json` school preset data (349 schools).

The school list was transformed into `schools/index.json` for this project. Classy's Kotlin parser layer under `com.imsx3d.classy.data.jw` (38 parser/helper files) is compiled into this Android app and exposed through `ClassyParserBridge`/MethodChannel. Dart also contains a minimal `zf_new` fallback in `lib/classy_parser.dart`. No Compose UI code was copied. Unknown school types fall back to this app's generic web/AI import. All copied code is GPL-3.0; see upstream for original sources.

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
