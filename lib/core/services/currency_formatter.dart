/// Formats a numeric value using a currency code with thousands grouping.
///
/// This is the single reusable currency-formatting path for the application.
/// It is deliberately dependency-free (no `intl`) and follows the app's
/// established `<code> <value>` convention (e.g. `PKR 125,000`), so it can be
/// reused later by garment price, wardrobe value, cost-per-wear, outfit value
/// and any other financial metric without duplicating formatting logic.
class CurrencyFormatter {
  const CurrencyFormatter(this.currencyCode);

  /// ISO 4217 currency code, e.g. `PKR`.
  final String currencyCode;

  /// Formats [number] as `<currencyCode> <grouped-integer>`, rounding to whole
  /// units. Example: `125000` → `PKR 125,000`.
  String format(num? number) {
    if (number == null) {
      return '—';
    }
    return '$currencyCode ${_groupThousands(number)}';
  }

  /// Rounds to whole units then inserts comma thousands separators. A negative
  /// sign (if any) is preserved before the first group.
  static String _groupThousands(num number) {
    final int rounded = number.round();
    final bool negative = rounded < 0;
    final String digits = rounded.abs().toString();

    final StringBuffer buffer = StringBuffer();
    final int length = digits.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }

    return negative ? '-$buffer' : buffer.toString();
  }
}