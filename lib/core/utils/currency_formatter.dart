import 'package:intl/intl.dart';

class CurrencyFormatter {
  static const Map<String, String> currencySymbols = {
    'UZS': 'сўм',
    'USD': '\$',
    'RUB': '₽',
  };

  static const Map<String, int> currencyDecimals = {
    'UZS': 0,
    'USD': 2,
    'RUB': 2,
  };

  /// Format currency amount with proper symbol and decimals
  static String format(double amount, String currency) {
    final decimals = currencyDecimals[currency] ?? 2;
    final symbol = currencySymbols[currency] ?? currency;

    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: decimals,
    );

    final formattedAmount = formatter.format(amount.abs());
    final prefix = amount < 0 ? '-' : '';

    return '$prefix$formattedAmount $symbol';
  }

  /// Format currency for display in cards (compact)
  static String formatCompact(double amount, String currency) {
    final decimals = currencyDecimals[currency] ?? 2;

    if (amount.abs() >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(1)}M ${currencySymbols[currency] ?? currency}';
    } else if (amount.abs() >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(0)}K ${currencySymbols[currency] ?? currency}';
    }

    return format(amount, currency);
  }

  /// Parse amount from string input
  static double? parseAmount(String input) {
    try {
      return double.parse(input.replaceAll(',', '.'));
    } catch (e) {
      return null;
    }
  }

  /// Get currency symbol
  static String getSymbol(String currency) {
    return currencySymbols[currency] ?? currency;
  }
}

/// Extension on double for easy currency formatting
extension CurrencyExtension on double {
  String toCurrency(String currency) => CurrencyFormatter.format(this, currency);
  String toCurrencyCompact(String currency) =>
      CurrencyFormatter.formatCompact(this, currency);
}
