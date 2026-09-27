/// Represents a currency supported by Denk.
///
/// All financial amounts in the app are stored strictly as integer minor units
/// (e.g. cents, kuruş, centimes). [minorUnitDigits] indicates how many decimal
/// places the minor unit represents (e.g. 2 for EUR, 0 for JPY).
class Currency {
  final String code;
  final String symbol;
  final String name;
  final int minorUnitDigits;
  final bool symbolOnLeft;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    this.minorUnitDigits = 2,
    this.symbolOnLeft = true,
  });

  /// Divisor to convert minor units to major units (e.g. 100 for 2 decimal places).
  int get divisor {
    int result = 1;
    for (int i = 0; i < minorUnitDigits; i++) {
      result *= 10;
    }
    return result;
  }

  /// Format an integer minor unit amount into a human-readable string.
  ///
  /// For example, `formatMinor(1250)` for TRY returns `"₺12.50"`.
  /// For JPY, `formatMinor(500)` returns `"¥500"`.
  String formatMinor(int amountMinor, {bool includeSymbol = true}) {
    final bool isNegative = amountMinor < 0;
    final int absMinor = amountMinor.abs();

    String numberStr;
    if (minorUnitDigits == 0) {
      numberStr = absMinor.toString();
    } else {
      final int major = absMinor ~/ divisor;
      final int minor = absMinor % divisor;
      final String minorStr = minor.toString().padLeft(minorUnitDigits, '0');
      numberStr = '$major.$minorStr';
    }

    if (!includeSymbol) {
      return isNegative ? '-$numberStr' : numberStr;
    }

    final String withSymbol = symbolOnLeft
        ? '$symbol$numberStr'
        : '$numberStr $symbol';
    return isNegative ? '-$withSymbol' : withSymbol;
  }

  /// Parses a user input string (e.g. "12.50" or "12,50") into integer minor units.
  ///
  /// Returns null if the input is invalid or negative.
  int? parseToMinor(String input) {
    final String clean = input.trim().replaceAll(',', '.');
    if (clean.isEmpty) return null;

    final parts = clean.split('.');
    if (parts.length > 2) return null;

    final int? major = int.tryParse(parts[0]);
    if (major == null || major < 0) return null;

    if (minorUnitDigits == 0) {
      if (parts.length > 1) return null;
      return major;
    }

    int minor = 0;
    if (parts.length == 2) {
      String fraction = parts[1];
      if (fraction.length > minorUnitDigits) {
        // Truncate to supported precision
        fraction = fraction.substring(0, minorUnitDigits);
      }
      fraction = fraction.padRight(minorUnitDigits, '0');
      final int? parsedMinor = int.tryParse(fraction);
      if (parsedMinor == null) return null;
      minor = parsedMinor;
    }

    return (major * divisor) + minor;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$code ($symbol)';

  // Supported Currencies
  static const Currency tryCurrency = Currency(
    code: 'TRY',
    symbol: '₺',
    name: 'Turkish Lira',
    minorUnitDigits: 2,
    symbolOnLeft: true,
  );

  static const Currency eurCurrency = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
    minorUnitDigits: 2,
    symbolOnLeft: false,
  );

  static const Currency usdCurrency = Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar',
    minorUnitDigits: 2,
    symbolOnLeft: true,
  );

  static const Currency gbpCurrency = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British Pound',
    minorUnitDigits: 2,
    symbolOnLeft: true,
  );

  static const Currency chfCurrency = Currency(
    code: 'CHF',
    symbol: 'CHF',
    name: 'Swiss Franc',
    minorUnitDigits: 2,
    symbolOnLeft: true,
  );

  static const Currency jpyCurrency = Currency(
    code: 'JPY',
    symbol: '¥',
    name: 'Japanese Yen',
    minorUnitDigits: 0,
    symbolOnLeft: true,
  );

  static const Currency cadCurrency = Currency(
    code: 'CAD',
    symbol: 'CA\$',
    name: 'Canadian Dollar',
    minorUnitDigits: 2,
    symbolOnLeft: true,
  );

  static const Currency audCurrency = Currency(
    code: 'AUD',
    symbol: 'AU\$',
    name: 'Australian Dollar',
    minorUnitDigits: 2,
    symbolOnLeft: true,
  );

  static const List<Currency> supportedCurrencies = [
    tryCurrency,
    eurCurrency,
    usdCurrency,
    gbpCurrency,
    chfCurrency,
    jpyCurrency,
    cadCurrency,
    audCurrency,
  ];

  static Currency fromCode(String? code) {
    if (code == null) return tryCurrency;
    final String upper = code.trim().toUpperCase();
    return supportedCurrencies.firstWhere(
      (c) => c.code == upper,
      orElse: () => Currency(
        code: upper,
        symbol: upper,
        name: upper,
        minorUnitDigits: 2,
        symbolOnLeft: false,
      ),
    );
  }
}
