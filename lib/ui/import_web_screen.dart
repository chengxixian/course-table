import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:m3e_core/m3e_core.dart';
import '../ai_import_service.dart';
import '../ai_nav_service.dart';

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
  bool _aiBusy = false;
  String _aiStatus = 'AI 正在识别课表…';
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
      final html = _decodeJs(raw);
      if (html.isEmpty) throw const FormatException('页面内容为空');
      final url = await web.currentUrl() ?? _url.text;
      final cookies = <String, String>{};
      try {
        final list = await WebViewCookieManager().getCookies(domain: Uri.parse(url));
        for (final c in list) {
          cookies[c.name] = c.value;
        }
      } catch (_) {}
      var source = ImportedSource(url: url, cookies: cookies, html: html, savedAt: DateTime.now());
      var preview = parseImportedHtml(html, url);
      final host = Uri.tryParse(url)?.host ?? '';
      final missingRoom = preview != null && preview.meetings.any((m) => m.room.trim().isEmpty);
      if ((preview == null || missingRoom) && !host.contains('hsu.edu.cn')) {
        final rawText = await web.runJavaScriptReturningResult('document.body.innerText');
        final text = _decodeJs(rawText);
        if (text.trim().length >= 20) {
          setState(() => _aiBusy = true);
          try {
            final aiSource = await AiImportService.parse(text: text, url: url, cookies: cookies);
            final aiPreview = parseImportedHtml(aiSource.html, url);
            if (aiPreview != null) {
              source = aiSource;
              preview = aiPreview;
            }
          } finally {
            if (mounted) setState(() => _aiBusy = false);
          }
        }
      }
      if (preview == null) {
        throw FormatException(host.contains('hsu.edu.cn')
            ? '黄山学院请使用已适配高校入口，不要从未适配网页导入。'
            : (lastParseError ?? '没有在当前页面识别到课表'));
      }
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('导入这份课表？'),
          content: Text('识别到 ${preview!.courses.length} 门课程、${preview.meetings.length} 个上课时段。\n\n导入后会保存当前页面地址和本地登录状态，用于以后刷新；页面文本可能发送到 AI 识别服务，但不会发送账号密码或 Cookie。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('再看看')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('确定导入')),
          ],
        ),
      );
      if (ok == true && mounted) Navigator.of(context).pop(source);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('FormatException: ', '').replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _decodeJs(Object? raw) {
    var value = raw?.toString() ?? '';
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      try {
        value = jsonDecode(value) as String;
      } catch (_) {
        value = value.substring(1, value.length - 1);
      }
    }
    return value;
  }

  Future<String> _pageText() async {
    final raw = await _web?.runJavaScriptReturningResult('document.body.innerText');
    return _decodeJs(raw);
  }

  Future<bool> _clickNextWeek() async {
    final raw = await _web?.runJavaScriptReturningResult(r'''(() => {
      const all = [...document.querySelectorAll('a,button,[role=button],li,span,select')]
        .filter(e => { const r = e.getBoundingClientRect(); return r.width > 4 && r.height > 4; })
        .slice(0, 80);
      window.__aiNavNodes = all;
      all.forEach((e, i) => e.setAttribute('data-ai-nav', String(i)));
      return JSON.stringify(all.map((e, i) => ({
        index: i,
        tag: e.tagName,
        type: e.getAttribute('type') || '',
        text: (e.innerText || e.value || '').trim().slice(0, 80),
        aria: e.getAttribute('aria-label') || '',
        title: e.getAttribute('title') || '',
      })));
    })()''');
    final text = _decodeJs(raw);
    var decoded = <Map<String, dynamic>>[];
    try {
      final list = jsonDecode(text);
      if (list is List) decoded = list.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
    } catch (_) {}
    final pageText = await _pageText();
    final index = await AiNavService.nextIndex(text: pageText, controls: decoded);
    if (index >= 0) {
      await _web?.runJavaScriptReturningResult('window.__aiNavNodes?.[$index]?.click(); true');
      return true;
    }
    final fallback = await _web?.runJavaScriptReturningResult(r'''(() => {
      const all = [...document.querySelectorAll('a,button,[role=button],li,span')];
      const el = all.find(e => /涓嬩竴鍛▅涓嬪懆|鍚庝竴鍛▅\u203a|\u2192/.test((e.innerText || '').trim()));
      if (el) { el.click(); return true; }
      return false;
    })()''');
    return fallback?.toString().contains('true') ?? false;
  }

  Future<void> _importSemester() async {
    const total = 20;
    final web = _web;
    if (web == null) return;
    setState(() { _aiBusy = true; _aiStatus = '正在读取第 1 周…'; _error = null; });
    try {
      final chunks = <String>[];
      var reached = 1;
      for (var week = 1; week <= total; week++) {
        if (!mounted) return;
        setState(() => _aiStatus = '正在读取第 $week 周…');
        final text = await _pageText();
        if (text.trim().isNotEmpty) chunks.add('--- 第$week周 ---\n$text');
        reached = week;
        if (week == total) break;
        final moved = await _clickNextWeek();
        if (!moved) break;
        await Future<void>.delayed(const Duration(milliseconds: 1400));
      }
      if (chunks.isEmpty) throw const FormatException('没有读取到页面文本');
      final url = await web.currentUrl() ?? _url.text;
      final cookies = <String, String>{};
      try {
        final list = await WebViewCookieManager().getCookies(domain: Uri.parse(url));
        for (final c in list) cookies[c.name] = c.value;
      } catch (_) {}
      setState(() => _aiStatus = 'AI 正在合并 $reached 周课表…');
      final source = await AiImportService.parse(text: chunks.join('\n'), url: url, cookies: cookies);
      final preview = parseImportedHtml(source.html, url);
      if (preview == null) throw FormatException(lastParseError ?? 'AI 合并失败');
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('导入整学期课表？'),
          content: Text('读取到 $reached 周，识别 ${preview.courses.length} 门课程、${preview.meetings.length} 个时段。\n\n只保存识别后的课表，不会上传 Cookie/密码。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('再看看')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('导入')),
          ],
        ),
      );
      if (ok == true && mounted) Navigator.of(context).pop(source);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('FormatException: ', '').replaceFirst('StateError: ', ''));
    } finally {
      if (mounted) setState(() => _aiBusy = false);
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
      body: Stack(children: [
        Column(children: [
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
                    onPressed: _loading || _aiBusy ? null : _importSemester,
                    icon: Icon(PixelIcons.event_available_outlined, size: 18),
                    label: const Text('读取当前页面并导入'),
                  ),
                ),

                Text('请先登录并切到第 1 周；点击后 AI 会自动翻周、识别并合并整学期课表。登录状态只保存在本机。',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, color: scheme.onSurfaceVariant)),
              ]),
            ),
          ),
        ],
        ]),
        if (_aiBusy)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(22)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const M3ELoadingIndicator(constraints: BoxConstraints.tightFor(width: 44, height: 44)),
                    const SizedBox(height: 12),
                    Text(_aiStatus, style: TextStyle(fontSize: 11)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

