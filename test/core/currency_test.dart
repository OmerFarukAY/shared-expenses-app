import 'package:denk/core/constants/currencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency formatting & parsing (zero floating-point math)', () {
    test('Formats TRY correctly with integer minor units', () {
      final currency = Currency.tryCurrency;
      expect(currency.formatMinor(2000), '₺20.00');
      expect(currency.formatMinor(550), '₺5.50');
      expect(currency.formatMinor(5), '₺0.05');
      expect(currency.formatMinor(0), '₺0.00');
      expect(currency.formatMinor(-400), '-₺4.00');
    });

    test('Formats EUR correctly with symbol on right', () {
      final currency = Currency.eurCurrency;
      expect(currency.formatMinor(1550), '15.50 €');
      expect(currency.formatMinor(-1200), '-12.00 €');
    });

    test('Formats 0-decimal currencies (JPY) without decimals', () {
      final currency = Currency.jpyCurrency;
      expect(currency.formatMinor(500), '¥500');
      expect(currency.formatMinor(0), '¥0');
      expect(currency.formatMinor(-350), '-¥350');
    });

    test('Parses user input string into exact integer minor units', () {
      final currency = Currency.tryCurrency;
      expect(currency.parseToMinor('20'), 2000);
      expect(currency.parseToMinor('20.00'), 2000);
      expect(currency.parseToMinor('20,50'), 2050);
      expect(currency.parseToMinor('0.75'), 75);
      expect(currency.parseToMinor('1234.56'), 123456);
      expect(currency.parseToMinor('-10'), isNull);
      expect(currency.parseToMinor('abc'), isNull);
      expect(currency.parseToMinor(''), isNull);
    });

    test('Parses JPY input correctly without decimals', () {
      final currency = Currency.jpyCurrency;
      expect(currency.parseToMinor('500'), 500);
      expect(
        currency.parseToMinor('500.50'),
        isNull,
      ); // JPY does not have decimals
    });
  });
}
