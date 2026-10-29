import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'models.dart';

class PortalException implements Exception {
  final String message;
  const PortalException(this.message);
  @override
  String toString() => message;
}

class PortalClient {
  static const portalHome = 'https://mwx.hsu.edu.cn/zhxy/home';
  static const loginUrl = 'https://mwx.hsu.edu.cn/sso/login?service=https%3A%2F%2Fmwx.hsu.edu.cn%2Fzhxy';
  static const userLoginUrl = 'https://mwx.hsu.edu.cn/sso/userLogin';
  static const jwxtSsoUrl = 'https://jwxt.hsu.edu.cn/sso/hsssologin';
  static const scheduleApi = 'https://jwxt.hsu.edu.cn/jwglxt/kbcx/xskbcx_cxXsgrkb.html?gnmkdm=N2151';
  static const periodsApi = 'https://jwxt.hsu.edu.cn/jwglxt/kbcx/xskbcx_cxRjc.html?gnmkdm=N2151';
  static const _aesKey = '1234567890adbcde';
  static const _aesIv = '1234567890hjlkew';
  static const _ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0';

  final _jar = _CookieJar();

  Future<RawScrape> fetch(Credentials credentials, {DateTime? now}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final loginPage = await _request(client, 'GET', Uri.parse(loginUrl));
      final execution = RegExp(r'name="execution" value="([^"]+)"').firstMatch(loginPage.body)?.group(1);
      if (execution == null) throw const PortalException('未找到统一身份认证参数，请稍后重试');
      final encrypted = _encryptPassword(credentials.password);

      final loginJson = await _request(
        client,
        'POST',
        Uri.parse(userLoginUrl),
        form: {
          'serviceUrl': loginUrl,
          'password': encrypted,
          'username': credentials.username,
          'loginCaptcha': '',
          'type': '1',
        },
        headers: {'X-Requested-With': 'XMLHttpRequest', 'Referer': loginUrl},
      );
      Map<String, dynamic> loginObj;
      try {
        loginObj = (jsonDecode(loginJson.body) as Map).cast<String, dynamic>();
      } catch (_) {
        throw const PortalException('信息门户返回了无法识别的登录结果');
      }
      if (loginObj['success'] != true) {
        if (loginObj['is_verification'] == true) {
          throw const PortalException('登录需要滑动验证，请稍后在手机浏览器完成登录');
        }
        throw PortalException(loginObj['message']?.toString() ?? '信息门户登录失败');
      }

      final formResult = await _request(
        client,
        'POST',
        Uri.parse(loginUrl),
        form: {
          'captcha': '',
          'username': credentials.username,
          'password': encrypted,
          'execution': execution,
          'loginType': 'account',
          '_eventId': 'submit',
          'geolocation': '',
        },
        headers: {'Referer': loginUrl},
      );
      if (formResult.uri.path.contains('/sso/login') && formResult.body.contains('账号登录')) {
        throw const PortalException('信息门户登录未完成，请检查学号和密码');
      }

      final jwxtHome = await _request(client, 'GET', Uri.parse(jwxtSsoUrl), headers: {'Referer': portalHome});
      if (jwxtHome.uri.path.contains('login_slogin') || jwxtHome.body.contains('统一身份认证')) {
        throw const PortalException('教务系统单点登录失败，请稍后重试');
      }
      final semesterMatch = RegExp(r'(\d{4})-(\d{4})学年\s*第?(\d)\s*学期\s*\(?(\d{4}-\d{2}-\d{2})\s*[至到\-~]\s*(\d{4}-\d{2}-\d{2})')
          .firstMatch(jwxtHome.body);
      final semesterText = semesterMatch == null
          ? ''
          : '${semesterMatch.group(1)}-${semesterMatch.group(2)}学年${semesterMatch.group(3)}学期(${semesterMatch.group(4)}至${semesterMatch.group(5)})';
      final current = now ?? DateTime.now();
      final xnm = semesterMatch?.group(1) ?? (current.month >= 8 ? current.year : current.year - 1).toString();
      final xqm = semesterMatch != null
          ? (semesterMatch.group(3) == '2' ? '12' : '3')
          : (current.month >= 8 || current.month <= 1 ? '3' : '12');

      final schedule = await _request(
        client,
        'POST',
        Uri.parse(scheduleApi),
        form: {'xnm': xnm, 'xqm': xqm, 'kzlx': 'ck', 'xsdm': '', 'kclbdm': '', 'kclxdm': ''},
        headers: {'X-Requested-With': 'XMLHttpRequest', 'Referer': jwxtHome.uri.toString()},
      );
      if (!schedule.body.trimLeft().startsWith('{')) {
        throw const PortalException('教务系统返回了非课表内容，登录可能已失效');
      }
      final scheduleObj = (jsonDecode(schedule.body) as Map).cast<String, dynamic>();
      final kb = (scheduleObj['kbList'] as List?) ?? [];
      final xqhId = kb.isNotEmpty && kb.first is Map ? (kb.first['xqh_id']?.toString() ?? '1') : '1';
      final periods = await _request(
        client,
        'POST',
        Uri.parse(periodsApi),
        form: {'xnm': xnm, 'xqm': xqm, 'xqh_id': xqhId},
        headers: {'X-Requested-With': 'XMLHttpRequest', 'Referer': jwxtHome.uri.toString()},
      );
      final xsxx = (scheduleObj['xsxx'] as Map?)?.cast<String, dynamic>() ?? const {};
      final info = PortalInfo(
        name: xsxx['XM']?.toString() ?? '',
        className: xsxx['BJMC']?.toString() ?? '',
        id: xsxx['XH']?.toString() ?? xsxx['XH_ID']?.toString() ?? credentials.username,
        college: '',
      );
      return RawScrape(
        rawSchedule: scheduleObj,
        rawPeriods: jsonDecode(periods.body) as List<dynamic>,
        semesterText: semesterText,
        portalInfo: info,
        scrapedAt: DateTime.now(),
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<_Response> _request(
    HttpClient client,
    String method,
    Uri uri, {
    Map<String, String>? form,
    Map<String, String>? headers,
  }) async {
    var current = uri;
    var verb = method;
    var body = form == null ? null : form.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
    for (var redirect = 0; redirect < 10; redirect++) {
      final request = await client.openUrl(verb, current);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader, _ua);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json, text/javascript, text/html, */*; q=0.01');
      final cookie = _jar.header(current);
      if (cookie.isNotEmpty) request.headers.set(HttpHeaders.cookieHeader, cookie);
      headers?.forEach((key, value) => request.headers.set(key, value));
      if (body != null) {
        request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
        request.write(body);
      }
      final response = await request.close().timeout(const Duration(seconds: 45));
      final text = await utf8.decoder.bind(response).join();
      _jar.save(current, response.headers);
      final location = response.headers.value(HttpHeaders.locationHeader);
      if (response.statusCode >= 300 && response.statusCode < 400 && location != null) {
        current = current.resolve(location);
        if (response.statusCode == 303 || ((response.statusCode == 301 || response.statusCode == 302) && verb != 'GET')) {
          verb = 'GET';
          body = null;
        }
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PortalException('网络请求失败（HTTP ${response.statusCode}）');
      }
      return _Response(current, response.statusCode, text);
    }
    throw const PortalException('登录跳转次数过多，请稍后重试');
  }

  String _encryptPassword(String password) {
    final input = utf8.encode(password);
    final blockSize = 16;
    final paddedSize = (input.length ~/ blockSize + 1) * blockSize;
    final padded = Uint8List(paddedSize)..setRange(0, input.length, input);
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(Uint8List.fromList(utf8.encode(_aesKey))), Uint8List.fromList(utf8.encode(_aesIv))));
    final output = Uint8List(paddedSize);
    for (var offset = 0; offset < paddedSize; offset += blockSize) {
      cipher.processBlock(padded, offset, output, offset);
    }
    return base64Encode(output);
  }
}

class _Response {
  final Uri uri;
  final int status;
  final String body;
  const _Response(this.uri, this.status, this.body);
}

class _StoredCookie {
  final String name;
  final String value;
  final String domain;
  final String path;
  final bool secure;
  const _StoredCookie(this.name, this.value, this.domain, this.path, this.secure);
}

class _CookieJar {
  final Map<String, _StoredCookie> _cookies = {};

  void save(Uri uri, HttpHeaders headers) {
    headers.forEach((name, values) {
      if (name.toLowerCase() != 'set-cookie') return;
      for (final line in values) {
        final parts = line.split(';');
        if (parts.isEmpty) continue;
        final eq = parts.first.indexOf('=');
        if (eq <= 0) continue;
        final cookieName = parts.first.substring(0, eq).trim();
        final value = parts.first.substring(eq + 1).trim();
        var domain = uri.host;
        var path = '/';
        var secure = false;
        for (final attr in parts.skip(1)) {
          final a = attr.trim();
          final idx = a.indexOf('=');
          final key = (idx < 0 ? a : a.substring(0, idx)).trim().toLowerCase();
          final v = idx < 0 ? '' : a.substring(idx + 1).trim();
          if (key == 'domain' && v.isNotEmpty) domain = v.replaceFirst(RegExp(r'^\.'), '');
          if (key == 'path' && v.isNotEmpty) path = v;
          if (key == 'secure') secure = true;
        }
        _cookies['${domain.toLowerCase()}|$path|$cookieName'] = _StoredCookie(cookieName, value, domain.toLowerCase(), path, secure);
      }
    });
  }

  String header(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.isEmpty ? '/' : uri.path;
    final values = <String>[];
    for (final c in _cookies.values) {
      final hostMatch = host == c.domain || host.endsWith('.${c.domain}');
      if (!hostMatch) continue;
      if (!path.startsWith(c.path)) continue;
      if (c.secure && uri.scheme != 'https') continue;
      values.add('${c.name}=${c.value}');
    }
    return values.join('; ');
  }
}
