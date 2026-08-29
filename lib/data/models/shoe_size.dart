/// Shoe-size systems supported by the app, including child (infant/toddler/
/// youth) and adult bands so a size value is never ambiguous.
///
/// US sizes are split into separate bands because the same number maps to
/// different feet depending on age band (e.g. `US Infant 1` vs `US Youth 1`).
enum ShoeSizeSystem {
  eu('EU'),
  usInfant('US Infant'),
  usToddler('US Toddler'),
  usYouth('US Youth'),
  usAdult('US Adult'),
  uk('UK');

  const ShoeSizeSystem(this.label);

  /// Canonical, human-readable name used in the UI and in stored values
  /// (e.g. `US Adult 8`).
  final String label;

  /// Resolves a label (e.g. `'US Infant'`) back to an enum value, or returns
  /// `null` when the text does not match a known system.
  static ShoeSizeSystem? tryParse(String text) {
    final String trimmed = text.trim();

    for (final ShoeSizeSystem system in values) {
      if (system.label.toLowerCase() == trimmed.toLowerCase()) {
        return system;
      }
    }

    return null;
  }
}

/// A single shoe size value tied to a sizing system (e.g. `US Adult 8`).
///
/// Values are persisted as free text (`ShoeSize.label`) so older/legacy
/// entries remain readable; [tryParse] round-trips the canonical format and
/// returns `null` for anything it does not understand.
class ShoeSize {
  const ShoeSize({required this.system, required this.value});

  final ShoeSizeSystem system;
  final String value;

  /// Canonical stored/display form, e.g. `'US Adult 8'`.
  String get label => '${system.label} $value';

  /// Parses a stored string back into a [ShoeSize] when it matches the
  /// canonical `'<system label> <value>'` format. Returns `null` for legacy
  /// or otherwise unrecognised values (e.g. `'35'`, `'UK/PK 5'`).
  static ShoeSize? tryParse(String? text) {
    final String input = text?.trim() ?? '';

    if (input.isEmpty) {
      return null;
    }

    for (final ShoeSizeSystem system in ShoeSizeSystem.values) {
      final String prefix = '${system.label} ';

      if (input.toLowerCase().startsWith(prefix.toLowerCase())) {
        final String value = input.substring(prefix.length).trim();

        if (value.isNotEmpty) {
          return ShoeSize(system: system, value: value);
        }
      }
    }

    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ShoeSize && other.system == system && other.value == value;

  @override
  int get hashCode => Object.hash(system, value);

  @override
  String toString() => label;
}

/// Catalog of every supported shoe size, grouped by system.
///
/// Sizing bands intentionally span baby/infant, toddler, child/youth, teen and
/// adult ranges so any profile type can pick an appropriate size. The bands
/// are not driven by the member's date of birth or age.
abstract final class ShoeSizeCatalog {
  static final Map<ShoeSizeSystem, List<String>> _sizes = _buildCatalog();

  /// All size values available for [system], young-to-large.
  static List<String> sizesFor(ShoeSizeSystem system) => _sizes[system]!;

  /// Short guidance shown next to the picker, e.g. `'EU 15–50'`.
  static String hintFor(ShoeSizeSystem system) => switch (system) {
    ShoeSizeSystem.eu => 'EU 15–50 (toddler to adult)',
    ShoeSizeSystem.usInfant => 'US Infant 0–4 (crawler/pre-walker)',
    ShoeSizeSystem.usToddler => 'US Toddler 4.5–10',
    ShoeSizeSystem.usYouth => 'US Youth 10.5–3',
    ShoeSizeSystem.usAdult => 'US Adult 4–16',
    ShoeSizeSystem.uk => 'UK 0–14',
  };

  static Map<ShoeSizeSystem, List<String>> _buildCatalog() {
    return <ShoeSizeSystem, List<String>>{
      // EU sizes are continuous whole numbers from infant to adult.
      ShoeSizeSystem.eu: List<String>.generate(36, (int index) {
        return (15 + index).toString();
      }),
      ShoeSizeSystem.usInfant: _halvesFrom(0, 4),
      ShoeSizeSystem.usToddler: _halvesFrom(4.5, 10),
      ShoeSizeSystem.usYouth: <String>[
        ..._halvesFrom(10.5, 13.5),
        ..._halvesFrom(1, 3),
      ],
      ShoeSizeSystem.usAdult: _halvesFrom(4, 16),
      ShoeSizeSystem.uk: _halvesFrom(0, 14),
    };
  }

  /// Generates `start` to `end` in 0.5 steps, formatting whole numbers
  /// without a trailing `.0` (e.g. `'9'`, `'9.5'`).
  static List<String> _halvesFrom(double start, double end) {
    final List<String> result = <String>[];

    for (double value = start; value <= end + 0.001; value += 0.5) {
      result.add(
        value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toStringAsFixed(1),
      );
    }

    return result;
  }
}