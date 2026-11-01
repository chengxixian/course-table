import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';

import '../app_controller.dart';
import '../file_import_service.dart';
import '../imported_source.dart';
import 'manual_course_dialog.dart';

class ImportFileScreen extends StatefulWidget {
  final AppController controller;
  const ImportFileScreen({super.key, required this.controller});
  @override
  State<ImportFileScreen> createState() => _ImportFileScreenState();
}

class _ImportFileScreenState extends State<ImportFileScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _pick(List<String> extensions) async {
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: extensions);
    final file = picked.firstOrNull;
    if (file == null) return;
    await _run(() => FileImportService.importFile(file));
  }

  Future<void> _run(Future<ImportedSource> Function() task) async {
    setState(() { _busy = true; _error = null; });
    try {
      final source = await task();
      if (!mounted) return;
      Navigator.of(context).pop(source);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('FormatException: ', '').replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pasteText() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('粘贴课表文本'),
        content: SizedBox(
          width: 420,
          child: TextField(controller: controller, maxLines: 10, decoration: const InputDecoration(hintText: '把课表文字粘贴到这里，AI 会负责识别')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('导入')),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty) return;
    await _run(() => FileImportService.fromPastedText(text));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('文件导入课表')),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.all(16), children: [
          Text('支持从已有课表文件导入。Excel/PDF 会先提取文字，再交给 AI 解析；不上传原始文件。', style: TextStyle(fontSize: 11, height: 1.5, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          _option(context, Icons.event_note_outlined, 'ICS 日历文件', 'Apple/Google/Outlook 导出的 .ics', () => _pick(['ics'])),
          _option(context, Icons.table_chart_outlined, 'CSV 表格', '逗号分隔的课表文件', () => _pick(['csv'])),
          _option(context, Icons.grid_on_outlined, 'Excel 表格', '.xlsx / .xls', () => _pick(['xlsx', 'xls'])),
          _option(context, Icons.picture_as_pdf_outlined, 'PDF 课表', '文本型 PDF；扫描图片版无法提取', () => _pick(['pdf'])),
          _option(context, Icons.notes_outlined, '纯文本', '从网页/通知里复制出来的课表文字', _pasteText),
          _option(context, Icons.edit_outlined, '手动添加一门课', '表单录入课程、星期、节次', () async {
            await showManualCourseDialog(context, widget.controller);
            if (context.mounted) Navigator.of(context).pop();
          }),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: TextStyle(fontSize: 10, color: scheme.onErrorContainer)),
            ),
          ],
        ]),
        if (_busy) Positioned.fill(child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(22)),
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              M3ELoadingIndicator(constraints: BoxConstraints.tightFor(width: 42, height: 42)),
              SizedBox(height: 12),
              Text('正在解析文件…', style: TextStyle(fontSize: 11)),
            ]),
          )),
        )),
      ]),
    );
  }

  Widget _option(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: _busy ? null : onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: scheme.surfaceContainerLow,
        leading: CircleAvatar(backgroundColor: scheme.primaryContainer, child: Icon(icon, size: 21, color: scheme.onPrimaryContainer)),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right, size: 19),
      ),
    );
  }
}
