import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Local-only credential vault. The blob is AES-256-GCM encrypted and stored
/// in the app-private preferences (the random key lives beside it, inside the
/// same private sandbox). It is intentionally usable from a WorkManager
/// background isolate, unlike an Activity-bound MethodChannel.
class CredentialVault {
  static const _keyKey = 'vault_key';
  static const _blobKey = 'vault_blob';

  static Future<Credentials?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyB64 = prefs.getString(_keyKey);
      final blobB64 = prefs.getString(_blobKey);
      if (keyB64 == null || blobB64 == null) return null;
      final key = base64Decode(keyB64);
      final blob = base64Decode(blobB64);
      if (blob.length < 13) return null;
      final iv = Uint8List.fromList(blob.sublist(0, 12));
      final cipherText = Uint8List.fromList(blob.sublist(12));
      final cipher = GCMBlockCipher(AESEngine())
        ..init(false, AEADParameters(KeyParameter(Uint8List.fromList(key)), 128, iv, Uint8List(0)));
      final plain = cipher.process(cipherText);
      final obj = jsonDecode(utf8.decode(plain)) as Map;
      final u = obj['username']?.toString() ?? '';
      final p = obj['password']?.toString() ?? '';
      return u.isEmpty || p.isEmpty ? null : Credentials(u, p);
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(Credentials credentials) async {
    final prefs = await SharedPreferences.getInstance();
    var key = prefs.getString(_keyKey);
    if (key == null) {
      key = base64Encode(_randomBytes(32));
      await prefs.setString(_keyKey, key);
    }
    final keyBytes = Uint8List.fromList(base64Decode(key));
    final iv = _randomBytes(12);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(keyBytes), 128, iv, Uint8List(0)));
    final plain = utf8.encode(jsonEncode({'username': credentials.username, 'password': credentials.password}));
    final encrypted = cipher.process(Uint8List.fromList(plain));
    final blob = Uint8List.fromList([...iv, ...encrypted]);
    await prefs.setString(_blobKey, base64Encode(blob));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_blobKey);
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }
}
