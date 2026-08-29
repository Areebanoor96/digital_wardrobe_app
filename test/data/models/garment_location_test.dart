import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const List<GarmentLocation> locations = <GarmentLocation>[
    GarmentLocation(id: 'a', userId: 'u', memberId: 'm', name: 'Suitcase'),
    GarmentLocation(id: 'b', userId: 'u', memberId: 'm', name: '  Drawer  '),
  ];

  group('hasDuplicateLocationName', () {
    test('matches ignoring case', () {
      expect(hasDuplicateLocationName(locations, 'suitcase'), isTrue);
      expect(hasDuplicateLocationName(locations, 'SUITCASE'), isTrue);
    });

    test('matches ignoring surrounding whitespace', () {
      expect(hasDuplicateLocationName(locations, '  Drawer '), isTrue);
      expect(hasDuplicateLocationName(locations, 'drawer'), isTrue);
    });

    test('returns false for new names', () {
      expect(hasDuplicateLocationName(locations, 'Almirah'), isFalse);
      expect(hasDuplicateLocationName(locations, 'Shelf'), isFalse);
      expect(hasDuplicateLocationName(const <GarmentLocation>[], 'Shelf'), isFalse);
    });

    test('excludes exceptId so renaming to its own name is allowed', () {
      expect(
        hasDuplicateLocationName(locations, 'Suitcase', exceptId: 'a'),
        isFalse,
      );
      expect(
        hasDuplicateLocationName(locations, 'suitcase', exceptId: 'a'),
        isFalse,
      );
    });

    test('does not treat blank names as duplicates', () {
      expect(hasDuplicateLocationName(locations, '   '), isFalse);
      expect(hasDuplicateLocationName(locations, ''), isFalse);
    });
  });

  test('LocationNameConflict exposes a clear message', () {
    const LocationNameConflict conflict = LocationNameConflict('Suitcase');

    expect(
      conflict.message,
      'A location named "Suitcase" already exists.',
    );
    expect(conflict.toString(), conflict.message);
  });
}