import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses country_code when present', () {
      final Profile profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-1',
        'full_name': 'Ayesha',
        'location_city': 'Karachi',
        'country_code': 'PK',
        'unused_alerts_enabled': true,
        'laundry_alerts_enabled': true,
        'ootd_alerts_enabled': true,
      });
      expect(profile.countryCode, 'PK');
    });

    test('missing country does not crash and stays null', () {
      final Profile profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-1',
        'full_name': 'Existing user',
      });
      expect(profile.countryCode, isNull);
    });

    test('null country_code stays null', () {
      final Profile profile = Profile.fromJson(<String, dynamic>{
        'id': 'user-1',
        'country_code': null,
      });
      expect(profile.countryCode, isNull);
    });
  });
}