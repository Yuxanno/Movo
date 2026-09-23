import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../api_service.dart';
import '../../core/secure_storage_service.dart';

/// Отвечает только за: авторизацию, JWT-токен, профиль пользователя.
/// Ничего не знает о транзакциях, счетах и прочих данных.
class AuthStore extends ChangeNotifier {
  final ApiService api;

  AuthStore(this.api);

  // ── Состояние ─────────────────────────────────────────────────────────
  String? userId;
  String? userName;
  String? userLogin;

  bool get isLoggedIn => userId != null;

  // ── Ключи SharedPreferences ───────────────────────────────────────────
  static const _keyUser  = 'movo_user';
  static const _keyToken = 'movo_token';

  // ── Пользователь ─────────────────────────────────────────────────────

  void setUser(String? id, {String? name, String? login}) {
    userId   = id;
    userName = name;
    userLogin = login;
    notifyListeners();
  }

  Future<void> saveUserToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    try { return jsonDecode(raw) as Map<String, dynamic>; } catch (_) { return null; }
  }

  // ── Токен ─────────────────────────────────────────────────────────────

  /// Восстанавливает токен при старте — не пишет в prefs повторно.
  void restoreToken(String token) => api.setToken(token);

  /// Сохраняет JWT в зашифрованное хранилище и передаёт в ApiService.
  Future<void> saveToken(String token) async {
    await SecureStorageService.saveToken(token);
    api.setToken(token);
  }

  static Future<String?> loadTokenFromPrefs() async {
    return await SecureStorageService.getToken();
  }

  Future<void> _clearToken() async {
    await SecureStorageService.deleteToken();
    api.setToken(null);
  }

  // ── Logout ────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    setUser(null);
  }
}
