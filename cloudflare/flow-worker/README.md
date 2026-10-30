# 课程表导入流程中转 Worker

GitHub 不允许 App 匿名写入。这个 Worker 让 App 只发 `school + url`，由 Worker 用服务端 token 创建分支和 PR。

## 部署

1. 创建细粒度 GitHub token：只给 `chengxixian/course-table` 的 **Contents: Read/Write** 和 **Pull requests: Read/Write**，不要给 Actions/Administration。
2. Cloudflare 控制台创建 Worker，粘贴 `src.js`；在 Settings → Variables 添加：
   - `GITHUB_TOKEN`（加密）
   - `GITHUB_REPO=chengxixian/course-table`
   - `GITHUB_BRANCH=main`
3. 可选：绑定 KV 到 `FLOW_RATE_LIMIT` 做 IP 限流。
4. 构建 App 时传入 Worker 地址：
   ```bash
   flutter build apk --release --dart-define=FLOW_UPLOAD_URL=https://course-table-flow.<你的子域>.workers.dev
   ```
5. 上传成功后 Worker 返回 PR 链接；合并后学校进入仓库，后续可做远端学校列表。

## 安全

- Token 只在 Worker 环境变量，不进 APK。
- 只接受 `school` 和 `url`，拒绝 Cookie/HTML/密码字段。
- 只创建 PR，不直接写 `main`，人工审核后合并。
- 限制 body 4KB、学校名 40 字、URL 必须 http(s)、禁止 URL 内嵌账号密码。
- 建议开启 KV 限流（每 IP 60 秒 1 次）。
