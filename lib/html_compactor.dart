import 'dart:convert';

/// Shrinks fetched/rendered web pages down to what the parsers actually read.
///
/// Modern timetable portals inline megabytes of JavaScript, CSS and base64
/// images into the document. Two user-visible bugs came from that:
///
/// 1. `ImportedScheduleService.fetch` threw `网页内容过大` on any page over
///    6MB — a normal size for a SPA timetable page — so web import failed
///    before parsing even started.
/// 2. The AI fallback sent only the first 30k characters of `innerText`,
///    which on those pages is navigation and script noise; the timetable
///    itself sits further down and never reached the model.
///
/// Both paths now compact first and only then measure.

final RegExp _scriptBlock = RegExp(r'<script[\s\S]*?</script\s*>', caseSensitive: false);
final RegExp _styleBlock = RegExp(r'<style[\s\S]*?</style\s*>', caseSensitive: false);
final RegExp _noscriptBlock = RegExp(r'<noscript[\s\S]*?</noscript\s*>', caseSensitive: false);
final RegExp _templateBlock = RegExp(r'<template[\s\S]*?</template\s*>', caseSensitive: false);
final RegExp _commentBlock = RegExp(r'<!--[\s\S]*?-->');
final RegExp _base64Payload = RegExp(r'data:[a-zA-Z0-9/#+.\-]*;base64,[A-Za-z0-9+/=]{64,}');

/// Removes script/style/template/comment/base64 payloads from an HTML string.
///
/// Keeps table structure, attributes and text nodes — everything
/// `generic_html_parser` needs — and typically shrinks portal pages by 60–90%.
String compactHtml(String html) {
  var out = html;
  for (final block in [_scriptBlock, _styleBlock, _noscriptBlock, _templateBlock, _commentBlock]) {
    out = out.replaceAll(block, ' ');
  }
  out = out.replaceAll(_base64Payload, ' ');
  return out;
}

/// Hard ceiling after compaction; anything still larger is not a timetable page.
const int maxHtmlChars = 24 * 1024 * 1024;

final RegExp _timetableToken =
    RegExp(r'(?:周[一二三四五六日天]|星期[一二三四五六日天]|第[0-9０-９一二三四五六七八九十]+[节次]|[0-9]{1,2}[:：][0-9]{2})');

/// Picks the window of [text] with the highest timetable-token density.
///
/// Used before the AI upload: instead of the first N characters (usually page
/// chrome), send the N characters most likely to contain the timetable grid.
String pickTimetableText(String text, {int limit = 30000}) {
  if (text.length <= limit) return text;
  final step = (limit ~/ 4).clamp(2000, 15000);
  var bestStart = 0;
  var bestScore = -1;
  for (var start = 0; start < text.length; start += step) {
    final end = (start + limit).clamp(0, text.length);
    final chunk = text.substring(start, end);
    final score = _timetableToken.allMatches(chunk).length;
    if (score > bestScore) {
      bestScore = score;
      bestStart = start;
    }
    if (end == text.length) break;
  }
  return text.substring(bestStart, (bestStart + limit).clamp(0, text.length));
}

/// UTF-8 decodes a response body tolerating malformed bytes.
///
/// `utf8.decoder` throws on any invalid sequence — one bad byte in a 20MB page
/// used to fail the whole import. Replacement characters never appear inside
/// timetable cells, so this is safe for parsing.
String decodeUtf8Tolerant(List<int> bytes) => utf8.decode(bytes, allowMalformed: true);
