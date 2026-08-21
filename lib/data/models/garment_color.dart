/// A single selectable garment color shade.
///
/// This is garment metadata only. It has no connection to the application's
/// Material theme colors.
class GarmentColorOption {
  const GarmentColorOption({required this.name, required this.hex});

  /// Human-readable shade name, for example "Navy" or "Burgundy".
  final String name;

  /// Hex value in `#RRGGBB` format, for example "#001F3F".
  final String hex;
}

/// A practical clothing color family containing multiple shades.
class GarmentColorFamily {
  const GarmentColorFamily({required this.name, required this.colors});

  final String name;
  final List<GarmentColorOption> colors;
}

/// The garment color palette used by the Add/Edit Garment form.
class GarmentColorPalette {
  const GarmentColorPalette._();

  static const List<GarmentColorFamily> families = <GarmentColorFamily>[
    GarmentColorFamily(
      name: 'Black / Gray / White',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Black', hex: '#000000'),
        GarmentColorOption(name: 'Off Black', hex: '#1C1C1C'),
        GarmentColorOption(name: 'Charcoal', hex: '#36454F'),
        GarmentColorOption(name: 'Dark Gray', hex: '#555555'),
        GarmentColorOption(name: 'Gray', hex: '#808080'),
        GarmentColorOption(name: 'Silver', hex: '#C0C0C0'),
        GarmentColorOption(name: 'Light Gray', hex: '#D3D3D3'),
        GarmentColorOption(name: 'White', hex: '#FFFFFF'),
        GarmentColorOption(name: 'Off White', hex: '#FAF9F6'),
      ],
    ),
    GarmentColorFamily(
      name: 'Brown / Beige',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Brown', hex: '#7B3F00'),
        GarmentColorOption(name: 'Chocolate', hex: '#4B3621'),
        GarmentColorOption(name: 'Coffee', hex: '#6F4E37'),
        GarmentColorOption(name: 'Taupe', hex: '#483C32'),
        GarmentColorOption(name: 'Camel', hex: '#C19A6B'),
        GarmentColorOption(name: 'Tan', hex: '#D2B48C'),
        GarmentColorOption(name: 'Khaki', hex: '#C3B091'),
        GarmentColorOption(name: 'Beige', hex: '#F5F5DC'),
        GarmentColorOption(name: 'Cream', hex: '#FFFDD0'),
      ],
    ),
    GarmentColorFamily(
      name: 'Red',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Red', hex: '#D22B2B'),
        GarmentColorOption(name: 'Crimson', hex: '#DC143C'),
        GarmentColorOption(name: 'Burgundy', hex: '#800020'),
        GarmentColorOption(name: 'Maroon', hex: '#800000'),
        GarmentColorOption(name: 'Wine', hex: '#722F37'),
      ],
    ),
    GarmentColorFamily(
      name: 'Orange',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Orange', hex: '#FF8C00'),
        GarmentColorOption(name: 'Burnt Orange', hex: '#CC5500'),
        GarmentColorOption(name: 'Rust', hex: '#B7410E'),
        GarmentColorOption(name: 'Terracotta', hex: '#E2725B'),
        GarmentColorOption(name: 'Coral', hex: '#FF7F50'),
        GarmentColorOption(name: 'Peach', hex: '#FFE5B4'),
      ],
    ),
    GarmentColorFamily(
      name: 'Yellow',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Yellow', hex: '#FFD335'),
        GarmentColorOption(name: 'Lemon', hex: '#FFF44F'),
        GarmentColorOption(name: 'Mustard', hex: '#E1AD01'),
        GarmentColorOption(name: 'Gold', hex: '#D4AF37'),
      ],
    ),
    GarmentColorFamily(
      name: 'Green',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Green', hex: '#228B22'),
        GarmentColorOption(name: 'Emerald', hex: '#50C878'),
        GarmentColorOption(name: 'Forest Green', hex: '#1B4D3E'),
        GarmentColorOption(name: 'Olive', hex: '#6B8E23'),
        GarmentColorOption(name: 'Sage', hex: '#9CAF88'),
        GarmentColorOption(name: 'Mint', hex: '#3EB489'),
      ],
    ),
    GarmentColorFamily(
      name: 'Blue',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Navy', hex: '#000080'),
        GarmentColorOption(name: 'Royal Blue', hex: '#4169E1'),
        GarmentColorOption(name: 'Blue', hex: '#1E90FF'),
        GarmentColorOption(name: 'Sky Blue', hex: '#87CEEB'),
        GarmentColorOption(name: 'Baby Blue', hex: '#89CFF1'),
        GarmentColorOption(name: 'Denim', hex: '#4682B4'),
        GarmentColorOption(name: 'Teal', hex: '#008080'),
        GarmentColorOption(name: 'Turquoise', hex: '#40E0D0'),
      ],
    ),
    GarmentColorFamily(
      name: 'Purple',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Purple', hex: '#800080'),
        GarmentColorOption(name: 'Violet', hex: '#8F00FF'),
        GarmentColorOption(name: 'Plum', hex: '#8E4585'),
        GarmentColorOption(name: 'Lilac', hex: '#C8A2C8'),
        GarmentColorOption(name: 'Lavender', hex: '#E6E6FA'),
      ],
    ),
    GarmentColorFamily(
      name: 'Pink',
      colors: <GarmentColorOption>[
        GarmentColorOption(name: 'Pink', hex: '#FFC0CB'),
        GarmentColorOption(name: 'Baby Pink', hex: '#F4C2C2'),
        GarmentColorOption(name: 'Hot Pink', hex: '#FF69B4'),
        GarmentColorOption(name: 'Fuchsia', hex: '#FF00FF'),
        GarmentColorOption(name: 'Blush', hex: '#DE5D83'),
        GarmentColorOption(name: 'Mauve', hex: '#E0B0FF'),
      ],
    ),
  ];

  /// Every selectable shade across all families.
  static List<GarmentColorOption> get allOptions => <GarmentColorOption>[
    for (final GarmentColorFamily family in families) ...family.colors,
  ];

  /// Finds a palette shade by name, case-insensitively.
  ///
  /// Returns null when [name] is null/empty or does not match any shade,
  /// which keeps legacy free-text color values safe.
  static GarmentColorOption? tryFindByName(String? name) {
    final String cleaned = name?.trim() ?? '';

    if (cleaned.isEmpty) {
      return null;
    }

    for (final GarmentColorOption option in allOptions) {
      if (option.name.toLowerCase() == cleaned.toLowerCase()) {
        return option;
      }
    }

    return null;
  }
}
