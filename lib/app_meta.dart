class AppMeta {
  static const name = '课程表';

  /// Version and build come from the installed package at runtime.
  ///
  /// These used to be compile-time constants, which meant the About page and
  /// the update check reported whatever was hard-coded here no matter what the
  /// user had installed: a 3.1.5 build still said 3.1.4 and kept offering
  /// itself as an update forever. [applyPackageInfo] fills them in during
  /// bootstrap; the fallbacks only cover a package_info failure.
  static String version = '3.1.9';
  static int build = 54;

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

  /// Time-based cache buster. The old `?b=<build>` was a design flaw: the
  /// build number only changes *after* an update, so every check from an
  /// installed app hit the same CDN URL — and jsdelivr kept serving a stale
  /// snapshot of it (a 3.1.6 app was told 3.1.5 was the latest, forever).
  /// A minute-granularity timestamp forces a fresh fetch while keeping the
  /// cache effective within the minute.
  static String get _buster => '?t=${DateTime.now().millisecondsSinceEpoch ~/ 60000}';

  static String get versionUrl => 'https://cdn.jsdelivr.net/gh/$owner/$repo@main/version.json$_buster';
  static String get versionUrlFallback => 'https://raw.githubusercontent.com/$owner/$repo/main/version.json$_buster';
  static String get versionUrlMirror => 'https://ghproxy.net/https://raw.githubusercontent.com/$owner/$repo/main/version.json$_buster';
  static String get versionUrlFastly => 'https://fastly.jsdelivr.net/gh/$owner/$repo@main/version.json$_buster';
  static String get versionUrlGcore => 'https://gcore.jsdelivr.net/gh/$owner/$repo@main/version.json$_buster';
}
