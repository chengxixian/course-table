class AppMeta {
  static const name = '课程表';

  /// Version and build come from the installed package at runtime.
  ///
  /// These used to be compile-time constants, which meant the About page and
  /// the update check reported whatever was hard-coded here no matter what the
  /// user had installed: a 3.1.5 build still said 3.1.4 and kept offering
  /// itself as an update forever. [applyPackageInfo] fills them in during
  /// bootstrap; the fallbacks only cover a package_info failure.
  static String version = '3.1.6';
  static int build = 51;

  static void applyPackageInfo({required String version, required String buildNumber}) {
    if (version.trim().isNotEmpty) AppMeta.version = version.trim();
    final parsed = int.tryParse(buildNumber.trim());
    if (parsed != null && parsed > 0) AppMeta.build = parsed;
  }

  static const owner = 'chengxixian';
  static const repo = 'course-table';
  static const githubUrl = 'https://github.com/$owner/$repo';
  static const flowUploadUrl = String.fromEnvironment('FLOW_UPLOAD_URL', defaultValue: 'https://course-table-flow.pages.dev/'); // 配置中转接口后，App 可一键上传导入流程
  static const aiParseUrl = 'https://course-table-flow.pages.dev/ai-parse';
  static const aiNavUrl = 'https://course-table-flow.pages.dev/ai-nav';
  static const versionApiUrl = 'https://api.github.com/repos/$owner/$repo/releases/latest';
  static const releasesUrl = '$githubUrl/releases';

  /// `?b=<build>` busts the CDN cache. Read through getters so the URL follows
  /// the runtime build number instead of freezing at class-initialization time.
  static String get versionUrl => 'https://cdn.jsdelivr.net/gh/$owner/$repo@main/version.json?b=$build';
  static String get versionUrlFallback => 'https://raw.githubusercontent.com/$owner/$repo/main/version.json?b=$build';
  static String get versionUrlMirror => 'https://ghproxy.net/https://raw.githubusercontent.com/$owner/$repo/main/version.json?b=$build';
  static String get versionUrlFastly => 'https://fastly.jsdelivr.net/gh/$owner/$repo@main/version.json?b=$build';
  static String get versionUrlGcore => 'https://gcore.jsdelivr.net/gh/$owner/$repo@main/version.json?b=$build';
}
