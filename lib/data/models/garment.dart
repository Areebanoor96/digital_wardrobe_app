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
    LaundryStatus.washing || LaundryStatus.ironing => 'In laundry',
  };
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
    this.size,
    this.brand,
    this.price,
    this.currency = 'PKR',
    this.occasions = const <String>[],
    this.seasons = const <String>[],
    this.moods = const <String>[],
    this.fabric,
    this.washInstructions,
    this.wearCount = 0,
    this.lastWornDate,
    this.purchaseDate,
    this.laundryStatus = LaundryStatus.clean,
    this.isArchived = false,
    this.familyMemberId,
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
  final String? size;
  final String? brand;
  final double? price;
  final String currency;
  final List<String> occasions;
  final List<String> seasons;
  final List<String> moods;
  final String? fabric;
  final String? washInstructions;
  final int wearCount;
  final DateTime? lastWornDate;
  final DateTime? purchaseDate;
  final LaundryStatus laundryStatus;
  final bool isArchived;
  final String? familyMemberId;

  String? get coverImageUrl => photoUrls.isEmpty ? null : photoUrls.first;
  double? get costPerWear =>
      price == null || wearCount == 0 ? null : price! / wearCount;

  factory Garment.fromJson(
    Map<String, dynamic> json, {
    List<String>? photoUrls,
  }) {
    return Garment(
      id: json['id'] as String,
      name: json['name'] as String,
      memberId: json['member_id'] as String?,
      familyMemberId: json['family_member_id'] as String?,

      category: GarmentCategory.values.byName(json['category'] as String),
      photoPaths: List<String>.from(
        json['photo_urls'] as List<dynamic>? ?? const <String>[],
      ),
      photoUrls: photoUrls ?? const <String>[],
      subcategory: json['subcategory'] as String?,
      colorName: json['color_name'] as String?,
      colorHex: json['color_hex'] as String?,
      size: json['size'] as String?,
      brand: json['brand'] as String?,
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
      washInstructions: json['wash_instructions'] as String?,
      wearCount: json['wear_count'] as int? ?? 0,
      lastWornDate: DateTime.tryParse(json['last_worn_date'] as String? ?? ''),
      purchaseDate: DateTime.tryParse(json['purchase_date'] as String? ?? ''),
      laundryStatus: LaundryStatus.values.byName(
        json['laundry_status'] as String? ?? LaundryStatus.clean.name,
      ),
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
    'size': size,
    'brand': brand,
    'price': price,
    'currency': currency,
    'occasions': occasions,
    'seasons': seasons,
    'mood_tags': moods,
    'fabric': fabric,
    'wash_instructions': washInstructions,
    'photo_urls': photoPaths,
    'purchase_date': purchaseDate?.toIso8601String().split('T').first,
    'laundry_status': laundryStatus.name,
    'is_archived': isArchived,
    'family_member_id': familyMemberId,
  };


  Garment copyWith({
    List<String>? photoPaths,
    List<String>? photoUrls,
    bool? isArchived,
    String? memberId,
    String? familyMemberId,
  }) => Garment(
    id: id,
    name: name,
    category: category,
    photoPaths: photoPaths ?? this.photoPaths,
    photoUrls: photoUrls ?? this.photoUrls,
    subcategory: subcategory,
    colorName: colorName,
    colorHex: colorHex,
    size: size,
    brand: brand,
    price: price,
    currency: currency,
    occasions: occasions,
    seasons: seasons,
    moods: moods,
    fabric: fabric,
    washInstructions: washInstructions,
    wearCount: wearCount,
    lastWornDate: lastWornDate,
    purchaseDate: purchaseDate,
    laundryStatus: laundryStatus,
    isArchived: isArchived ?? this.isArchived,
      familyMemberId: familyMemberId ?? this.familyMemberId,
  );
}
