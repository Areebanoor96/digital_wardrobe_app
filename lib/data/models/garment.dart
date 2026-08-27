enum GarmentCategory {
  top,
  bottom,
  dress,
  outerwear,
  shoe,
  accessory,
  jewelry,
  bag;

  String get label => switch (this) {
    GarmentCategory.top => 'Tops',
    GarmentCategory.bottom => 'Bottoms',
    GarmentCategory.dress => 'Dresses',
    GarmentCategory.outerwear => 'Outerwear',
    GarmentCategory.shoe => 'Shoes',
    GarmentCategory.accessory => 'Accessories',
    GarmentCategory.jewelry => 'Jewelry',
    GarmentCategory.bag => 'Bags',
  };
}

enum LaundryStatus {
  clean,
  dirty,
  washing,
  ironing;

  String get label => switch (this) {
    LaundryStatus.clean => 'Clean',
    LaundryStatus.dirty => 'Needs washing',
    LaundryStatus.washing => 'Washing',
    LaundryStatus.ironing => 'Needs ironing',
  };
}

enum GarmentAvailabilityStatus {
  available,
  lent,
  borrowed,
  inStorage,
  donated,
  lost;

  String get dbValue => switch (this) {
    GarmentAvailabilityStatus.available => 'available',
    GarmentAvailabilityStatus.lent => 'lent',
    GarmentAvailabilityStatus.borrowed => 'borrowed',
    GarmentAvailabilityStatus.inStorage => 'in_storage',
    GarmentAvailabilityStatus.donated => 'donated',
    GarmentAvailabilityStatus.lost => 'lost',
  };

  String get label => switch (this) {
    GarmentAvailabilityStatus.available => 'Available',
    GarmentAvailabilityStatus.lent => 'Lent',
    GarmentAvailabilityStatus.borrowed => 'Borrowed',
    GarmentAvailabilityStatus.inStorage => 'In Storage',
    GarmentAvailabilityStatus.donated => 'Donated',
    GarmentAvailabilityStatus.lost => 'Lost',
  };

  bool get isPhysicallyAvailable =>
      this == GarmentAvailabilityStatus.available ||
      this == GarmentAvailabilityStatus.borrowed;

  static GarmentAvailabilityStatus fromDb(String? value) {
    return switch (value) {
      'lent' => GarmentAvailabilityStatus.lent,
      'borrowed' => GarmentAvailabilityStatus.borrowed,
      'in_storage' => GarmentAvailabilityStatus.inStorage,
      'donated' => GarmentAvailabilityStatus.donated,
      'lost' => GarmentAvailabilityStatus.lost,
      _ => GarmentAvailabilityStatus.available,
    };
  }
}

enum StitchingStatus {
  stitched,
  unstitched;

  String get label => switch (this) {
    StitchingStatus.stitched => 'Stitched',
    StitchingStatus.unstitched => 'Unstitched',
  };
}

enum IroningStatus {
  ironed,
  needsIroning;

  String get dbValue => switch (this) {
    IroningStatus.ironed => 'ironed',
    IroningStatus.needsIroning => 'needs_ironing',
  };

  String get label => switch (this) {
    IroningStatus.ironed => 'Ironed',
    IroningStatus.needsIroning => 'Needs Ironing',
  };

  static IroningStatus? fromDb(String? value) {
    return switch (value) {
      'ironed' => IroningStatus.ironed,
      'needs_ironing' => IroningStatus.needsIroning,
      _ => null,
    };
  }
}

