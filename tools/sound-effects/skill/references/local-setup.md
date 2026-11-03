ClashX Meta (mihomo), controller 127.0.0.1:9090, no secret; shell exports http(s)_proxy=127.0.0.1:7890.
Profile: ~/.config/clash.meta/<`defaults read com.metacubex.ClashX.meta selectConfigName`>.yaml — a subscription, so updates wipe manual edits.
Fix = select group `Freesound` (low-latency nodes + DIRECT) + first rule `DOMAIN-SUFFIX,freesound.org,Freesound`, then `PUT /configs?force=true {"path":...}`.
Measured 2026-10-05: default node SG IEPL 7 times out; DIRECT ~5–13 KB/s; every working node ~80 KB/s per connection (server limit, Finland), so pick by latency only — EU nodes ~170–220 ms.
Freesound originals need API key + OAuth2 (not set up); previews (~190 kbps mp3) suffice.
