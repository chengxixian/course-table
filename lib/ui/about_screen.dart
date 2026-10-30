import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_meta.dart';
import '../acknowledgements_service.dart';
import '../pixel_icons.dart';
import '../update_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
            Center(child: Text('课程表', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: scheme.onSurface))),
            const SizedBox(height: 4),
            Center(child: Text('版本 ${AppMeta.version} · Flutter', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant))),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => _checkUpdate(context),
                icon: Icon(PixelIcons.sync, size: 16),
                label: const Text('检查更新'),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              _Action(icon: PixelIcons.auto_awesome, label: '更新', onTap: () => _open(context, AppMeta.releasesUrl)),
              _Action(icon: PixelIcons.info_outline, label: '支持', onTap: () => _open(context, '${AppMeta.githubUrl}/issues')),
              _Action(icon: PixelIcons.open_in_new, label: 'GitHub', onTap: () => _open(context, AppMeta.githubUrl)),
            ]),
            const SizedBox(height: 26),
            Text('开发', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(PixelIcons.open_in_new, size: 20, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('chengxixian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('开发 / 维护', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                ])),
                IconButton(
                  onPressed: () => _open(context, AppMeta.githubUrl),
                  icon: Icon(PixelIcons.chevron_right, size: 18),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(PixelIcons.menu_book_outlined, size: 19),
              title: const Text('开源许可', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              subtitle: const Text('GNU General Public License v3.0', style: TextStyle(fontSize: 9)),
              trailing: Icon(PixelIcons.chevron_right, size: 16),
              onTap: () => showLicensePage(context: context, applicationName: AppMeta.name, applicationVersion: AppMeta.version),
            ),
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
            Text('长按二维码识别，或保存后在微信 / 支付宝中扫码。',
                style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('致谢', style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                const _AcknowledgementsText(),
              ]),
            ),
            const SizedBox(height: 22),
            Text('登录信息使用 AES-GCM 加密保存在本机应用私有目录；应用不收集、不上传课表与账号信息。',
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
