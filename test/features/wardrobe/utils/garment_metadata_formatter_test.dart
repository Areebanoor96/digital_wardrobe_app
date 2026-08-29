import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/utils/garment_metadata_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GarmentMetadataFormatter.sizeSummary', () {
    test('summarizes contiguous child size ranges', () {
      expect(
        GarmentMetadataFormatter.sizeSummary(
          const <String>['10-11Y', '11-12Y', '12-13Y'],
        ),
        '10-13Y',
      );
    });

    test('does not merge non-contiguous child sizes', () {
      expect(
        GarmentMetadataFormatter.sizeSummary(
          const <String>['8-9Y', '10-11Y'],
        ),
        '8-9Y, 10-11Y',
      );
    });

    test('leaves adult sizes unchanged', () {
      expect(
        GarmentMetadataFormatter.sizeSummary(const <String>['S', 'M', 'L']),
        'S, M, L',
      );
    });
  });

  group('GarmentMetadataFormatter.seasonSummary', () {
    test('formats one season', () {
      expect(
        GarmentMetadataFormatter.seasonSummary(const <String>['winter']),
        'Winter',
      );
    });

    test('formats multiple seasons', () {
      expect(
        GarmentMetadataFormatter.seasonSummary(
          const <String>['spring', 'summer', 'autumn'],
        ),
        '3 seasons - Spring, Summer, Autumn',
      );
    });

    test('formats all seasons', () {
      expect(
        GarmentMetadataFormatter.seasonSummary(const <String>['all']),
        'All Seasons',
      );
    });
  });

  group('GarmentMetadataFormatter.seasonTagLabel', () {
    test('formats one season', () {
      expect(
        GarmentMetadataFormatter.seasonTagLabel(const <String>['winter']),
        'Winter',
      );
    });

    test('formats multiple seasons into one label', () {
      expect(
        GarmentMetadataFormatter.seasonTagLabel(
          const <String>['winter', 'autumn', 'summer'],
        ),
        'Winter · Autumn · Summer',
      );
    });

    test('formats all seasons', () {
      expect(
        GarmentMetadataFormatter.seasonTagLabel(const <String>['all']),
        'All Seasons',
      );
    });
  });

  group('GarmentMetadataFormatter.categoryLabel', () {
    test('uses singular labels', () {
      expect(GarmentMetadataFormatter.categoryLabel(GarmentCategory.dress),
          'Dress');
      expect(GarmentMetadataFormatter.categoryLabel(GarmentCategory.top),
          'Top');
      expect(GarmentMetadataFormatter.categoryLabel(GarmentCategory.bottom),
          'Bottom');
      expect(GarmentMetadataFormatter.categoryLabel(GarmentCategory.bag),
          'Bag');
    });
  });
}
