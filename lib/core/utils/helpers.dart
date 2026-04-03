import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatCurrency(double amount, [String currency = 'UZS']) {
  final f = NumberFormat('#,##0', 'ru_RU');
  return '${f.format(amount.toInt())} ${_currencyLabel(currency)}';
}

String formatAmount(double amount) {
  final f = NumberFormat('#,##0', 'ru_RU');
  return f.format(amount.toInt());
}

String _currencyLabel(String c) {
  switch (c) {
    case 'UZS': return 'сум';
    case 'USD': return '\$';
    case 'RUB': return '₽';
    default: return c;
  }
}

Color parseColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  } catch (_) {
    return const Color(0xFF22c55e);
  }
}

String formatDate(DateTime d, [String lang = 'ru']) {
  try {
    return DateFormat('d MMM', lang).format(d);
  } catch (_) {
    return DateFormat('d MMM', 'en').format(d);
  }
}

String formatDateFull(DateTime d, [String lang = 'ru']) {
  try {
    return DateFormat('d MMMM y', lang).format(d);
  } catch (_) {
    return DateFormat('d MMMM y', 'en').format(d);
  }
}
