import 'package:intl/intl.dart';

class DateFormatter {
  /// Format date like "Today", "Yesterday" or formatted date
  static String formatTransactionDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Сегодня';
    } else if (dateToCheck == yesterday) {
      return 'Вчера';
    } else {
      return DateFormat('dd MMM yyyy', 'ru_RU').format(date);
    }
  }

  /// Format time like "10:30"
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format datetime for display
  static String formatDateTime(DateTime date) {
    return '${formatTransactionDate(date)} ${formatTime(date)}';
  }

  /// Get relative time like "2 hours ago"
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} часов назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return DateFormat('dd MMM', 'ru_RU').format(date);
    }
  }

  /// Format month and year for charts
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy', 'ru_RU').format(date);
  }

  /// Get week days for charts (abbreviated)
  static String formatWeekDay(DateTime date) {
    return DateFormat('EEE', 'ru_RU').format(date);
  }
}

/// Extension on DateTime
extension DateTimeExtension on DateTime {
  String toTransactionDate() => DateFormatter.formatTransactionDate(this);
  String toTime() => DateFormatter.formatTime(this);
  String toDateTime() => DateFormatter.formatDateTime(this);
  String toRelativeTime() => DateFormatter.formatRelativeTime(this);
  String toMonthYear() => DateFormatter.formatMonthYear(this);
}
