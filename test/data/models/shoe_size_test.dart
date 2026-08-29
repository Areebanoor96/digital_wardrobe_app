import 'package:digital_wardrobe_app/data/models/shoe_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShoeSizeCatalog', () {
    test('provides non-empty lists for every system', () {
      for (final ShoeSizeSystem system in ShoeSizeSystem.values) {
        expect(
          ShoeSizeCatalog.sizesFor(system),
          isNotEmpty,
          reason: '${system.label} must have at least one size',
        );
      }
    });

    test('covers baby/infant through adult across the catalog', () {
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.eu), contains('15'));
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.eu), contains('50'));
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usInfant), contains('0'));
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usInfant), contains('4'));
      expect(
        ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usToddler),
        contains('4.5'),
      );
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usToddler), contains('10'));
      expect(
        ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usYouth),
        contains('10.5'),
      );
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usYouth), contains('3'));
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usAdult), contains('4'));
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usAdult), contains('16'));
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.uk), contains('0'));
      expect(ShoeSizeCatalog.sizesFor(ShoeSizeSystem.uk), contains('14'));
    });

    test('has no duplicate values within a system', () {
      for (final ShoeSizeSystem system in ShoeSizeSystem.values) {
        final List<String> sizes = ShoeSizeCatalog.sizesFor(system);
        expect(
          sizes.toSet().length,
          sizes.length,
          reason: '${system.label} contains duplicates',
        );
      }
    });

    test('formats half sizes without trailing zeros', () {
      expect(
        ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usAdult),
        contains('7.5'),
      );
      expect(
        ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usAdult),
        contains('8'),
      );
      expect(
        ShoeSizeCatalog.sizesFor(ShoeSizeSystem.usToddler),
        contains('10'),
      );
    });

    test('every hint is non-empty', () {
      for (final ShoeSizeSystem system in ShoeSizeSystem.values) {
        expect(ShoeSizeCatalog.hintFor(system), isNotEmpty);
      }
    });
  });

  group('ShoeSizeSystem.tryParse', () {
    test('resolves labels case-insensitively', () {
      expect(ShoeSizeSystem.tryParse('EU'), ShoeSizeSystem.eu);
      expect(ShoeSizeSystem.tryParse('eu'), ShoeSizeSystem.eu);
      expect(ShoeSizeSystem.tryParse('US Infant'), ShoeSizeSystem.usInfant);
      expect(ShoeSizeSystem.tryParse('us toddler'), ShoeSizeSystem.usToddler);
      expect(ShoeSizeSystem.tryParse('US Youth'), ShoeSizeSystem.usYouth);
      expect(ShoeSizeSystem.tryParse('US Adult'), ShoeSizeSystem.usAdult);
      expect(ShoeSizeSystem.tryParse('UK'), ShoeSizeSystem.uk);
    });

    test('returns null for unknown systems', () {
      expect(ShoeSizeSystem.tryParse('EUR'), isNull);
      expect(ShoeSizeSystem.tryParse('US'), isNull);
      expect(ShoeSizeSystem.tryParse(''), isNull);
    });
  });

  group('ShoeSize', () {
    test('label uses the canonical system + value form', () {
      const ShoeSize size = ShoeSize(
        system: ShoeSizeSystem.usAdult,
        value: '8',
      );
      expect(size.label, 'US Adult 8');
    });

    test('tryParse round-trips the canonical format', () {
      const ShoeSize size = ShoeSize(
        system: ShoeSizeSystem.usAdult,
        value: '8',
      );
      final ShoeSize? parsed = ShoeSize.tryParse(size.label);
      expect(parsed, size);
    });

    test('tryParse is case-insensitive on the system label', () {
      final ShoeSize? parsed = ShoeSize.tryParse('us infant 2');
      expect(
        parsed,
        const ShoeSize(system: ShoeSizeSystem.usInfant, value: '2'),
      );
    });

    test('trims surrounding whitespace', () {
      final ShoeSize? parsed = ShoeSize.tryParse('  US Adult 8  ');
      expect(
        parsed,
        const ShoeSize(system: ShoeSizeSystem.usAdult, value: '8'),
      );
    });

    test('returns null for legacy or malformed values', () {
      expect(ShoeSize.tryParse(null), isNull);
      expect(ShoeSize.tryParse(''), isNull);
      expect(ShoeSize.tryParse('   '), isNull);
      expect(ShoeSize.tryParse('35'), isNull);
      expect(ShoeSize.tryParse('UK/PK 5'), isNull);
      expect(ShoeSize.tryParse('EU'), isNull);
      expect(ShoeSize.tryParse('US Infant'), isNull);
      expect(ShoeSize.tryParse('EU '), isNull);
    });

    test('operator == compares system and value', () {
      const ShoeSize a = ShoeSize(
        system: ShoeSizeSystem.eu,
        value: '40',
      );
      const ShoeSize b = ShoeSize(
        system: ShoeSizeSystem.eu,
        value: '40',
      );
      const ShoeSize c = ShoeSize(
        system: ShoeSizeSystem.eu,
        value: '41',
      );
      const ShoeSize d = ShoeSize(
        system: ShoeSizeSystem.uk,
        value: '40',
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
      expect(a, isNot(d));
    });
  });

  group('band disambiguation', () {
    test('same number in different bands is unambiguous', () {
      const ShoeSize infant1 = ShoeSize(
        system: ShoeSizeSystem.usInfant,
        value: '1',
      );
      const ShoeSize youth1 = ShoeSize(
        system: ShoeSizeSystem.usYouth,
        value: '1',
      );
      const ShoeSize toddler1 = ShoeSize(
        system: ShoeSizeSystem.usToddler,
        value: '10.5',
      );

      expect(infant1.label, 'US Infant 1');
      expect(youth1.label, 'US Youth 1');
      expect(toddler1.label, 'US Toddler 10.5');
      expect(infant1, isNot(youth1));
    });
  });
}