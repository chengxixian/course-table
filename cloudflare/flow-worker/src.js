const MAX_BODY = 4096;

function json(data, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { 'content-type': 'application/json; charset=utf-8' } });
}

function slugify(name) {
  return name.toLowerCase().replace(/[^a-z0-9\u4e00-\u9fa5]+/g, '-').replace(/^-|-$/g, '').slice(0, 48) || 'school';
}

async function gh(env, path, init = {}) {
  const res = await fetch(`https://api.github.com${path}`, {
    ...init,
    headers: {
      authorization: `Bearer ${env.GITHUB_TOKEN}`,
      accept: 'application/vnd.github+json',
      'user-agent': 'course-table-flow-worker',
      'content-type': 'application/json',
      ...(init.headers || {}),
    },
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`GitHub ${res.status}: ${body.slice(0, 300)}`);
  return body ? JSON.parse(body) : {};
}

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return json({ error: 'method not allowed' }, 405);
    const len = Number(request.headers.get('content-length') || 0);
    if (len > MAX_BODY) return json({ error: 'body too large' }, 413);
    let body;
    try { body = await request.json(); } catch { return json({ error: 'invalid json' }, 400); }

    const school = String(body.school || '').trim();
    const url = String(body.url || '').trim();
    if (!school || school.length > 40 || /[\r\n<>]/.test(school)) return json({ error: 'invalid school' }, 400);
    let parsed;
    try { parsed = new URL(url); } catch { return json({ error: 'invalid url' }, 400); }
    if (!['https:', 'http:'].includes(parsed.protocol)) return json({ error: 'invalid url scheme' }, 400);
    if (parsed.username || parsed.password) return json({ error: 'credentials in url are not allowed' }, 400);

    // Optional KV rate limit: bind FLOW_RATE_LIMIT (KV namespace).
    if (env.FLOW_RATE_LIMIT) {
      const ip = request.headers.get('cf-connecting-ip') || 'unknown';
      const key = `flow:${ip}`;
      const last = Number(await env.FLOW_RATE_LIMIT.get(key) || 0);
      if (Date.now() - last < 60_000) return json({ error: 'too many requests' }, 429);
      await env.FLOW_RATE_LIMIT.put(key, String(Date.now()), { expirationTtl: 120 });
    }

    const repo = env.GITHUB_REPO;
    const base = env.GITHUB_BRANCH || 'main';
    if (!repo || !env.GITHUB_TOKEN) return json({ error: 'server not configured' }, 500);

    try {
      const ref = await gh(env, `/repos/${repo}/git/ref/heads/${base}`);
      const branch = `flow/${slugify(school)}-${Date.now()}`;
      await gh(env, `/repos/${repo}/git/refs`, {
        method: 'POST',
        body: JSON.stringify({ ref: `refs/heads/${branch}`, sha: ref.object.sha }),
      });
      const path = `schools/pending/${slugify(school)}-${Date.now()}.json`;
      const content = btoa(unescape(encodeURIComponent(JSON.stringify({
        school, url, source: 'app', submittedAt: new Date().toISOString(),
      }, null, 2))));
      await gh(env, `/repos/${repo}/contents/${path}`, {
        method: 'PUT',
        body: JSON.stringify({ message: `flow: ${school}`, content, branch }),
      });
      const pr = await gh(env, `/repos/${repo}/pulls`, {
        method: 'POST',
        body: JSON.stringify({
          title: `新增高校导入流程：${school}`,
          head: branch,
          base,
          body: `由课程表 App 提交。\n\n学校：${school}\n课表网址：${url}\n\n请审核后再合并。`,
        }),
      });
      return json({ ok: true, pr: pr.html_url, number: pr.number });
    } catch (e) {
      return json({ error: String(e.message || e).slice(0, 300) }, 502);
    }
  },
};
