class GarmentMetadataFormatter {
  const GarmentMetadataFormatter._();

  static String sizeSummary(List<String> sizes) {
    final List<String> clean = _dedupeClean(sizes);
    if (clean.isEmpty) {
      return '';
    }

    final List<String> summarized = <String>[];
    int index = 0;

    while (index < clean.length) {
      final _NumericSize? current = _NumericSize.tryParse(clean[index]);
      if (current == null) {
        summarized.add(clean[index]);
        index++;
        continue;
      }

      int endIndex = index;
      _NumericSize end = current;
      while (endIndex + 1 < clean.length) {
        final _NumericSize? next = _NumericSize.tryParse(clean[endIndex + 1]);
        if (next == null ||
            next.suffix != current.suffix ||
            next.start != end.end) {
          break;
        }

        end = next;
        endIndex++;
      }

      summarized.add(
        endIndex == index
            ? clean[index]
            : '${current.start}-${end.end}${current.suffix}',
      );
      index = endIndex + 1;
    }

    return summarized.join(', ');
  }

  static String seasonSummary(List<String> seasons) {
    final List<String> clean = _dedupeClean(seasons);
    if (clean.isEmpty) {
      return '';
    }

    if (clean.any((String season) => season.toLowerCase() == 'all')) {
      return 'All Seasons';
    }

    final List<String> labels = clean.map(_titleCase).toList();
    if (labels.length == 1) {
      return labels.single;
    }

    return '${labels.length} seasons - ${labels.join(', ')}';
  }

  static String detailListSummary(List<String> values) {
    final List<String> clean = _dedupeClean(values);
    return clean.join(', ');
  }

  static String _titleCase(String value) {
    final String clean = value.trim();
    if (clean.isEmpty) {
      return '';
    }

    return clean
        .split(RegExp(r'\s+'))
        .map(
          (String word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  static List<String> _dedupeClean(List<String> values) {
    final List<String> clean = <String>[];
    final Set<String> seen = <String>{};

    for (final String value in values) {
      final String trimmed = value.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
        clean.add(trimmed);
      }
    }

    return clean;
  }
}

class _NumericSize {
  const _NumericSize({
    required this.start,
    required this.end,
    required this.suffix,
  });

  final int start;
  final int end;
  final String suffix;

  static _NumericSize? tryParse(String value) {
    final RegExpMatch? match = RegExp(
      r'^(\d+)[-–](\d+)([MY])$',
      caseSensitive: false,
    ).firstMatch(value.trim());

    if (match == null) {
      return null;
    }

    return _NumericSize(
      start: int.parse(match.group(1)!),
      end: int.parse(match.group(2)!),
      suffix: match.group(3)!.toUpperCase(),
    );
  }
}
