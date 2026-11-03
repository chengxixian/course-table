#!/usr/bin/env python3
"""Check / repair Clash routing for freesound.org (ClashX Meta, controller 127.0.0.1:9090).

  clash_freesound.py          status: rule present? which node? its latency
  clash_freesound.py --fix    re-add `Freesound` group + rule if a subscription update wiped them,
                              then select the lowest-latency node (all nodes hit the same
                              ~80 KB/s per-connection cap, so latency/stability is what matters)
"""
import json, subprocess, sys, urllib.parse, urllib.request
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from pathlib import Path

API = "http://127.0.0.1:9090"
TEST = "https://freesound.org/favicon.ico"
GROUP, RULE = "Freesound", " - DOMAIN-SUFFIX,freesound.org,Freesound"
NOT_NODES = {"Selector", "URLTest", "Fallback", "LoadBalance", "Relay", "Direct", "Reject", "RejectDrop", "Compatible", "Pass"}
local = urllib.request.build_opener(urllib.request.ProxyHandler({}))  # never proxy the controller


def api(path, method="GET", body=None):
    req = urllib.request.Request(API + path, method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Content-Type": "application/json"})
    with local.open(req, timeout=30) as r:
        raw = r.read()
        return json.loads(raw) if raw else None


def delay(name):
    try:
        return api(f"/proxies/{urllib.parse.quote(name)}/delay?url={urllib.parse.quote(TEST)}&timeout=5000")["delay"]
    except Exception:
        return None


def profile():
    name = subprocess.run(["defaults", "read", "com.metacubex.ClashX.meta", "selectConfigName"],
                          capture_output=True, text=True).stdout.strip()
    return Path.home() / ".config/clash.meta" / f"{name}.yaml"


def status():
    rule = next((r for r in api("/rules")["rules"] if r["payload"] == "freesound.org"), None)
    grp = api("/proxies").get("proxies", {}).get(GROUP)
    now = grp["now"] if grp else None
    print(f"profile: {profile()}")
    print(f"rule:    {'ok → ' + rule['proxy'] if rule else 'MISSING'}")
    print(f"group:   {now or 'MISSING'}" + (f"  ({delay(now)} ms)" if now else ""))
    return bool(rule and grp)


def fix():
    proxies = api("/proxies")["proxies"]
    nodes = [n for n, v in proxies.items() if v["type"] not in NOT_NODES]
    with ThreadPoolExecutor(16) as ex:
        ranked = sorted((d, n) for n, d in zip(nodes, ex.map(delay, nodes)) if d)
    if not ranked:
        sys.exit("no node reached freesound.org")
    best = [n for _, n in ranked[:12]]
    print("fastest:", ", ".join(f"{n} {d}ms" for d, n in ranked[:5]))
    if not status():
        p = profile()
        txt = p.read_text(encoding="utf-8")
        p.with_name(f"{p.name}.bak-{date.today():%Y%m%d}").write_text(txt, encoding="utf-8")
        if f"name: {GROUP}\n" not in txt:
            grp = f"  - name: {GROUP}\n    type: select\n    proxies:\n" + "".join(f"      - {n}\n" for n in best) + "      - DIRECT\n"
            txt = txt.replace("\nproxy-groups:\n", "\nproxy-groups:\n" + grp, 1)
        if "DOMAIN-SUFFIX,freesound.org," not in txt:
            txt = txt.replace("\nrules:\n", "\nrules:\n" + RULE + "\n", 1)
        p.write_text(txt, encoding="utf-8")
        api("/configs?force=true", "PUT", {"path": str(p)})
        print(f"patched + reloaded {p.name} (backup saved)")
    members = api(f"/proxies/{GROUP}")["all"]
    pick = next((n for n in best if n in members), members[0])
    api(f"/proxies/{urllib.parse.quote(GROUP)}", "PUT", {"name": pick})
    status()


if __name__ == "__main__":
    fix() if "--fix" in sys.argv else status()
