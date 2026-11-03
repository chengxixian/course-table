#!/usr/bin/env python3
"""Search & download SFX from Freesound using the Python standard library.

Uses the shell's http(s)_proxy settings.

  sfx.py freesound "<query>" [--license cc0|by|any] [--sort relevance|downloads|rating|short] [-n N] [-p PAGE] [--pages K]
                                       relevance (default) is re-ranked by downloads across K pages
  sfx.py get <out_dir> <key>...        keys: fs:<id>
"""
import argparse, html, json, re, shutil, ssl, subprocess, sys, time, urllib.parse, urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

UA = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) sfx-sources"}
CACHE = Path.home() / ".cache" / "sfx-sources"
INDEX = CACHE / "index.json"  # search results, so `get` knows title + download url
FS_LICENSE = {"cc0": '"Creative Commons 0"', "by": '("Attribution" OR "Creative Commons 0")', "any": None}
FS_LIC_SHORT = {"Creative Commons 0": "CC0", "Attribution": "BY", "Attribution NonCommercial": "BY-NC", "Sampling+": "Sampling+"}
FS_SORT = {"downloads": "Downloads (most first)", "rating": "Rating (highest first)",
           "relevance": "Automatic by relevance", "short": "Duration (shortest first)"}


def fetch_curl(url, timeout):
    """Fallback transport for hosts whose TLS handshake Python's ssl module can't complete.

    On this machine https://freesound.org/ closes the connection during the
    handshake for CPython's OpenSSL client (ssl.SSLEOFError / UNEXPECTED_EOF),
    and Windows PowerShell's Invoke-WebRequest fails the same way, while
    curl.exe (Schannel) gets a normal 200. cdn.freesound.org — where the preview
    MP3s actually live — works fine with urllib, so only the search page needs
    this path.
    """
    exe = shutil.which("curl.exe") or shutil.which("curl")
    if not exe:
        raise OSError("urllib TLS failed and curl is not available")
    p = subprocess.run(
        [exe, "-sS", "--max-time", str(int(timeout)), "-A", UA["User-Agent"], url],
        capture_output=True,
    )
    if p.returncode != 0:
        raise OSError(f"curl exit {p.returncode}: {p.stderr.decode('utf-8', 'replace')[:200]}")
    if not p.stdout:
        raise OSError("curl returned an empty body")
    return p.stdout


def fetch(url, timeout=60, tries=3):
    last = None
    for n in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=timeout) as r:
                return r.read()
        except Exception as e:
            last = e
            if isinstance(e, ssl.SSLError) or "SSL" in repr(e):
                break  # retrying won't fix a handshake failure; go straight to curl
            if n < tries - 1:
                time.sleep(1 + n)
    try:
        return fetch_curl(url, timeout)
    except Exception as ce:
        raise last if isinstance(last, OSError) else OSError(f"{last!r} / curl: {ce!r}")


