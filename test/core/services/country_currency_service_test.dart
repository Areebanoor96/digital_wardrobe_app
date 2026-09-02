import 'package:digital_wardrobe_app/core/services/country_currency_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const CountryCurrencyService service = CountryCurrencyService();
  const List<CountryInfo> countries = CountryCurrencyService.countries;

  group('country list', () {
    test('only includes unique country codes', () {
      final Set<String> codes = <String>{};
      for (final CountryInfo country in countries) {
        expect(codes.add(country.code), isTrue,
            reason: 'Duplicate country code: ${country.code}');
      }
    });

    test('is sorted alphabetically by name', () {
      final List<String> names = countries
          .map((CountryInfo country) => country.name)
          .toList();
      final List<String> sorted = List<String>.from(names)..sort();
      expect(names, sorted);
    });

    test('every country has a currency code and symbol', () {
      for (final CountryInfo country in countries) {
        expect(country.currencyCode, isNotEmpty,
            reason: 'Missing currency for ${country.name}');
        expect(country.currencySymbol, isNotEmpty,
            reason: 'Missing symbol for ${country.name}');
      }
    });

    test('sortedCountries matches the static list ordering', () {
      final List<String> byName = countries
          .map((CountryInfo country) => country.name)
          .toList();
      final List<String> sorted = List<String>.from(byName)..sort();
      expect(
        service.sortedCountries.map((CountryInfo c) => c.name),
        sorted,
      );
    });
  });

  group('country to currency mapping', () {
    test('Pakistan maps to PKR', () {
      final CountryInfo country = service.byCode('PK');
      expect(country.name, 'Pakistan');
      expect(country.currencyCode, 'PKR');
      expect(country.currencySymbol, '₨');
    });

    test('United States maps to USD', () {
      final CountryInfo country = service.byCode('US');
      expect(country.name, 'United States');
      expect(country.currencyCode, 'USD');
      expect(country.currencySymbol, r'$');
    });

    test('United Kingdom maps to GBP', () {
      final CountryInfo country = service.byCode('GB');
      expect(country.name, 'United Kingdom');
      expect(country.currencyCode, 'GBP');
      expect(country.currencySymbol, '£');
    });

    test('United Arab Emirates maps to AED', () {
      final CountryInfo country = service.byCode('AE');
      expect(country.name, 'United Arab Emirates');
      expect(country.currencyCode, 'AED');
    });

    test('additional representative countries map correctly', () {
      const Map<String, String> expectations = <String, String>{
        'IN': 'INR',
        'SA': 'SAR',
        'JP': 'JPY',
        'DE': 'EUR',
        'CA': 'CAD',
        'AU': 'AUD',
        'CN': 'CNY',
        'SG': 'SGD',
      };

      for (final MapEntry<String, String> entry in expectations.entries) {
        expect(service.byCode(entry.key).currencyCode, entry.value,
            reason: 'Expected ${entry.key} -> ${entry.value}');
      }
    });
  });

  group('fallback default', () {
    test('unknown or missing code falls back to Pakistan / PKR', () {
      expect(service.byCode(null).currencyCode, 'PKR');
      expect(service.byCode('').currencyCode, 'PKR');
      expect(service.byCode('ZZ').currencyCode, 'PKR');
    });

    test('formatterFor derives the currency from the country code', () {
      expect(service.formatterFor('PK').format(125000), 'PKR 125,000');
      expect(service.formatterFor('US').format(125000), 'USD 125,000');
      expect(service.formatterFor(null).format(125000), 'PKR 125,000');
    });
  });
}