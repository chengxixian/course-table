import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_meta.dart';
import '../acknowledgements_service.dart';
import '../pixel_icons.dart';
import '../update_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const privacyUrl = '${AppMeta.githubUrl}/blob/main/docs/PRIVACY.md';
  static const sdkUrl = '${AppMeta.githubUrl}/blob/main/docs/SDK.md';
  static const noticeUrl = '${AppMeta.githubUrl}/blob/main/NOTICE';
  static const licenseUrl = '${AppMeta.githubUrl}/blob/main/LICENSE';

  Future<void> _checkUpdate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final info = await UpdateService.check(force: true);
      if (!context.mounted) return;
      if (info == null) {
        messenger.showSnackBar(const SnackBar(
          duration: Duration(seconds: 3),
          content: Text('当前已是最新版本'),
        ));
        return;
      }
      await UpdateService.showDialogFor(context, info);
    } on UpdateCheckException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 5),
        content: Text('检查更新失败：${e.message}'),
      ));
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法打开链接')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '返回',
                icon: Icon(PixelIcons.chevron_left, size: 22),
              ),
            ),
            const SizedBox(height: 18),
            Text('关于', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: -1)),
            const SizedBox(height: 28),
            Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: scheme.shadow.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/icon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 18),
            Center(child: Text(AppMeta.name, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: scheme.onSurface))),
            const SizedBox(height: 4),
            Center(child: Text('版本 ${AppMeta.version} · Flutter', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))),
            const SizedBox(height: 20),
            Row(children: [
              _Action(icon: PixelIcons.auto_awesome, label: '更新', onTap: () => _checkUpdate(context)),
              _Action(icon: PixelIcons.info_outline, label: '支持', onTap: () => _open(context, '${AppMeta.githubUrl}/issues')),
              _Action(icon: PixelIcons.open_in_new, label: 'GitHub', onTap: () => _open(context, AppMeta.githubUrl)),
            ]),
            const SizedBox(height: 26),
            Text('开发', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Material(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: InkWell(
                onTap: () => _open(context, AppMeta.githubUrl),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(PixelIcons.open_in_new, size: 20, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text(AppMeta.owner, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('开发 / 维护', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                    ])),
                    Icon(PixelIcons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: scheme.surfaceContainerLow,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: scheme.outlineVariant),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(PixelIcons.menu_book_outlined, size: 19),
                title: const Text('开源许可', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                subtitle: const Text('GNU General Public License v3.0', style: TextStyle(fontSize: 9)),
                trailing: Icon(PixelIcons.chevron_right, size: 16),
                onTap: () => showLicensePage(context: context, applicationName: AppMeta.name, applicationVersion: AppMeta.version),
              ),
            ),
            const SizedBox(height: 6),
            Text('含改编自 Classy（IMSX3D，GPL-3.0，commit 8a2499d）的 Kotlin 解析器；完整版权与修改说明见「第三方声明」。',
                style: TextStyle(fontSize: 9, height: 1.4, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Text('赞赏', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('如果这个课表工具帮到了你，可以请作者喝杯饮料。感谢每一份支持。',
                style: TextStyle(fontSize: 10, height: 1.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _DonateCard(image: 'assets/donate_wechat.png', title: '微信赞赏', color: const Color(0xFF07C160))),
              const SizedBox(width: 10),
              Expanded(child: _DonateCard(image: 'assets/donate_alipay.jpg', title: '支付宝', color: const Color(0xFF1677FF))),
            ]),
            const SizedBox(height: 8),
            Text('用微信 / 支付宝「扫一扫」扫描二维码，或截图后从相册识别。',
                style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('致谢', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                const _AcknowledgementsText(),
              ]),
            ),
            const SizedBox(height: 14),
            Text('开源项目', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Material(
              color: scheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                title: const Text('查看引用的开源项目', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                subtitle: const Text('Classy、Flutter、依赖库与字体', style: TextStyle(fontSize: 9)),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                children: [
                  _credit(context, 'Classy', 'GPL-3.0', 'https://github.com/IMSX3D/Classy'),
                  _credit(context, 'Flutter / Dart', 'BSD-3-Clause', 'https://github.com/flutter/flutter'),
                  _credit(context, 'dynamic_color', 'Apache-2.0', 'https://pub.dev/packages/dynamic_color'),
                  _credit(context, 'home_widget', 'BSD-3-Clause', 'https://pub.dev/packages/home_widget'),
                  _credit(context, 'workmanager', 'MIT', 'https://pub.dev/packages/workmanager'),
                  _credit(context, 'webview_flutter', 'BSD-3-Clause', 'https://pub.dev/packages/webview_flutter'),
                  _credit(context, 'm3e_core / material_ui', 'MIT / BSD-3-Clause', 'https://pub.dev/packages/m3e_core'),
                  _credit(context, 'flutoryx', 'MIT', 'https://pub.dev/packages/flutoryx'),
                  _credit(context, 'file_picker', 'MIT', 'https://pub.dev/packages/file_picker'),
                  _credit(context, 'excel', 'MIT', 'https://pub.dev/packages/excel'),
                  _credit(context, 'PDFBox-Android', 'Apache-2.0', 'https://github.com/TomRoush/PdfBox-Android'),
                  _credit(context, 'jsoup', 'MIT', 'https://jsoup.org/'),
                  _credit(context, 'FandolFang 字体', 'GPL-3.0 + 字体例外', 'https://ctan.org/pkg/fandol'),
                  _credit(context, 'Liberation Serif 字体', 'SIL OFL 1.1', 'https://github.com/liberationfonts/liberation-fonts'),
                  _credit(context, 'FusionPixel 字体', 'SIL OFL 1.1', 'https://github.com/TakWolf/fusion-pixel-font'),
                  _credit(context, 'Pixelarticons', 'MIT', 'https://github.com/halfmage/pixelarticons'),
                  TextButton.icon(
                    onPressed: () => _open(context, AboutScreen.noticeUrl),
                    icon: const Icon(Icons.article_outlined, size: 15),
                    label: const Text('完整版权与修改说明', style: TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('隐私与数据', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(spacing: 4, runSpacing: 0, children: [
              TextButton.icon(
                onPressed: () => _open(context, AboutScreen.privacyUrl),
                icon: const Icon(Icons.privacy_tip_outlined, size: 15),
                label: const Text('隐私政策', style: TextStyle(fontSize: 10)),
              ),
              TextButton.icon(
                onPressed: () => _open(context, AboutScreen.sdkUrl),
                icon: const Icon(Icons.inventory_2_outlined, size: 15),
                label: const Text('SDK 清单', style: TextStyle(fontSize: 10)),
              ),
              TextButton.icon(
                onPressed: () => _open(context, AboutScreen.noticeUrl),
                icon: const Icon(Icons.article_outlined, size: 15),
                label: const Text('第三方声明', style: TextStyle(fontSize: 10)),
              ),
              TextButton.icon(
                onPressed: () => _open(context, AboutScreen.licenseUrl),
                icon: const Icon(Icons.gavel_outlined, size: 15),
                label: const Text('许可证全文', style: TextStyle(fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 8),
            Text('登录信息以 AES-256-GCM 加密保存在本机应用私有存储；AI 导入会把当前页面可见文本（最多约 3 万字）发送到 Cloudflare，再转交智谱 AI 解析，其中 10–12 位数字会在云端脱敏；上传导入流程会在公开 PR 中公开学校名与网址。',
                style: TextStyle(fontSize: 9, height: 1.5, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Center(child: Text('源代码以 GPL-3.0 发布 · 非官方个人工具', style: TextStyle(fontSize: 8.5, color: scheme.outline))),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            Icon(icon, size: 24, color: scheme.onSurface),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}

class _DonateCard extends StatelessWidget {
  final String image;
  final String title;
  final Color color;
  const _DonateCard({required this.image, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 0.74,
            child: Image.asset(image, fit: BoxFit.cover, alignment: Alignment.topCenter),
          ),
        ),
        const SizedBox(height: 7),
        Text(title, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: scheme.onSurface)),
      ]),
    );
  }
}



Widget _credit(BuildContext context, String name, String license, String url) {
  final scheme = Theme.of(context).colorScheme;
  return InkWell(
    onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(name, style: const TextStyle(fontSize: 11))),
        Text(license, style: TextStyle(fontSize: 8.5, color: scheme.primary)),
        const SizedBox(width: 4),
        Icon(Icons.open_in_new, size: 13, color: scheme.onSurfaceVariant),
      ]),
    ),
  );
}

class _AcknowledgementsText extends StatelessWidget {
  const _AcknowledgementsText();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<List<String>>(
      future: AcknowledgementsService.load(),
      builder: (context, snapshot) {
        final names = snapshot.data ?? AcknowledgementsService.fallback;
        return Text('感谢 ${names.join('、')} 对项目的帮助与支持。',
            style: TextStyle(fontSize: 11, height: 1.6, color: scheme.onSurface));
      },
    );
  }
}
