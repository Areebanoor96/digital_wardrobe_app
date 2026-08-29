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
        'size': '3-4Y',
        'created_at': '2026-05-10T08:30:00.000Z',
      });

      expect(garment.colorName, 'Dark Blue');
      expect(garment.colorHex, isNull);
      expect(garment.secondaryColorName, isNull);
      expect(garment.secondaryColorHex, isNull);
      expect(garment.details, isNull);
      expect(garment.availabilityStatus, GarmentAvailabilityStatus.available);
      expect(garment.ironingStatus, isNull);
      expect(garment.stitchingStatus, isNull);
      expect(garment.effectiveSizes, <String>['3-4Y']);
      expect(garment.createdAt, DateTime.parse('2026-05-10T08:30:00.000Z'));
    });

    test('fromJson maps garment management columns and normalized sizes', () {
      final Garment garment = garmentFromJson(<String, dynamic>{
        'category': 'outerwear',
        'subcategory': 'Coat',
        'availability_status': 'in_storage',
        'ironing_status': 'needs_ironing',
        'stitching_status': 'stitched',
        'location_id': 'location-1',
        'garment_locations': <String, dynamic>{'name': 'Suitcase'},
        'garment_sizes': <Map<String, dynamic>>[
          <String, dynamic>{'size': 'M', 'sort_order': 1},
          <String, dynamic>{'size': 'S', 'sort_order': 0},
          <String, dynamic>{'size': 's', 'sort_order': 2},
        ],
      });

      expect(garment.subcategory, 'Coat');
      expect(garment.availabilityStatus, GarmentAvailabilityStatus.inStorage);
      expect(garment.ironingStatus, IroningStatus.needsIroning);
      expect(garment.stitchingStatus, StitchingStatus.stitched);
      expect(garment.locationId, 'location-1');
      expect(garment.locationName, 'Suitcase');
      expect(garment.effectiveSizes, <String>['S', 'M']);
    });

    test('fromJson treats a null location embed as unspecified', () {
      final Garment garment = garmentFromJson(<String, dynamic>{
        'category': 'top',
        'garment_locations': null,
      });

      expect(garment.locationId, isNull);
      expect(garment.locationName, isNull);
    });

    test('fromJson falls back to a legacy location_name column', () {
      final Garment garment = garmentFromJson(<String, dynamic>{
        'category': 'top',
        'location_name': 'Old Shelf',
      });

      expect(garment.locationId, isNull);
      expect(garment.locationName, 'Old Shelf');
    });

    test('fromJson uses designated primary garment color shade', () {
      final Garment garment = garmentFromJson(<String, dynamic>{
        'category': 'top',
        'color_name': 'Legacy Navy',
        'color_hex': '#000080',
        'garment_color_shades': <Map<String, dynamic>>[
          <String, dynamic>{
            'color_name': 'Cream',
            'color_hex': '#FFFDD0',
            'is_primary': false,
          },
          <String, dynamic>{
            'color_name': 'Burgundy',
            'color_hex': '#800020',
            'is_primary': true,
          },
        ],
      });

      expect(garment.colorName, 'Burgundy');
      expect(garment.colorHex, '#800020');
      expect(garment.secondaryColorName, 'Cream');
      expect(garment.colorShades.length, 2);
      expect(garment.primaryShade?.name, 'Burgundy');
      expect(garment.colorNames, containsAll(<String>['burgundy', 'cream']));
    });

    test('fromJson preserves garment color shade sort order', () {
      final Garment garment = garmentFromJson(<String, dynamic>{
        'category': 'top',
        'garment_color_shades': <Map<String, dynamic>>[
          <String, dynamic>{
            'color_name': 'Cream',
            'color_hex': '#FFFDD0',
            'is_primary': false,
            'sort_order': 1,
          },
          <String, dynamic>{
            'color_name': 'Navy',
            'color_hex': '#000080',
            'is_primary': true,
            'sort_order': 0,
          },
        ],
      });

      expect(
        garment.colorShades.map((GarmentColorShade shade) => shade.name),
        <String>['Navy', 'Cream'],
      );
      expect(garment.primaryShade?.name, 'Navy');
    });

    test('shade insert json includes authenticated user id and sort order', () {
      const GarmentColorShade shade = GarmentColorShade(
        name: 'Navy',
        hex: '#000080',
        isPrimary: true,
      );

      final Map<String, dynamic> json = shade.toJson(
        userId: 'auth-user-1',
        garmentId: 'garment-1',
        sortOrder: 2,
      );

      expect(json['user_id'], 'auth-user-1');
      expect(json['garment_id'], 'garment-1');
      expect(json['color_name'], 'Navy');
      expect(json['color_hex'], '#000080');
      expect(json['is_primary'], isTrue);
      expect(json['sort_order'], 2);
    });

    test('normalizes selected shades to exactly one primary', () {
      final List<GarmentColorShade> normalized = normalizeColorShades(
        const <GarmentColorShade>[
          GarmentColorShade(name: 'Navy', hex: '#000080'),
          GarmentColorShade(name: 'Cream', hex: '#FFFDD0'),
        ],
      );

      expect(normalized.length, 2);
      expect(normalized.where((GarmentColorShade shade) => shade.isPrimary), hasLength(1));
      expect(normalized.first.isPrimary, isTrue);
    });

    test('primary shade can change and remains single', () {
      final List<GarmentColorShade> normalized = normalizeColorShades(
        const <GarmentColorShade>[
          GarmentColorShade(name: 'Navy', hex: '#000080'),
          GarmentColorShade(name: 'Cream', hex: '#FFFDD0', isPrimary: true),
        ],
      );

      expect(normalized.where((GarmentColorShade shade) => shade.isPrimary), hasLength(1));
      expect(normalized.singleWhere((GarmentColorShade shade) => shade.isPrimary).name, 'Cream');
    });

    test('removing primary makes another selected shade primary', () {
      final List<GarmentColorShade> normalized = normalizeColorShades(
        const <GarmentColorShade>[
          GarmentColorShade(name: 'Cream', hex: '#FFFDD0'),
        ],
      );

      expect(normalized.single.isPrimary, isTrue);
      expect(normalized.single.name, 'Cream');
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
        size: 'Legacy Size',
        sizes: <String>['S', 'M'],
        availabilityStatus: GarmentAvailabilityStatus.lent,
        ironingStatus: IroningStatus.ironed,
        stitchingStatus: StitchingStatus.unstitched,
        locationId: 'location-1',
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
      expect(json['size'], 'S');
      expect(json['availability_status'], 'lent');
      expect(json['ironing_status'], 'ironed');
      expect(json['stitching_status'], 'unstitched');
      expect(json['location_id'], 'location-1');
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

    test('availability status marks only available and borrowed as wearable', () {
      expect(GarmentAvailabilityStatus.available.isPhysicallyAvailable, isTrue);
      expect(GarmentAvailabilityStatus.borrowed.isPhysicallyAvailable, isTrue);
      expect(GarmentAvailabilityStatus.lent.isPhysicallyAvailable, isFalse);
      expect(
        GarmentAvailabilityStatus.inStorage.isPhysicallyAvailable,
        isFalse,
      );
      expect(GarmentAvailabilityStatus.donated.isPhysicallyAvailable, isFalse);
      expect(GarmentAvailabilityStatus.lost.isPhysicallyAvailable, isFalse);
    });
  });
}
