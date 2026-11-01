import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../app_controller.dart';
import '../calendar_export.dart';
import '../google_calendar_import.dart';
import '../models.dart';
import 'components.dart';
import '../pixel_icons.dart';
import '../ui_theme.dart';
import 'about_screen.dart';
import 'import_web_screen.dart';
import '../imported_source.dart';
import '../schools.dart';
import '../school_registry.dart';
import '../flow_upload_service.dart';

class SettingsScreen extends StatelessWidget {
  final AppController controller;
  final VoidCallback onLogin;
  const SettingsScreen({super.key, required this.controller, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final schedule = controller.schedule;
    final profile = schedule?.student;
    final scheme = Theme.of(context).colorScheme;
    final settings = controller.settings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        PageHeader(
          kicker: '偏好与数据',
          title: '设置',
          subtitle: '管理同步、桌面小组件与 Google 日历。',
          actions: [
            FilledButton.icon(
              onPressed: controller.syncing ? null : () => _sync(context),
              icon: controller.syncing
                  ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(PixelIcons.sync, size: 17),
              label: Text(controller.syncing ? '同步中' : '立即同步'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionCard(
          kicker: 'ACCOUNT',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text((profile?.name.isNotEmpty ?? false) ? profile!.name.substring(0, 1) : '同',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(profile?.name ?? '同学', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text([profile?.className, profile?.college].where((e) => e != null && e.isNotEmpty).join(' · '),
                    style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant)),
                Text('学号 ${profile?.id ?? '—'}', style: TextStyle(fontSize: 9, color: scheme.outline)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.credentialsSaved ? scheme.primaryContainer : scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(controller.credentialsSaved ? PixelIcons.check : PixelIcons.warning_amber_rounded,
                      size: 11, color: controller.credentialsSaved ? scheme.onPrimaryContainer : scheme.onTertiaryContainer),
                  const SizedBox(width: 3),
                  Text(controller.credentialsSaved ? '已连接' : '待登录',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: controller.credentialsSaved ? scheme.onPrimaryContainer : scheme.onTertiaryContainer)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(14), border: Border.all(color: scheme.outlineVariant)),
              child: Row(children: [
                Expanded(child: _Fact(label: '上次同步', value: formatLastSync(controller.lastSync))),
                Expanded(child: _Fact(label: '数据来源', value: '教务管理系统')),
                Expanded(child: _Fact(label: '本学期', value: schedule?.semester.name ?? '—')),
              ]),
            ),
            if (controller.error != null) ...[
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(10)),
                child: Text('同步失败：${controller.error}', style: TextStyle(fontSize: 9.5, color: scheme.onErrorContainer)),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 6, children: [
              OutlinedButton.icon(onPressed: onLogin, icon: Icon(PixelIcons.lock_outline, size: 16), label: Text(controller.credentialsSaved ? '修改登录信息' : '登录')),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse('https://mwx.hsu.edu.cn/zhxy/home'), mode: LaunchMode.externalApplication),
                icon: Icon(PixelIcons.open_in_new, size: 15),
                label: const Text('打开信息门户'),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'DATA',
          title: '课程数据',
          subtitle: '清空本机保存的课表、网页导入源和小组件显示；不会删除登录账号。',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(controller.usingImportedSource ? '当前来源：未适配网页导入' : '当前来源：黄山学院门户', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (controller.usingImportedSource) ...[
              SizedBox(width: double.infinity, child: FilledButton.tonalIcon(
                onPressed: () async { await controller.useNativeSource(); },
                icon: const Icon(Icons.restore, size: 17),
                label: const Text('恢复黄山学院原生课表'),
              )),
              const SizedBox(height: 6),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _clearAllCourses(context),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('一键清除所有课程信息'),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'ADAPTED',
          title: '已适配高校',
          subtitle: '点击学校名称直接进入对应登录页；黄山学院保留原生同步。',
          child: ValueListenableBuilder<List<SchoolPreset>>(
            valueListenable: SchoolRegistry.schools,
            builder: (_, list, __) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('已适配 ${list.length} 所高校', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant))),
                IconButton(
                  tooltip: '搜索高校',
                  onPressed: () => _searchSchool(context),
                  icon: Icon(PixelIcons.search, size: 19),
                ),
              ]),
              for (final school in list.take(8))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.school_outlined, size: 20, color: scheme.onPrimaryContainer),
                  ),
                  title: Text(school.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(school.note, style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
                  trailing: Icon(PixelIcons.chevron_right, size: 18),
                  onTap: () => school.native
                      ? onLogin()
                      : _importWeb(context, initialUrl: school.loginUrl, schoolName: school.name),
                ),
              if (list.length > 8)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _searchSchool(context),
                    icon: const Icon(Icons.search, size: 16),
                    label: Text('搜索全部 ${list.length} 所高校'),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'UNADAPTED',
          title: '未适配高校导入',
          subtitle: '适用于课表有网页版的学校：记录你的登录与操作流程，导入成功后询问是否上传。',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => _importWeb(context, allowFlowUpload: true),
                icon: Icon(PixelIcons.open_in_new, size: 18),
                label: const Text('打开空白网页开始导入'),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _uploadExistingFlow(context),
                icon: const Icon(Icons.cloud_upload_outlined, size: 17),
                label: const Text('上传已导入流程（无需重新导入）'),
              ),
            ),
            const SizedBox(height: 7),
            Text('不会记录账号密码；只保存页面地址、操作路径与登录 Cookie。上传需要配置中转接口，GitHub 不允许匿名写入。',
                style: TextStyle(fontSize: 9, height: 1.5, color: scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'AUTOMATION',
          title: '自动同步',
          subtitle: '每天在指定时间从教务系统重新抓取一次。Android 使用 WorkManager 在后台执行，Windows 在应用运行时执行。',
          child: Column(children: [
            SettingRow(
              title: '每日自动更新',
              subtitle: '应用在后台或托盘运行时生效',
              trailing: Switch(value: settings.autoSync, onChanged: (v) => controller.updateSettings(settings.copyWith(autoSync: v))),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            SettingRow(
              title: '更新时间',
              subtitle: '建议在上午第一节课前完成',
              trailing: TextButton(
                onPressed: () => _pickTime(context, settings),
                child: Text(settings.refreshTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'WIDGET',
          title: '桌面小组件',
          subtitle: Platform.isAndroid ? 'Material 3 风格的桌面小组件，展示下一节课与今日课程。' : '将主窗口切换为悬浮小组件，始终置顶在桌面。',
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(
                Platform.isAndroid ? '支持 4×3 尺寸，可在桌面长按添加，也可以直接点击下方按钮。' : '悬浮模式会隐藏导航与侧栏，只保留下一节课与今日课程。',
                style: TextStyle(fontSize: 10, height: 1.5, color: scheme.onSurfaceVariant),
              )),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: () async {
                  if (Platform.isAndroid) {
                    await controller.requestPinWidget();
                  } else {
                    await _enterCompact(context);
                  }
                },
                icon: Icon(Platform.isAndroid ? PixelIcons.widgets_outlined : PixelIcons.picture_in_picture_alt_outlined, size: 17),
                label: Text(Platform.isAndroid ? '添加小组件' : '悬浮模式'),
              ),
            ]),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => controller.requestPinNextWidget(),
                  icon: Icon(PixelIcons.add, size: 15),
                  label: const Text('添加 2×1 下一节小组件'),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'CALENDAR',
          title: 'Google 日历',
          subtitle: Platform.isAndroid
              ? '一次写入本学期全部课程到手机上的 Google 日历账号，不需要逐节课添加。首次使用会请求日历权限。'
              : '一次性生成本学期全部课程事件（.ics），再导入 Google 日历。不会一节课一节课添加。',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: controller.schedule == null ? null : () => _importAll(context),
                icon: Icon(PixelIcons.event_available_outlined, size: 18),
                label: Text(Platform.isAndroid ? '导入全部课程到 Google 日历' : '导出全部课程到 Google 日历'),
              ),
            ),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => CalendarExport.openGoogleImport(),
                  icon: Icon(PixelIcons.open_in_new, size: 15),
                  label: const Text('打开 Google 日历导入页'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await controller.addNextToGoogle();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '已打开下一节课的 Google 日历事件' : '接下来没有课程')));
                  },
                  icon: Icon(PixelIcons.add, size: 16),
                  label: const Text('只添加下一节'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text('提示：Android 会直接写入已登录的 Google 日历（需要日历权限）。每节按 45 分钟计算，连续两节为 90 分钟。重复导入会自动跳过已存在的事件。',
                style: TextStyle(fontSize: 9, height: 1.5, color: scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'APPEARANCE',
          title: '外观',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('主题', style: TextStyle(fontSize: 9, letterSpacing: 1, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              for (final entry in [('light', '浅色'), ('dark', '深色'), ('system', '跟随系统')])
                ChoiceChip(
                  label: Text(entry.$2),
                  selected: settings.theme == entry.$1,
                  onSelected: (_) => controller.updateSettings(settings.copyWith(theme: entry.$1)),
                ),
            ]),
            const SizedBox(height: 12),
            Text('配色风格', style: TextStyle(fontSize: 9, letterSpacing: 1, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final entry in HsuTheme.palettes.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: settings.palette == entry.key,
                  onSelected: (_) => controller.updateSettings(settings.copyWith(palette: entry.key)),
                ),
            ]),
            const SizedBox(height: 12),
            Text('字体', style: TextStyle(fontSize: 9, letterSpacing: 1, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              ChoiceChip(
                label: const Text('仿宋 + Times'),
                selected: settings.fontStyle != 'pixel',
                onSelected: (_) => controller.updateSettings(settings.copyWith(fontStyle: 'fangsoong')),
              ),
              ChoiceChip(
                label: const Text('像素字体'),
                selected: settings.fontStyle == 'pixel',
                onSelected: (_) => controller.updateSettings(settings.copyWith(fontStyle: 'pixel')),
              ),
            ]),
            const SizedBox(height: 12),
            Text('图标', style: TextStyle(fontSize: 9, letterSpacing: 1, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              ChoiceChip(
                label: const Text('Material 图标'),
                selected: settings.iconStyle != 'pixel',
                onSelected: (_) => controller.updateSettings(settings.copyWith(iconStyle: 'material')),
              ),
              ChoiceChip(
                label: const Text('像素图标'),
                selected: settings.iconStyle == 'pixel',
                onSelected: (_) => controller.updateSettings(settings.copyWith(iconStyle: 'pixel')),
              ),
            ]),
            const SizedBox(height: 12),
            Text('单个课时长度', style: TextStyle(fontSize: 9, letterSpacing: 1, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, children: [
              ChoiceChip(
                label: const Text('45 分钟 / 节'),
                selected: settings.durationMode == '45',
                onSelected: (_) => controller.updateSettings(settings.copyWith(durationMode: '45')),
              ),
              ChoiceChip(
                label: const Text('按实际课间'),
                selected: settings.durationMode == 'actual',
                onSelected: (_) => controller.updateSettings(settings.copyWith(durationMode: 'actual')),
              ),
            ]),
            const SizedBox(height: 6),
            Text('默认按每节 45 分钟生成日历；连续两节为 90 分钟，不含 10 分钟课间。',
                style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 12),
        SectionCard(
          kicker: 'ABOUT',
          title: '关于',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _AboutRow(label: '版本', value: '2.0.0 · Flutter'),
            _AboutRow(label: '数据', value: '信息门户 / 教务管理系统'),
            const SizedBox(height: 9),
            Text('非官方工具，仅用于个人课表查看与日历整理。登录信息只保存在本机。',
                style: TextStyle(fontSize: 9, height: 1.55, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Row(children: [
              TextButton.icon(
                onPressed: () => controller.clearCredentials(),
                icon: Icon(PixelIcons.logout, size: 15),
                label: const Text('清除登录信息'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                icon: Icon(PixelIcons.info_outline, size: 15),
                label: const Text('关于课程表'),
              ),
            ]),
          ]),
        )
      ],
    );
  }

  Future<void> _importWeb(BuildContext context, {String? initialUrl, String? schoolName, bool allowFlowUpload = false}) async {
    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('网页导入目前仅支持 Android')));
      return;
    }
    final source = await Navigator.of(context).push<ImportedSource>(
      MaterialPageRoute(builder: (_) => ImportWebScreen(initialUrl: initialUrl, strongAi: false)),
    );
    if (source == null || !context.mounted) return;
    try {
      await controller.applyImportedSource(source);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        content: Text('网页课表已导入'),
      ));
      if (allowFlowUpload) {
        await _askUploadFlow(context, source, schoolName: schoolName ?? '未命名高校');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  Future<void> _uploadExistingFlow(BuildContext context) async {
    final source = controller.currentImportedSource;
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('还没有网页导入记录，请先导入一次课表')));
      return;
    }
    await _askUploadFlow(context, source, schoolName: '未命名高校');
  }

  Future<void> _askUploadFlow(BuildContext context, ImportedSource source, {required String schoolName}) async {
    final host = Uri.tryParse(source.url)?.host ?? '';
    final defaultName = schoolName == '未命名高校' ? host : schoolName;
    final nameController = TextEditingController(text: defaultName);
    final upload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('上传这份导入流程？'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('提交后由维护者审核合并；合并后其他用户可以在“已适配高校”里搜索到这所学校。\n\n只上传学校名称和课表网址；不会上传账号、密码或 Cookie。', style: TextStyle(fontSize: 11, height: 1.5)),
          const SizedBox(height: 10),
          TextField(controller: nameController, decoration: const InputDecoration(labelText: '学校名称', hintText: '例如：某某大学', isDense: true)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('暂不上传')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('上传')),
        ],
      ),
    );
    final actualName = nameController.text.trim();
    nameController.dispose();
    if (upload != true || !context.mounted) return;
    if (actualName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('学校名称不能为空')));
      return;
    }
    try {
      final pr = await FlowUploadService.upload(school: actualName, source: source);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pr == null ? '已提交导入流程' : '已提交 PR：$pr')));
    } catch (e) {
      if (!context.mounted) return;
      final networkError = e is HandshakeException || e is SocketException || e is HttpException;
      final issueUrl = Uri.https('github.com', '/chengxixian/course-table/issues/new', {
        'title': '新增高校导入流程：$actualName',
        'body': '学校：$actualName\n课表网址：${source.url}\n\n由课程表 App 提交。',
      });
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(networkError ? '上传通道连接失败' : '上传未完成'),
          content: Text(networkError
              ? '当前网络无法完成 TLS 握手，常见原因是 VPN 或网络拦截。请关闭 VPN 后重试；也可以先在 GitHub 手动提交。'
              : '$e\n\n可以复制信息后到 GitHub 提交。'),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: '${actualName}\n${source.url}'));
                Navigator.pop(ctx);
              },
              child: const Text('复制信息'),
            ),
            FilledButton(
              onPressed: () {
                launchUrl(issueUrl, mode: LaunchMode.externalApplication);
                Navigator.pop(ctx);
              },
              child: const Text('去 GitHub 提交'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _searchSchool(BuildContext context) async {
    final query = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final q = query.text.trim();
          final filtered = SchoolRegistry.schools.value.where((s) => s.name.contains(q) || s.aliases.any((a) => a.contains(q)) || s.type.contains(q)).toList();
          return AlertDialog(
            title: Text('搜索已适配高校（${SchoolRegistry.schools.value.length}）'),
            content: SizedBox(
              width: 360,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: query,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '输入高校名称', prefixIcon: Icon(Icons.search)),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Padding(padding: EdgeInsets.all(16), child: Text('没有匹配的高校'))
                else
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final school = filtered[i];
                        return ListTile(
                          title: Text(school.name),
                          subtitle: Text(school.note),
                          onTap: () {
                            Navigator.pop(ctx);
                            if (school.native) {
                              onLogin();
                            } else {
                              _importWeb(context, initialUrl: school.loginUrl, schoolName: school.name);
                            }
                          },
                        );
                      },
                    ),
                  ),
              ]),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
          );
        },
      ),
    );
    query.dispose();
  }

  Future<void> _clearAllCourses(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有课程信息？'),
        content: const Text('会删除本机课表、网页导入源和小组件显示，保留登录账号，之后可重新同步。此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清除')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await controller.clearAllCourses();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('课程信息已清除')));
  }

  Future<void> _sync(BuildContext context) async {
    await controller.sync();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(controller.error == null ? '课表已同步' : '同步失败：${controller.error}')));
  }


  Future<void> _importAll(BuildContext context) async {
    final schedule = controller.schedule;
    if (schedule == null) return;
    if (!Platform.isAndroid) {
      try {
        final path = await CalendarExport.saveIcs(schedule, controller.settings.durationMode);
        await CalendarExport.openGoogleImport();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导出全部课程：$path\n在 Google 日历导入页选择该文件即可。')));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
      return;
    }
    try {
      final result = await GoogleCalendarImport.importAll(schedule, controller.settings.durationMode);
      if (!context.mounted) return;
      final skipped = result.skipped > 0 ? '，跳过 ${result.skipped} 个已存在事件' : '';
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        content: Text('已写入 ${result.inserted} 个课程事件到 ${result.calendarName}$skipped。'),
      ));
    } on CalendarPermissionException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('未导入：${e.message}')));
    } on NoWritableCalendarException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败：$e')));
    }
  }

  Future<void> _shareAll(BuildContext context) async {
    try {
      final schedule = controller.schedule;
      if (schedule == null) return;
      final count = await CalendarExport.shareAll(schedule, controller.settings.durationMode);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已生成 $count 个课程事件（全部课程），请选择 Google 日历。')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }

  Future<void> _pickTime(BuildContext context, AppSettings settings) async {
    final parts = settings.refreshTime.split(':');
    final initial = TimeOfDay(hour: int.tryParse(parts.first) ?? 7, minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 30);
    final picked = await showTimePicker(context: context, initialTime: initial, helpText: '每天自动同步时间');
    if (picked == null) return;
    final text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await controller.updateSettings(settings.copyWith(refreshTime: text));
  }

  Future<void> _enterCompact(BuildContext context) async {
    if (!Platform.isWindows) return;
    await controller.setCompactMode(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setSize(const Size(400, 620));
    await windowManager.center();
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  _Fact({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 8.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.3)),
    ]);
  }
}

class _AboutRow extends StatelessWidget {
  final String label;
  final String value;
  _AboutRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

