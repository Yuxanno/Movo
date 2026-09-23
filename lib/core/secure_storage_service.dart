import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Сервис для работы с чувствительными данными (PIN-код и др.).
///
/// Использует [FlutterSecureStorage], который на Android шифрует данные
/// через EncryptedSharedPreferences (AES-256), на iOS — через Keychain Services.
///
/// Используется как набор статических методов — не нужен экземпляр класса.
class SecureStorageService {
  // Приватный конструктор — класс не предназначен для инстанцирования.
  SecureStorageService._();

  /// Единственный экземпляр хранилища.
  /// AndroidOptions — гарантирует использование EncryptedSharedPreferences.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    webOptions: WebOptions(
      dbName: 'movo_secure_storage',
      publicKey: 'movo_public_key',
    ),
  );

  // ── Ключи хранилища ────────────────────────────────────────────────────────
  static const _keyPin = 'secure_pin_code';
  static const _keyJwtToken = 'secure_jwt_token';

  // ── PIN-код ────────────────────────────────────────────────────────────────

  /// Сохраняет PIN-код в зашифрованное хранилище.
  /// Перезаписывает предыдущее значение, если оно было.
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _keyPin, value: pin);
  }

  /// Читает PIN-код из зашифрованного хранилища.
  /// Возвращает [null], если PIN не был задан.
  static Future<String?> getPin() async {
    return _storage.read(key: _keyPin);
  }

  /// Удаляет PIN-код из хранилища (при отключении блокировки или logout).
  static Future<void> deletePin() async {
    await _storage.delete(key: _keyPin);
  }

  // ── JWT-токен ────────────────────────────────────────────────────────────────

  /// Сохраняет JWT-токен в зашифрованное хранилище.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyJwtToken, value: token);
  }

  /// Читает JWT-токен из зашифрованного хранилища.
  static Future<String?> getToken() async {
    return _storage.read(key: _keyJwtToken);
  }

  /// Удаляет JWT-токен из хранилища (при logout).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyJwtToken);
  }
}
