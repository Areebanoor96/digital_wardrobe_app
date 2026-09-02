import 'package:digital_wardrobe_app/core/services/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const CurrencyFormatter pkr = CurrencyFormatter('PKR');

  group('CurrencyFormatter.format', () {
    test('prepends the currency code', () {
      expect(pkr.format(1500), 'PKR 1,500');
    });

    test('groups thousands with commas', () {
      expect(pkr.format(125000), 'PKR 125,000');
      expect(pkr.format(1000000), 'PKR 1,000,000');
      expect(pkr.format(999), 'PKR 999');
      expect(pkr.format(1000), 'PKR 1,000');
    });

    test('rounds to whole units', () {
      expect(pkr.format(199.6), 'PKR 200');
      expect(pkr.format(199.4), 'PKR 199');
    });

    test('preserves negative sign', () {
      expect(pkr.format(-5000), 'PKR -5,000');
    });

    test('returns dash for null', () {
      expect(pkr.format(null), '—');
    });

    test('supports multiple currency codes', () {
      const CurrencyFormatter usd = CurrencyFormatter('USD');
      const CurrencyFormatter gbp = CurrencyFormatter('GBP');
      expect(usd.format(125000), 'USD 125,000');
      expect(gbp.format(125000), 'GBP 125,000');
    });
  });
}