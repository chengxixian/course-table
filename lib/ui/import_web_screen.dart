import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../generic_html_parser.dart';
import '../imported_source.dart';
import '../pixel_icons.dart';

class ImportWebScreen extends StatefulWidget {
  final String? initialUrl;
  const ImportWebScreen({super.key, this.initialUrl});

  @override
  State<ImportWebScreen> createState() => _ImportWebScreenState();
}

class _ImportWebScreenState extends State<ImportWebScreen> {
  late final TextEditingController _url;
  WebViewController? _web;
  bool _loading = true;
  int _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.initialUrl ?? '');
    if (!Platform.isAndroid) return;
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1B1B1F))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p),
        onPageStarted: (_) => setState(() {
          _loading = true;
          _error = null;
        }),
        onPageFinished: (url) async {
          final current = await _web?.currentUrl();
          if (current != null && mounted) _url.text = current;
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (err) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            if (err.isForMainFrame == true) _error = err.description;
          });
        },
      ));
    final initial = _url.text.trim();
    if (initial.isNotEmpty) {
      _web!.loadRequest(Uri.parse(initial));
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _openUrl() async {
    final value = _url.text.trim();
    if (value.isEmpty) {
      setState(() => _error = '请先输入学校课表网页地址');
      return;
    }
    var uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      uri = Uri.tryParse('https://$value');
    }
    if (uri == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    await _web?.loadRequest(uri);
  }

  Future<void> _importCurrent() async {
    final web = _web;
    if (web == null) return;
    setState(() => _loading = true);
    try {
      final raw = await web.runJavaScriptReturningResult('document.documentElement.outerHTML');
      var html = raw?.toString() ?? '';
      if (html.length >= 2 && html.startsWith('"') && html.endsWith('"')) {
        try {
          html = jsonDecode(html) as String;
        } catch (_) {
          html = html.substring(1, html.length - 1);
        }
      }
      if (html.isEmpty) throw const FormatException('页面内容为空');
      final url = await web.currentUrl() ?? _url.text;
      final cookies = <String, String>{};
      try {
        final list = await WebViewCookieManager().getCookies(domain: Uri.parse(url));
        for (final c in list) {
          cookies[c.name] = c.value;
        }
      } catch (_) {}
      final source = ImportedSource(url: url, cookies: cookies, html: html, savedAt: DateTime.now());
      final preview = parseImportedHtml(html, url);
      if (preview == null) {
        throw FormatException(lastParseError ?? '没有在当前页面识别到课表');
      }
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('导入这份课表？'),
          content: Text('识别到 ${preview.courses.length} 门课程、${preview.meetings.length} 个上课时段。\n\n导入后会把当前页面地址和登录状态保存在本机，用于以后刷新课表；不会上传到服务器。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('再看看')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('确定导入')),
          ],
        ),
      );
      if (ok == true && mounted) Navigator.of(context).pop(source);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('FormatException: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入网页课表'),
        leading: IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(PixelIcons.chevron_left)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _url,
                style: const TextStyle(fontSize: 10),
                decoration: InputDecoration(
                  hintText: '输入学校课表网页地址',
                  prefixIcon: Icon(PixelIcons.search, size: 18),
                  isDense: true,
                ),
                onSubmitted: (_) => _openUrl(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(onPressed: _openUrl, child: const Text('打开')),
          ]),
        ),
        if (Platform.isAndroid && _url.text.trim().isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
            child: Text('先输入学校教务系统或课表网页的完整网址，点「打开」登录并操作到课表页面，再读取导入。',
                style: TextStyle(fontSize: 10, height: 1.55, color: scheme.onSurfaceVariant)),
          ),
        if (!Platform.isAndroid)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text('网页导入目前支持 Android。Windows 请使用“导入/导出 ICS”或现有教务系统同步。',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.6, color: scheme.onSurfaceVariant)),
              ),
            ),
          )
        else ...[
          if (_loading && _progress < 100)
            LinearProgressIndicator(value: _progress <= 0 ? null : _progress / 100, minHeight: 2),
          if (_error != null)
            Container(
              width: double.infinity,
              color: scheme.errorContainer,
              padding: const EdgeInsets.all(10),
              child: Text(_error!, style: TextStyle(fontSize: 9.5, color: scheme.onErrorContainer)),
            ),
          Expanded(
            child: WebViewWidget(controller: _web!),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _importCurrent,
                    icon: Icon(PixelIcons.event_available_outlined, size: 18),
                    label: const Text('读取当前页面并导入'),
                  ),
                ),
                const SizedBox(height: 5),
                Text('请先在网页里登录并操作到完整课表页面，再点上方按钮。登录状态只保存在本机。',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, color: scheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}
