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


async function aiParse(request, env) {
  if (!env.ZHIPU_API_KEY) return json({ error: 'AI 未配置' }, 500);
  const len = Number(request.headers.get('content-length') || 0);
  if (len > 45000) return json({ error: '页面内容过大' }, 413);
  let body;
  try { body = await request.json(); } catch { return json({ error: 'invalid json' }, 400); }
  const raw = String(body.text || body.html || '').slice(0, 30000);
  if (raw.trim().length < 20) return json({ error: '页面内容过少' }, 400);
  const text = raw
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/[0-9]{10,12}/g, '[学号已脱敏]')
    .replace(/[ \t]+/g, ' ')
    .slice(0, 26000);
  const prompt = `你是高校课表结构化解析器。只输出一个 JSON 对象，不要 Markdown、不要解释。
格式：
{"courses":[{"name":"课程名","teacher":"教师或空字符串","room":"教室或空字符串","day":1,"startPeriod":1,"endPeriod":2,"start":"08:00","end":"09:40","weeks":"1-16"}]}
规则：
- day：周一=1 ... 周日=7。
- startPeriod/endPeriod：1-20 的整数；不要猜测，按页面节次。
- start/end：24 小时制 HH:mm；页面没有时间就留空字符串。
- room：页面没有教室就留空字符串，不要编造。
- weeks：如 1-16、1-8,10-16；没有就留空。
- 只提取真实课程，不要把导航、按钮、表头当课程。
- 如果完全无法识别，输出 {"courses":[]}。
页面文本：
${text}`;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 28000);
    const response = await fetch('https://open.bigmodel.cn/api/paas/v4/chat/completions', {
      method: 'POST',
      signal: controller.signal,
      headers: { authorization: `Bearer ${env.ZHIPU_API_KEY}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        model: env.ZHIPU_MODEL || 'glm-4-flash',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.1,
        max_tokens: 4096,
        response_format: { type: 'json_object' },
      }),
    });
    clearTimeout(timer);
    const data = await response.json();
    if (!response.ok) return json({ error: 'AI 服务错误', detail: data?.error?.message || response.status }, 502);
    let content = data?.choices?.[0]?.message?.content || '';
    content = String(content).trim().replace(/^```(?:json)?\s*/i, '').replace(/```$/i, '').trim();
    let parsed;
    try { parsed = JSON.parse(content); } catch { return json({ error: 'AI 返回格式错误' }, 502); }
    const courses = Array.isArray(parsed.courses) ? parsed.courses : [];
    const clean = courses.map((c) => ({
      name: String(c.name || '').trim(),
      teacher: String(c.teacher || '').trim(),
      room: String(c.room || '').trim(),
      day: Number(c.day) || 0,
      startPeriod: Number(c.startPeriod) || 0,
      endPeriod: Number(c.endPeriod) || 0,
      start: String(c.start || '').trim(),
      end: String(c.end || '').trim(),
      weeks: String(c.weeks || '').trim(),
    })).filter((c) => c.name && c.day >= 1 && c.day <= 7 && c.startPeriod >= 1 && c.endPeriod >= c.startPeriod);
    return json({ courses: clean, model: env.ZHIPU_MODEL || 'glm-4-flash' });
  } catch (e) {
    return json({ error: 'AI 请求失败', detail: String(e.message || e).slice(0, 200) }, 502);
  }
}


async function aiNav(request, env) {
  if (!env.ZHIPU_API_KEY) return json({ error: 'AI 未配置' }, 500);
  let body;
  try { body = await request.json(); } catch { return json({ error: 'invalid json' }, 400); }
  const controls = Array.isArray(body.controls) ? body.controls.slice(0, 80) : [];
  if (!controls.length) return json({ index: -1 });
  const page = String(body.text || '').slice(0, 12000);
  const list = controls.map((c, i) => `${i}. tag=${c.tag || ''} type=${c.type || ''} text=${String(c.text || '').replace(/\s+/g, ' ').slice(0, 80)} aria=${String(c.aria || '').slice(0, 60)} title=${String(c.title || '').slice(0, 60)}`).join('\n');
  const prompt = `你是高校课表网页的周次导航器。根据控件列表和页面文本，判断哪个控件能进入“下一周”课表。
只输出 JSON：{"index": 数字}；不确定输出 {"index": -1}。
规则：
- 优先“下一周/下周/后一周/下一頁/下一个”或向右箭头。
- 排除“上一周/上周/前一页”、登录、退出、提交、保存、打印、刷新、学期切换。
- 如果控件是下拉框，且列表里有“周次/周”相关选项，选能表示下一周的控件；没有就 -1。
页面文本片段：
${page}
控件列表：
${list}`;
  try {
    const r = await fetch('https://open.bigmodel.cn/api/paas/v4/chat/completions', {
      method: 'POST',
      headers: { authorization: `Bearer ${env.ZHIPU_API_KEY}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        model: env.ZHIPU_MODEL || 'glm-4-flash',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0,
        max_tokens: 120,
        response_format: { type: 'json_object' },
      }),
    });
    const data = await r.json();
    if (!r.ok) return json({ index: -1, error: 'AI 服务错误' }, 502);
    let content = String(data?.choices?.[0]?.message?.content || '').trim().replace(/^```(?:json)?\s*/i, '').replace(/```$/i, '').trim();
    let parsed;
    try { parsed = JSON.parse(content); } catch { return json({ index: -1 }); }
    const index = Number(parsed.index);
    if (!Number.isInteger(index) || index < 0 || index >= controls.length) return json({ index: -1 });
    return json({ index });
  } catch (e) {
    return json({ index: -1, error: String(e.message || e).slice(0, 120) }, 502);
  }
}

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return json({ error: 'method not allowed' }, 405);
    const path = new URL(request.url).pathname;
    if (path.endsWith('/ai-parse')) return aiParse(request, env);
    if (path.endsWith('/ai-nav')) return aiNav(request, env);
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
