import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// 密码服务
class PasswordService {
  static const String _keyPasswordHash = 'memo_password_hash';
  static const String _keyPasswordSet = 'memo_password_set';
  static const String _defaultPassword = '123456';

  /// 检查是否已设置密码（首次需要修改）
  static Future<bool> isPasswordSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPasswordSet) ?? false;
  }

  /// 验证密码
  static Future<bool> verifyPassword(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_keyPasswordHash);
    if (storedHash == null) return input == _defaultPassword;
    return _hashPassword(input) == storedHash;
  }

  /// 设置/修改密码
  static Future<bool> setPassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPassword(newPassword);
    await prefs.setString(_keyPasswordHash, hash);
    await prefs.setBool(_keyPasswordSet, true);
    return true;
  }

  /// 用默认密码初始化
  static Future<void> initDefaultPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyPasswordHash)) {
      final hash = _hashPassword(_defaultPassword);
      await prefs.setString(_keyPasswordHash, hash);
      await prefs.setBool(_keyPasswordSet, false);
    }
  }

  /// 简单 hash（使用 SHA-256）
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}
