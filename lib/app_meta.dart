class AppMeta {
  static const name = '课程表';
  static const version = '2.0.16';
  static const build = 18;
  static const owner = 'chengxixian';
  static const repo = 'course-table';
  static const githubUrl = 'https://github.com/$owner/$repo';
  static const flowUploadUrl = String.fromEnvironment('FLOW_UPLOAD_URL', defaultValue: 'https://course-table-flow.pages.dev/'); // 配置中转接口后，App 可一键上传导入流程
  static const aiParseUrl = 'https://course-table-flow.pages.dev/ai-parse';
  static const aiNavUrl = 'https://course-table-flow.pages.dev/ai-nav';
  static const versionApiUrl = 'https://api.github.com/repos/$owner/$repo/releases/latest';
  static final String versionUrl = 'https://cdn.jsdelivr.net/gh/$owner/$repo@main/version.json?b=$build';
  static final String versionUrlFallback = 'https://raw.githubusercontent.com/$owner/$repo/main/version.json?b=$build';
  static final String versionUrlMirror = 'https://ghproxy.net/https://raw.githubusercontent.com/$owner/$repo/main/version.json?b=$build';
  static final String versionUrlFastly = 'https://fastly.jsdelivr.net/gh/$owner/$repo@main/version.json?b=$build';
  static final String versionUrlGcore = 'https://gcore.jsdelivr.net/gh/$owner/$repo@main/version.json?b=$build';
  static const releasesUrl = '$githubUrl/releases';
}
