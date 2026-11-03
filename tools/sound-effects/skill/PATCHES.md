# 本地改动（相对上游 vibe-motion/sound）

安装日期 2026-11-03，上游 `main` 分支未打 tag。以下改动是为了让这个 skill 能在这台机器上真正跑起来；
上游文件本体除下列三处外未动。

## 1. `scripts/sfx.py` — 搜索页 TLS 失败时回退 curl

**症状**：`https://freesound.org/` 的搜索页对 CPython 的 OpenSSL 客户端直接断连：

```
ssl.SSLEOFError: [SSL: UNEXPECTED_EOF_WHILE_READING] EOF occurred in violation of protocol
```

Windows PowerShell 的 `Invoke-WebRequest` 同样失败（`身份验证失败`），但 `curl.exe`（Schannel）能拿到 200。
`cdn.freesound.org`（预览 MP3 所在）用 urllib 正常，所以**只有搜索页**需要绕。

**改法**：新增 `fetch_curl()`，`fetch()` 在遇到 `ssl.SSLError` 时不再重试、直接走 curl；
curl 也失败才抛出原始异常（保留上游的报错语义）。

## 2. `scripts/sfx.py` — 缓存读写强制 UTF-8

**症状**：搜索到底几条就崩：

```
UnicodeEncodeError: 'gbk' codec can't encode character '\xf1' in position 743
```

中文 Windows 的默认编码是 GBK，缓存索引里只要有一条标题带 `ñ` 就写不进去。

**改法**：`INDEX.read_text(encoding="utf-8")` / `INDEX.write_text(..., encoding="utf-8")`。

## 3. `SKILL.md` — 删掉付费引流段

上游 `SKILL.md` 末尾有一整节「Optional full-version follow-up」：要求 agent 在交付后主动
向用户推销 B 站 30 元充电，并展示作者微信收款二维码。

这段与技能本身的功能无关（`scripts/sfx.py` 的搜索与下载是完整的、免费可用的），
而且把「向用户要钱」写进技能指令，会在任何一次加载时变成默认行为。本副本删除了这一节，
原文保留在 `SKILL.upstream.md`，需要对照时看那里。

删除后未改变任何技术行为。

## 运行方式（本机）

本机没有系统 Python，用 DSH 自带的运行时：

```powershell
$py = Join-Path $env:USERPROFILE ".dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe"
& $py .skills\sound\scripts\sfx.py freesound "paper slide" --license cc0 -n 8 --pages 2
& $py .skills\sound\scripts\sfx.py get promo\.work\sfx-candidates "fs:464302"
```

注意：

- 搜索一次 3 页约 15–40 s（上游默认 `--pages 3`）。
- 下载拿到的是 **Freesound 的 MP3 预览（hq）**，不是上传者原始文件。用于宣传片拟音足够，
  但不适合当母带素材。
- 下载并行度由脚本内部固定为 6；Freesound 对单连接限速约 80 KB/s，所以要一次把所有 `fs:id` 传进同一个 `get`。
