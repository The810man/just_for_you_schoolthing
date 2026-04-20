import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _keyHash = 'admin_pw_hash';
  static const _keySetup = 'admin_setup_done';

  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySetup) ?? false;
  }

  static Future<void> setupPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHash, _hash(password));
    await prefs.setBool(_keySetup, true);
  }

  static Future<bool> checkPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyHash) ?? '';
    return stored == _hash(password);
  }

  static Future<void> resetSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHash);
    await prefs.remove(_keySetup);
  }
}