def load_index():
    try:
        return json.loads(INDEX.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def save_index(rows):
    CACHE.mkdir(parents=True, exist_ok=True)
    idx = load_index()
    idx.update({r["key"]: r for r in rows})
    # Explicit UTF-8: on a GBK/CP936 Windows locale the default codec raises
    # UnicodeEncodeError as soon as a clip title contains e.g. "ñ".
    INDEX.write_text(json.dumps(idx, ensure_ascii=False), encoding="utf-8")


def show(rows, a, lic=False, hint=""):
    save_index(rows)
    for r in rows:
        print("\t".join([r["key"], r["title"], r["dur"]] + ([r["stats"]] if "stats" in r else []) + [r["license"]] * lic + ([r["desc"]] if r.get("desc") else []) + [r["preview"]] * a.urls))
    if not rows:
        print("(none)" + hint)


def freesound(a):
    # Pull several relevance pages and rank them by downloads, since sorting by downloads
    # server-side lets globally popular but off-topic sounds (gunshots, ambiences) win on a loose tag match.
    q = {"q": a.query, "s": FS_SORT[a.sort]}
    if FS_LICENSE[a.license]:
        q["f"] = "license:" + FS_LICENSE[a.license]
    pages = range(a.page, a.page + a.pages)
    with ThreadPoolExecutor(len(pages)) as ex:
        htmls = list(ex.map(lambda n: fetch("https://freesound.org/search/?" + urllib.parse.urlencode({**q, "page": n})).decode(), pages))
    rows = []
    for blk in (b for h in htmls for b in h.split('class="bw-search__result"')[1:]):
        g = lambda k: (re.search(rf'data-{k}="([^"]*)"', blk) or [None, ""])[1]
        lic = re.search(r'title="License: ([^"]+)"', blk)
        rt = re.search(r'aria-label="Average rating of ([\d.]+)"', blk)
        rn = re.search(r'bw-rating__count[^>]*>\((\d+)\)', blk)
        desc = re.search(r'<div class="max-h-60px[^"]*"\s*>\s*(.*?)\s*</div>', blk, re.S)
        sid, user, dl = g("sound-id"), g("username"), int(g("num-downloads") or 0)
        rows.append({"key": f"fs:{sid}", "title": html.unescape(g("title")), "dur": f"{float(g('duration') or 0):.1f}s",
                     "author": user, "license": FS_LIC_SHORT.get(lic.group(1), lic.group(1)) if lic else "?", "preview": g("mp3").replace("-lq.mp3", "-hq.mp3"),
                     "url": g("mp3").replace("-lq.mp3", "-hq.mp3"), "downloads": dl,
                     "stats": f"↓{dl} ★{rt[1]}({rn[1]})" if rt and rn else f"↓{dl} ★-",
                     # the uploader's own words (mic, source, processing) are the closest thing to hearing it
                     "desc": html.unescape(re.sub(r"<[^>]+>|\s+", " ", desc[1])).strip()[:90] if desc else ""})
    if a.sort == "relevance":
        rows.sort(key=lambda r: -r["downloads"])
    show(rows[: a.n], a, lic=a.license != "cc0")


def get(a):
    out = Path(a.out_dir)
    out.mkdir(parents=True, exist_ok=True)
    idx = load_index()

    def one(key):
        src, sep, ref = key.partition(":")
        if src != "fs" or not sep:
            return key, None, "unsupported key — only fs: keys are supported"
        r = idx.get(key)
        if not r:
            return key, None, "unknown key — search first"
        slug = re.sub(r"[^\w]+", "-", r["title"]).strip("-")[:40]
        dst = out / f"{src}_{ref}{'_' + slug if slug else ''}{Path(urllib.parse.urlparse(r['url']).path).suffix}"
        if not dst.exists():
            tmp = dst.with_suffix(dst.suffix + ".part")
            tmp.write_bytes(fetch(r["url"], timeout=300))
            tmp.rename(dst)
        lic = r.get("license", "CC0")
        return key, dst, f"credit {r.get('author', '?')}" if lic != "CC0" else None

    def safe(key):
        try:
            return one(key)
        except Exception as e:  # one bad file shouldn't sink the batch
            return key, None, repr(e)

    # Freesound caps ~80 KB/s per connection, so parallelism is the only speed lever.
    with ThreadPoolExecutor(6) as ex:
        for key, dst, note in ex.map(safe, a.keys):
            print(f"FAIL {key}: {note}" if not dst else f"{dst.name}  [{note}]" if note else dst.name)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sp = ap.add_subparsers(dest="cmd", required=True)
    f = sp.add_parser("freesound"); f.add_argument("query"); f.add_argument("--license", choices=FS_LICENSE, default="any")
    f.add_argument("--sort", choices=FS_SORT, default="relevance"); f.add_argument("-n", type=int, default=8); f.add_argument("--urls", action="store_true")
    f.add_argument("-p", "--page", type=int, default=1)
    f.add_argument("--pages", type=int, default=3, help="relevance pages (15 each) to rank by downloads"); f.set_defaults(fn=freesound)
    g = sp.add_parser("get"); g.add_argument("out_dir"); g.add_argument("keys", nargs="+"); g.set_defaults(fn=get)
    a = ap.parse_args()
    try:
        a.fn(a)
    except OSError as e:
        sys.exit(f"network error: {getattr(e, 'reason', e)}" + (" — try clash_freesound.py --fix" if a.cmd == "freesound" else ""))


if __name__ == "__main__":
    main()
