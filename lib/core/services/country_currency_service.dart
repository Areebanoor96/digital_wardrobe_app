import 'package:digital_wardrobe_app/core/services/currency_formatter.dart';

/// A single, authoritative country entry used for setup selection and for
/// deriving the user's default Analytics currency.
class CountryInfo {
  const CountryInfo({
    required this.code,
    required this.name,
    required this.currencyCode,
    required this.currencySymbol,
  });

  /// ISO 3166-1 alpha-2 country code (e.g. `PK`).
  final String code;

  /// Display name (e.g. `Pakistan`).
  final String name;

  /// ISO 4217 currency code (e.g. `PKR`).
  final String currencyCode;

  /// A short currency symbol (e.g. `₨`).
  final String currencySymbol;
}

/// Centralized source of truth for the country → currency mapping.
///
/// The Setup Wizard persists only the stable ISO country [CountryInfo.code].
/// The Analytics currency code and symbol are derived here — never scattered
/// across the application. The default fallback is Pakistan (PKR), matching the
/// application's long-standing PKR garment-price convention, so existing users
/// without a stored country remain on PKR.
class CountryCurrencyService {
  const CountryCurrencyService();

  static const List<CountryInfo> countries = <CountryInfo>[
    CountryInfo(code: 'AR', name: 'Argentina', currencyCode: 'ARS', currencySymbol: r'$'),
    CountryInfo(code: 'AU', name: 'Australia', currencyCode: 'AUD', currencySymbol: r'$'),
    CountryInfo(code: 'BR', name: 'Brazil', currencyCode: 'BRL', currencySymbol: r'R$'),
    CountryInfo(code: 'CA', name: 'Canada', currencyCode: 'CAD', currencySymbol: r'$'),
    CountryInfo(code: 'CN', name: 'China', currencyCode: 'CNY', currencySymbol: '¥'),
    CountryInfo(code: 'EG', name: 'Egypt', currencyCode: 'EGP', currencySymbol: 'E£'),
    CountryInfo(code: 'FR', name: 'France', currencyCode: 'EUR', currencySymbol: '€'),
    CountryInfo(code: 'DE', name: 'Germany', currencyCode: 'EUR', currencySymbol: '€'),
    CountryInfo(code: 'IN', name: 'India', currencyCode: 'INR', currencySymbol: '₹'),
    CountryInfo(code: 'ID', name: 'Indonesia', currencyCode: 'IDR', currencySymbol: 'Rp'),
    CountryInfo(code: 'IT', name: 'Italy', currencyCode: 'EUR', currencySymbol: '€'),
    CountryInfo(code: 'JP', name: 'Japan', currencyCode: 'JPY', currencySymbol: '¥'),
    CountryInfo(code: 'MY', name: 'Malaysia', currencyCode: 'MYR', currencySymbol: 'RM'),
    CountryInfo(code: 'MA', name: 'Morocco', currencyCode: 'MAD', currencySymbol: 'د.م.'),
    CountryInfo(code: 'NL', name: 'Netherlands', currencyCode: 'EUR', currencySymbol: '€'),
    CountryInfo(code: 'NZ', name: 'New Zealand', currencyCode: 'NZD', currencySymbol: r'$'),
    CountryInfo(code: 'NG', name: 'Nigeria', currencyCode: 'NGN', currencySymbol: '₦'),
    CountryInfo(code: 'PK', name: 'Pakistan', currencyCode: 'PKR', currencySymbol: '₨'),
    CountryInfo(code: 'PH', name: 'Philippines', currencyCode: 'PHP', currencySymbol: '₱'),
    CountryInfo(code: 'PL', name: 'Poland', currencyCode: 'PLN', currencySymbol: 'zł'),
    CountryInfo(code: 'RU', name: 'Russia', currencyCode: 'RUB', currencySymbol: '₽'),
    CountryInfo(code: 'SA', name: 'Saudi Arabia', currencyCode: 'SAR', currencySymbol: '﷼'),
    CountryInfo(code: 'SG', name: 'Singapore', currencyCode: 'SGD', currencySymbol: r'$'),
    CountryInfo(code: 'ZA', name: 'South Africa', currencyCode: 'ZAR', currencySymbol: 'R'),
    CountryInfo(code: 'KR', name: 'South Korea', currencyCode: 'KRW', currencySymbol: '₩'),
    CountryInfo(code: 'ES', name: 'Spain', currencyCode: 'EUR', currencySymbol: '€'),
    CountryInfo(code: 'CH', name: 'Switzerland', currencyCode: 'CHF', currencySymbol: 'Fr'),
    CountryInfo(code: 'TH', name: 'Thailand', currencyCode: 'THB', currencySymbol: '฿'),
    CountryInfo(code: 'TR', name: 'Turkey', currencyCode: 'TRY', currencySymbol: '₺'),
    CountryInfo(code: 'AE', name: 'United Arab Emirates', currencyCode: 'AED', currencySymbol: 'د.إ'),
    CountryInfo(code: 'GB', name: 'United Kingdom', currencyCode: 'GBP', currencySymbol: '£'),
    CountryInfo(code: 'US', name: 'United States', currencyCode: 'USD', currencySymbol: r'$'),
  ];

  /// Index of the default (fallback) country used when no country is stored.
  ///
  /// Pakistan is the safe default because the application has historically
  /// stored all garment prices in PKR.
  static const CountryInfo defaultCountry = CountryInfo(
    code: 'PK',
    name: 'Pakistan',
    currencyCode: 'PKR',
    currencySymbol: '₨',
  );

  /// Countries ordered alphabetically by display name for UI lists.
  List<CountryInfo> get sortedCountries {
    final List<CountryInfo> list = List<CountryInfo>.from(countries);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Looks up a country by its ISO code. Returns [defaultCountry] when the code
  /// is unknown or missing, keeping behavior safe for existing users.
  CountryInfo byCode(String? code) {
    if (code == null || code.isEmpty) {
      return defaultCountry;
    }
    for (final CountryInfo country in countries) {
      if (country.code == code) {
        return country;
      }
    }
    return defaultCountry;
  }

  /// Convenience: derives a reusable [CurrencyFormatter] for a country code.
  CurrencyFormatter formatterFor(String? countryCode) {
    final CountryInfo country = byCode(countryCode);
    return CurrencyFormatter(country.currencyCode);
  }
}