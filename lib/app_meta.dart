class AppMeta {
  static const name = '课程表';
  static const version = '2.0.7';
  static const build = 9;
  static const owner = 'chengxixian';
  static const repo = 'course-table';
  static const githubUrl = 'https://github.com/$owner/$repo';
  static const flowUploadUrl = String.fromEnvironment('FLOW_UPLOAD_URL', defaultValue: 'https://course-table-flow.pages.dev/'); // 配置中转接口后，App 可一键上传导入流程
  static const versionUrl = 'https://cdn.jsdelivr.net/gh/$owner/$repo@main/version.json';
  static const versionUrlFallback = 'https://raw.githubusercontent.com/$owner/$repo/main/version.json';
  static const versionUrlMirror = 'https://ghproxy.net/https://raw.githubusercontent.com/$owner/$repo/main/version.json';
  static const releasesUrl = '$githubUrl/releases';
}