class Garment {
  const Garment({
    required this.id,
    required this.name,
    required this.category,
    required this.photoPaths,
    required this.photoUrls,
    this.memberId,
    this.subcategory,
    this.colorName,
    this.colorHex,
    this.secondaryColorName,
    this.secondaryColorHex,
    this.colorShades = const <GarmentColorShade>[],
    this.size,
    this.sizes = const <String>[],
    this.brand,
    this.purchaseStore,
    this.price,
    this.currency = 'PKR',
    this.occasions = const <String>[],
    this.seasons = const <String>[],
    this.moods = const <String>[],
    this.fabric,
    this.fit,
    this.pattern,
    this.fabricWeight,
    this.sleeveLength,
    this.details,
    this.washInstructions,
    this.wearCount = 0,
    this.lastWornDate,
    this.purchaseDate,
    this.createdAt,
    this.laundryStatus = LaundryStatus.clean,
    this.ironingStatus,
    this.stitchingStatus,
    this.availabilityStatus = GarmentAvailabilityStatus.available,
    this.locationId,
    this.locationName,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String? memberId;
  final GarmentCategory category;
  final List<String> photoPaths;
  final List<String> photoUrls;
  final String? subcategory;
  final String? colorName;
  final String? colorHex;

  /// Optional secondary color selected from the same garment palette.
  final String? secondaryColorName;
  final String? secondaryColorHex;
  final List<GarmentColorShade> colorShades;
  final String? size;
  final List<String> sizes;
  final String? brand;

  /// Example: Outfitters - Centaurus Mall, Islamabad
  final String? purchaseStore;

  final double? price;
  final String currency;
  final List<String> occasions;
  final List<String> seasons;
  final List<String> moods;
  final String? fabric;
  final String? fit;
  final String? pattern;
  final String? fabricWeight;
  final String? sleeveLength;

  /// Optional free-form details, limited to 100 characters by the form.
  final String? details;
  final String? washInstructions;
  final int wearCount;
  final DateTime? lastWornDate;
  final DateTime? purchaseDate;
  final DateTime? createdAt;
  final LaundryStatus laundryStatus;
  final IroningStatus? ironingStatus;
  final StitchingStatus? stitchingStatus;
  final GarmentAvailabilityStatus availabilityStatus;
  final String? locationId;
  final String? locationName;
  final bool isArchived;

  String? get coverImageUrl => photoUrls.isEmpty ? null : photoUrls.first;
  GarmentColorShade? get primaryShade {
    if (colorShades.isEmpty) {
      return null;
    }

    return colorShades.firstWhere(
      (GarmentColorShade shade) => shade.isPrimary,
      orElse: () => colorShades.first,
    );
  }

  List<String> get colorNames {
    final Set<String> names = <String>{};

    for (final GarmentColorShade shade in colorShades) {
      final String trimmed = shade.name.trim();
      if (trimmed.isNotEmpty) {
        names.add(trimmed.toLowerCase());
      }
    }

    for (final String? legacy in <String?>[colorName, secondaryColorName]) {
      final String trimmed = legacy?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        names.add(trimmed.toLowerCase());
      }
    }

    return names.toList();
  }

  List<String> get effectiveSizes {
    final List<String> normalized = sizes
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();

    if (normalized.isNotEmpty) {
      return normalized;
    }

    final String fallback = size?.trim() ?? '';
    return fallback.isEmpty ? const <String>[] : <String>[fallback];
  }

  factory Garment.fromJson(
    Map<String, dynamic> json, {
    List<String>? photoUrls,
  }) {
    final List<GarmentColorShade> shades = _parseColorShades(json);
    final GarmentColorShade? primaryShade = _primaryShade(shades);
    final GarmentColorShade? secondaryShade = shades
        .where((GarmentColorShade shade) => shade != primaryShade)
        .firstOrNull;

    return Garment(
      id: json['id'] as String,
      name: json['name'] as String,
      memberId: json['member_id'] as String?,
      category: GarmentCategory.values.byName(json['category'] as String),
      photoPaths: List<String>.from(
        json['photo_urls'] as List<dynamic>? ?? const <String>[],
      ),
      photoUrls: photoUrls ?? const <String>[],
      subcategory: json['subcategory'] as String?,
      colorName: primaryShade?.name ?? json['color_name'] as String?,
      colorHex: primaryShade?.hex ?? json['color_hex'] as String?,
      secondaryColorName:
          secondaryShade?.name ?? json['secondary_color_name'] as String?,
      secondaryColorHex:
          secondaryShade?.hex ?? json['secondary_color_hex'] as String?,
      colorShades: shades,
      size: json['size'] as String?,
      sizes: _parseSizes(json),
      brand: json['brand'] as String?,
      purchaseStore: json['purchase_store'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'PKR',
      occasions: List<String>.from(
        json['occasions'] as List<dynamic>? ?? const <String>[],
      ),
      seasons: List<String>.from(
        json['seasons'] as List<dynamic>? ?? const <String>[],
      ),
      moods: List<String>.from(
        json['mood_tags'] as List<dynamic>? ?? const <String>[],
      ),
      fabric: json['fabric'] as String?,
      fit: json['fit'] as String?,
      pattern: json['pattern'] as String?,
      fabricWeight: json['fabric_weight'] as String?,
      sleeveLength: json['sleeve_length'] as String?,
      details: json['details'] as String?,
      washInstructions: json['wash_instructions'] as String?,
      wearCount: json['wear_count'] as int? ?? 0,
      lastWornDate: DateTime.tryParse(json['last_worn_date'] as String? ?? ''),
      purchaseDate: DateTime.tryParse(json['purchase_date'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      laundryStatus: LaundryStatus.values.byName(
        json['laundry_status'] as String? ?? LaundryStatus.clean.name,
      ),
      ironingStatus: IroningStatus.fromDb(json['ironing_status'] as String?),
      stitchingStatus: _enumByNameOrNull<StitchingStatus>(
        StitchingStatus.values,
        json['stitching_status'] as String?,
      ),
      availabilityStatus: GarmentAvailabilityStatus.fromDb(
        json['availability_status'] as String?,
      ),
      locationId: json['location_id'] as String?,
      locationName: _parseLocationName(json),
      isArchived: json['is_archived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertJson(String userId) => <String, dynamic>{
    'id': id,
    'user_id': userId,
    'name': name,
    'member_id': memberId,
    'category': category.name,
    'subcategory': subcategory,
    'color_name': colorName,
    'color_hex': colorHex,
    'secondary_color_name': secondaryColorName,
    'secondary_color_hex': secondaryColorHex,
    'size': effectiveSizes.firstOrNull ?? size,
    'brand': brand,
    'purchase_store': purchaseStore,
    'price': price,
    'currency': currency,
    'occasions': occasions,
    'seasons': seasons,
    'mood_tags': moods,
    'fabric': fabric,
    'fit': fit,
    'pattern': pattern,
    'fabric_weight': fabricWeight,
    'sleeve_length': sleeveLength,
    'details': details,
    'wash_instructions': washInstructions,
    'photo_urls': photoPaths,
    'purchase_date': purchaseDate?.toIso8601String().split('T').first,
    'laundry_status': laundryStatus.name,
    'ironing_status': ironingStatus?.dbValue,
    'stitching_status': stitchingStatus?.name,
    'availability_status': availabilityStatus.dbValue,
    'location_id': locationId,
    'is_archived': isArchived,
  };

  Garment copyWith({
    List<String>? photoPaths,
    List<String>? photoUrls,
    bool? isArchived,
    String? memberId,
    String? purchaseStore,
    LaundryStatus? laundryStatus,
    IroningStatus? ironingStatus,
    StitchingStatus? stitchingStatus,
    GarmentAvailabilityStatus? availabilityStatus,
    String? locationId,
    String? locationName,
    List<String>? sizes,
    List<GarmentColorShade>? colorShades,
  }) {
    final List<GarmentColorShade> resolvedColorShades =
        colorShades ?? this.colorShades;
    final GarmentColorShade? resolvedPrimary = _primaryShade(
      resolvedColorShades,
    );
    final GarmentColorShade? resolvedSecondary = resolvedColorShades
        .where((GarmentColorShade shade) => shade != resolvedPrimary)
        .firstOrNull;

    return Garment(
      id: id,
      name: name,
      memberId: memberId ?? this.memberId,
      category: category,
      photoPaths: photoPaths ?? this.photoPaths,
      photoUrls: photoUrls ?? this.photoUrls,
      subcategory: subcategory,
      colorName: resolvedPrimary?.name ?? colorName,
      colorHex: resolvedPrimary?.hex ?? colorHex,
      secondaryColorName: resolvedSecondary?.name ?? secondaryColorName,
      secondaryColorHex: resolvedSecondary?.hex ?? secondaryColorHex,
      colorShades: resolvedColorShades,
      size: size,
      sizes: sizes ?? this.sizes,
      brand: brand,
      purchaseStore: purchaseStore ?? this.purchaseStore,
      price: price,
      currency: currency,
      occasions: occasions,
      seasons: seasons,
      moods: moods,
      fabric: fabric,
      fit: fit,
      pattern: pattern,
      fabricWeight: fabricWeight,
      sleeveLength: sleeveLength,
      details: details,
      washInstructions: washInstructions,
      wearCount: wearCount,
      lastWornDate: lastWornDate,
      purchaseDate: purchaseDate,
      createdAt: createdAt,
      laundryStatus: laundryStatus ?? this.laundryStatus,
      ironingStatus: ironingStatus ?? this.ironingStatus,
      stitchingStatus: stitchingStatus ?? this.stitchingStatus,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  static List<String> _parseSizes(Map<String, dynamic> json) {
    final Object? raw = json['garment_sizes'];

    if (raw is! List) {
      return const <String>[];
    }

    final List<MapEntry<int, Map<String, dynamic>>> rows =
        <MapEntry<int, Map<String, dynamic>>>[];

    for (int index = 0; index < raw.length; index++) {
      final Object? row = raw[index];
      if (row is Map) {
        rows.add(
          MapEntry<int, Map<String, dynamic>>(
            index,
            Map<String, dynamic>.from(row),
          ),
        );
      }
    }

    rows.sort((MapEntry<int, Map<String, dynamic>> a,
        MapEntry<int, Map<String, dynamic>> b) {
      final int aOrder = (a.value['sort_order'] as num?)?.toInt() ?? a.key;
      final int bOrder = (b.value['sort_order'] as num?)?.toInt() ?? b.key;
      return aOrder.compareTo(bOrder);
    });

    final List<String> values = <String>[];
    final Set<String> seen = <String>{};
    for (final MapEntry<int, Map<String, dynamic>> row in rows) {
      final String value = (row.value['size'] as String? ?? '').trim();
      if (value.isNotEmpty && seen.add(value.toLowerCase())) {
        values.add(value);
      }
    }

    return values;
  }

  static String? _parseLocationName(Map<String, dynamic> json) {
    final Object? raw = json['garment_locations'];

    if (raw is Map) {
      return Map<String, dynamic>.from(raw)['name'] as String?;
    }

    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map)['name'] as String?;
    }

    return json['location_name'] as String?;
  }

  static T? _enumByNameOrNull<T extends Enum>(
    List<T> values,
    String? name,
  ) {
    if (name == null) {
      return null;
    }

    for (final T value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return null;
  }

  static List<GarmentColorShade> _parseColorShades(Map<String, dynamic> json) {
    final Object? raw =
        json['garment_color_shades'] ?? json['color_shades'];

    if (raw is! List) {
      return const <GarmentColorShade>[];
    }

    final List<MapEntry<int, Map<String, dynamic>>> rows =
        <MapEntry<int, Map<String, dynamic>>>[];

    for (int index = 0; index < raw.length; index++) {
      final Object? row = raw[index];

      if (row is Map) {
        rows.add(MapEntry<int, Map<String, dynamic>>(
          index,
          Map<String, dynamic>.from(row),
        ));
      }
    }

    rows.sort((MapEntry<int, Map<String, dynamic>> a,
        MapEntry<int, Map<String, dynamic>> b) {
      final int aOrder = (a.value['sort_order'] as num?)?.toInt() ?? a.key;
      final int bOrder = (b.value['sort_order'] as num?)?.toInt() ?? b.key;

      return aOrder.compareTo(bOrder);
    });

    return normalizeColorShades(
      rows.map((MapEntry<int, Map<String, dynamic>> entry) {
        return GarmentColorShade.fromJson(entry.value);
      }).toList(),
    );
  }

  static GarmentColorShade? _primaryShade(List<GarmentColorShade> shades) {
    if (shades.isEmpty) {
      return null;
    }

    return shades.firstWhere(
      (GarmentColorShade shade) => shade.isPrimary,
      orElse: () => shades.first,
    );
  }
}

class GarmentColorShade {
  const GarmentColorShade({
    required this.name,
    required this.hex,
    this.isPrimary = false,
  });

  final String name;
  final String hex;
  final bool isPrimary;

  factory GarmentColorShade.fromJson(Map<String, dynamic> json) {
    return GarmentColorShade(
      name: json['color_name'] as String? ?? json['name'] as String? ?? '',
      hex: json['color_hex'] as String? ?? json['hex'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson({
    required String userId,
    required String garmentId,
    required int sortOrder,
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'garment_id': garmentId,
      'color_name': name,
      'color_hex': hex,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
    };
  }

  GarmentColorShade copyWith({bool? isPrimary}) {
    return GarmentColorShade(
      name: name,
      hex: hex,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

List<GarmentColorShade> normalizeColorShades(List<GarmentColorShade> shades) {
  final List<GarmentColorShade> cleaned = <GarmentColorShade>[];
  final Set<String> seen = <String>{};

  for (final GarmentColorShade shade in shades) {
    final String name = shade.name.trim();
    final String hex = shade.hex.trim();
    if (name.isEmpty || hex.isEmpty) {
      continue;
    }

    final String key = name.toLowerCase();
    if (seen.add(key)) {
      cleaned.add(GarmentColorShade(
        name: name,
        hex: hex,
        isPrimary: shade.isPrimary,
      ));
    }
  }

  if (cleaned.isEmpty) {
    return const <GarmentColorShade>[];
  }

  int primaryIndex = cleaned.indexWhere(
    (GarmentColorShade shade) => shade.isPrimary,
  );
  if (primaryIndex == -1) {
    primaryIndex = 0;
  }

  return <GarmentColorShade>[
    for (int index = 0; index < cleaned.length; index++)
      cleaned[index].copyWith(isPrimary: index == primaryIndex),
  ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
