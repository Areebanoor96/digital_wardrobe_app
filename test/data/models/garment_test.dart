import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:flutter_test/flutter_test.dart';

Garment garmentFromJson(Map<String, dynamic> json) =>
    Garment.fromJson(<String, dynamic>{...json, 'id': 'g-1', 'name': 'Kurta'});

void main() {
  group('Garment color and details mapping', () {
    test('fromJson maps secondary color and details columns', () {
      final Garment garment = garmentFromJson(<String, dynamic>{
        'category': 'top',
        'color_name': 'Navy',
        'color_hex': '#000080',
        'secondary_color_name': 'Cream',
        'secondary_color_hex': '#FFFDD0',
        'fit': 'Tailored',
        'pattern': 'Embroidered',
        'fabric_weight': 'Light',
        'sleeve_length': 'Long Sleeve',
        'details': 'Embroidered collar',
      });

      expect(garment.colorName, 'Navy');
      expect(garment.colorHex, '#000080');
      expect(garment.secondaryColorName, 'Cream');
      expect(garment.secondaryColorHex, '#FFFDD0');
      expect(garment.fit, 'Tailored');
      expect(garment.pattern, 'Embroidered');
      expect(garment.fabricWeight, 'Light');
      expect(garment.sleeveLength, 'Long Sleeve');
      expect(garment.details, 'Embroidered collar');
    });

    test('fromJson tolerates legacy rows without the new columns', () {
      final Garment garment = garmentFromJson(<String, dynamic>{
        'category': 'top',
        'color_name': 'Dark Blue',
      });

      expect(garment.colorName, 'Dark Blue');
      expect(garment.colorHex, isNull);
      expect(garment.secondaryColorName, isNull);
      expect(garment.secondaryColorHex, isNull);
      expect(garment.details, isNull);
    });

    test('toInsertJson writes the new columns', () {
      const Garment garment = Garment(
        id: 'g-1',
        name: 'Kurta',
        category: GarmentCategory.top,
        photoPaths: <String>[],
        photoUrls: <String>[],
        colorName: 'Navy',
        colorHex: '#000080',
        secondaryColorName: 'Cream',
        secondaryColorHex: '#FFFDD0',
        fit: 'Tailored',
        pattern: 'Embroidered',
        fabricWeight: 'Light',
        sleeveLength: 'Long Sleeve',
        details: 'Embroidered collar',
      );

      final Map<String, dynamic> json = garment.toInsertJson('user-1');

      expect(json['color_name'], 'Navy');
      expect(json['color_hex'], '#000080');
      expect(json['secondary_color_name'], 'Cream');
      expect(json['secondary_color_hex'], '#FFFDD0');
      expect(json['fit'], 'Tailored');
      expect(json['pattern'], 'Embroidered');
      expect(json['fabric_weight'], 'Light');
      expect(json['sleeve_length'], 'Long Sleeve');
      expect(json['details'], 'Embroidered collar');
    });

    test('toInsertJson writes nulls when colors or details are absent', () {
      const Garment garment = Garment(
        id: 'g-1',
        name: 'Kurta',
        category: GarmentCategory.top,
        photoPaths: <String>[],
        photoUrls: <String>[],
      );

      final Map<String, dynamic> json = garment.toInsertJson('user-1');

      expect(json['color_name'], isNull);
      expect(json['color_hex'], isNull);
      expect(json['secondary_color_name'], isNull);
      expect(json['secondary_color_hex'], isNull);
      expect(json['fit'], isNull);
      expect(json['pattern'], isNull);
      expect(json['fabric_weight'], isNull);
      expect(json['sleeve_length'], isNull);
      expect(json['details'], isNull);
    });

    test('copyWith preserves the new fields', () {
      const Garment garment = Garment(
        id: 'g-1',
        name: 'Kurta',
        category: GarmentCategory.top,
        photoPaths: <String>['a/b.jpg'],
        photoUrls: <String>[],
        colorName: 'Navy',
        colorHex: '#000080',
        secondaryColorName: 'Cream',
        secondaryColorHex: '#FFFDD0',
        fit: 'Tailored',
        pattern: 'Embroidered',
        fabricWeight: 'Light',
        sleeveLength: 'Long Sleeve',
        details: 'Embroidered collar',
      );

      final Garment copy = garment.copyWith(
        photoUrls: const <String>['https://example.com/a.jpg'],
      );

      expect(copy.secondaryColorName, 'Cream');
      expect(copy.secondaryColorHex, '#FFFDD0');
      expect(copy.fit, 'Tailored');
      expect(copy.pattern, 'Embroidered');
      expect(copy.fabricWeight, 'Light');
      expect(copy.sleeveLength, 'Long Sleeve');
      expect(copy.details, 'Embroidered collar');
    });
  });
}
