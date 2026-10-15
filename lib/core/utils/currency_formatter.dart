import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;
  final String flag;
  final bool symbolOnLeft;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
    required this.flag,
    this.symbolOnLeft = true,
  });
}

class CurrencyFormatter {
  static const String defaultCurrencyCode = 'LKR';

  static final Map<String, CurrencyInfo> supportedCurrencies = {
    'LKR': const CurrencyInfo(code: 'LKR', symbol: 'Rs.', name: 'Sri Lankan Rupee', flag: '🇱🇰'),
    'USD': const CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar', flag: '🇺🇸'),
    'EUR': const CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro', flag: '🇪🇺'),
    'GBP': const CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound', flag: '🇬🇧'),
    'INR': const CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee', flag: '🇮🇳'),
    'AUD': const CurrencyInfo(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar', flag: '🇦🇺'),
    'CAD': const CurrencyInfo(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar', flag: '🇨🇦'),
    'SGD': const CurrencyInfo(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar', flag: '🇸🇬'),
    'AED': const CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE Dirham', flag: '🇦🇪'),
    'JPY': const CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen', flag: '🇯🇵'),
  };

  /// Formats amount into standard currency string like: "Rs. 1,450.00" or masks if [isMasked] is true
  static String format(
    double amount, {
    String currencyCode = defaultCurrencyCode,
    bool isMasked = false,
    bool showSign = false,
    int decimalDigits = 2,
  }) {
    if (isMasked) {
      final info = supportedCurrencies[currencyCode] ?? supportedCurrencies[defaultCurrencyCode]!;
      return '${info.symbol} ••••••';
    }

    final info = supportedCurrencies[currencyCode] ?? supportedCurrencies[defaultCurrencyCode]!;
    final isNegative = amount < 0;
    final absAmount = amount.abs();

    final numberFormat = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
    );
    final formattedNumber = numberFormat.format(absAmount).trim();

    String result;
    if (info.symbolOnLeft) {
      result = '${info.symbol} $formattedNumber';
    } else {
      result = '$formattedNumber ${info.symbol}';
    }

    if (isNegative) {
      return '-$result';
    } else if (showSign && amount > 0) {
      return '+$result';
    }
    return result;
  }

  /// Compact formatting e.g. "Rs. 1.2M" or "Rs. 45.2K"
  static String formatCompact(
    double amount, {
    String currencyCode = defaultCurrencyCode,
    bool isMasked = false,
  }) {
    if (isMasked) return '••••';
    final info = supportedCurrencies[currencyCode] ?? supportedCurrencies[defaultCurrencyCode]!;
    final compactFormat = NumberFormat.compact();
    return '${info.symbol} ${compactFormat.format(amount)}';
  }

  static CurrencyInfo getCurrencyInfo(String code) {
    return supportedCurrencies[code] ?? supportedCurrencies[defaultCurrencyCode]!;
  }
}
