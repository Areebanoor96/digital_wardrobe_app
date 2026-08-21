import 'package:digital_wardrobe_app/data/models/garment_color.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GarmentColorPalette', () {
    test('exposes all requested color families', () {
      final List<String> familyNames = GarmentColorPalette.families
          .map((GarmentColorFamily family) => family.name)
          .toList();

      expect(familyNames, contains('Black / Gray / White'));
      expect(familyNames, contains('Brown / Beige'));
      expect(familyNames, contains('Red'));
      expect(familyNames, contains('Orange'));
      expect(familyNames, contains('Yellow'));
      expect(familyNames, contains('Green'));
      expect(familyNames, contains('Blue'));
      expect(familyNames, contains('Purple'));
      expect(familyNames, contains('Pink'));
    });

    test('includes the required clothing shades', () {
      final List<String> names = GarmentColorPalette.allOptions
          .map((GarmentColorOption option) => option.name)
          .toList();

      for (final String required in <String>[
        'Navy',
        'Royal Blue',
        'Sky Blue',
        'Baby Blue',
        'Burgundy',
        'Maroon',
        'Olive',
        'Sage',
        'Emerald',
        'Cream',
        'Camel',
        'Tan',
        'Charcoal',
      ]) {
        expect(names, contains(required), reason: '$required is missing');
      }
    });

    test('every shade has a non-empty name and a valid #RRGGBB hex', () {
      for (final GarmentColorOption option
          in GarmentColorPalette.allOptions) {
        expect(option.name.trim(), isNotEmpty);

        expect(option.hex, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
      }
    });

    test('shade names are unique across the whole palette', () {
      final List<String> names = GarmentColorPalette.allOptions
          .map((GarmentColorOption option) => option.name.toLowerCase())
          .toList();

      expect(names.toSet().length, names.length);
    });

    test('tryFindByName matches case-insensitively and trims input', () {
      expect(GarmentColorPalette.tryFindByName('navy')?.hex, '#000080');
      expect(
        GarmentColorPalette.tryFindByName('  ROYAL BLUE ')?.name,
        'Royal Blue',
      );
    });

    test('tryFindByName returns null for unknown or empty values', () {
      expect(GarmentColorPalette.tryFindByName(null), isNull);
      expect(GarmentColorPalette.tryFindByName(''), isNull);
      expect(GarmentColorPalette.tryFindByName('Sparkly Rainbow'), isNull);
    });
  });
}
