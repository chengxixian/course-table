---
name: sound
description: Find and download sound effects from Freesound for videos, using download counts, ratings, descriptions, and licenses to select clips.
allowed-tools: Bash(python3 .claude/skills/sound/scripts/*)
---
Use Freesound for all sound-effect searches and downloads. You can't hear these clips, so lean on what people who did hear them left behind: download counts, ratings, and the uploader's description.

```
S=.skills/sound/scripts/sfx.py
python $S freesound "<English query>"     # ↓downloads ★rating(votes) license description
python $S freesound "<English query>" --license cc0
python $S get <dir> fs:<id>...            # parallel download of searched clips
```
`--urls` on a search adds preview links for the user to audition.

Reading the signals:
- Prefer the most-downloaded clip that fits the cue, and quote the numbers when proposing it. A high rating count beats a high average: ★4.4(380) is stronger evidence than ★4.9(6).
- The Freesound description is the closest thing to listening: "built-in mic" or "made with my mouth" means lo-fi; a named recorder (Zoom, Sound Devices) and a clear source ("cork from a wine bottle") mean you know what you'll get. Reject clips whose description shows a different source than the cue, however popular.
- Freesound licenses: CC0 is free; BY needs a credit (`get` prints it); avoid BY-NC for anything commercial (`--license cc0|by` filters).
- Popularity says nothing about fit: a widely downloaded "thud" can be a 3 s cinematic rumble. Check the duration, and measure with ffmpeg (tail length, where the energy sits) before trusting a top hit. Use `--urls` when the user wants to audition candidates.

- Freesound times out: `python .skills/sound/scripts/clash_freesound.py --fix`; if that fails, read references/local-setup.md.
- Freesound caps ~80 KB/s per connection: put all keys in one `get`.

## Local notes (read before the first run)

- **Python**: this machine has no system Python. Use the bundled runtime:
  `C:\Users\Admin（无密码）\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe`
- **TLS**: `https://freesound.org/` (the search pages) rejects CPython's OpenSSL
  client with `SSLEOFError: UNEXPECTED_EOF_WHILE_READING`, and Windows
  PowerShell's `Invoke-WebRequest` fails the same way. `curl.exe` gets a normal
  200. `scripts/sfx.py` therefore falls back to `curl.exe` when the urllib
  handshake dies; `cdn.freesound.org` (where the preview MP3s live) works with
  urllib and is unaffected. This is a local patch, see `PATCHES.md`.
- **Search is slow but works**: a 3-page search takes ~15–40 s per query.
- **Downloads are MP3 previews** (hq, ~128 kbps), not the uploader's original
  file. Good enough to judge and to mix at low level; not a mastering source.
- The upstream `SKILL.md` had a paid-upsell block (B 站充电 + 微信二维码) that
  this copy removed. The untouched original is `SKILL.upstream.md`. Nothing in
  this skill requires payment: the Freesound search/download scripts above are
  complete and free.
