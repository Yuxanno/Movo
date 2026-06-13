import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// Глобальный ключ ScaffoldMessenger.
/// Регистрируется один раз в MaterialApp.scaffoldMessengerKey (см. main.dart).
/// Позволяет показывать SnackBar из любого места — в том числе из AppStore,
/// где нет доступа к BuildContext.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Централизованный хелпер для отображения SnackBar.
///
/// Использование из виджета (Вариант А):
///   AppSnackBar.error(context: context, message: 'Что-то пошло не так');
///
/// Использование из Store/сервиса без context (Вариант Б):
///   AppSnackBar.error(message: 'Ошибка соединения');
abstract class AppSnackBar {
  // ── Публичный API ───────────────────────────────────────────────────

  /// Показывает красный SnackBar с иконкой ошибки.
  static void error({BuildContext? context, required String message}) =>
      _show(context: context, message: message, isError: true);

  /// Показывает зелёный SnackBar с иконкой успеха.
  static void success({BuildContext? context, required String message}) =>
      _show(context: context, message: message, isError: false);

  // ── Конвертер сырых исключений в человеческий текст ────────────────

  /// Преобразует любое исключение в строку, понятную пользователю.
  /// Вызывай в catch-блоке: AppSnackBar.messageFromError(e)
  static String messageFromError(Object e) {
    // TimeoutException — запрос завис дольше API_TIMEOUT
    if (e is TimeoutException) {
      return 'Сервер не отвечает. Проверьте соединение.';
    }
    // SocketException — нет сети на уровне OS (Android/iOS)
    if (e is SocketException) {
      return 'Нет соединения с интернетом.';
    }
    // Наши собственные Exception('текст') из ApiService
    // Exception.toString() возвращает "Exception: текст" — убираем префикс
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.replaceFirst('Exception: ', '');
    }
    // Запасной вариант — не показываем системный стектрейс,
    // возвращаем нейтральное сообщение
    return 'Произошла ошибка. Попробуйте ещё раз.';
  }

  // ── Внутренняя реализация ──────────────────────────────────────────

  static void _show({
    BuildContext? context,
    required String message,
    required bool isError,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? const Color(0xFFef4444) : const Color(0xFF16a34a),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 4),
    );

    // Вариант А: есть context — используем ScaffoldMessenger.of(context).
    // Это предпочтительно внутри виджетов, потому что привязан к конкретному Scaffold.
    if (context != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return;
    }

    // Вариант Б: нет context (вызов из Store/сервиса) — используем глобальный ключ.
    // scaffoldMessengerKey должен быть передан в MaterialApp.scaffoldMessengerKey.
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
