import 'dart:io';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/image_service.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/garment_color.dart';
import 'package:digital_wardrobe_app/data/models/garment_location.dart';
import 'package:digital_wardrobe_app/data/models/lending_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum _GarmentImageSource { camera, gallery, file }

class GarmentFormScreen extends ConsumerStatefulWidget {
  const GarmentFormScreen({super.key, this.garment});

  final Garment? garment;

  @override
  ConsumerState<GarmentFormScreen> createState() => _GarmentFormScreenState();
}

class _GarmentFormScreenState extends ConsumerState<GarmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController(
    text: widget.garment?.name,
  );

  late final TextEditingController _brand = TextEditingController(
    text: widget.garment?.brand,
  );

  late final TextEditingController _purchaseStore = TextEditingController(
    text: widget.garment?.purchaseStore,
  );

  late List<GarmentColorShade> _colorShades = _initialColorShades(
    widget.garment,
  );
  bool _showPrimaryColorError = false;

  static const List<String> _childSizeOptions = <String>[
    '0-1M',
    '1-3M',
    '3-6M',
    '6-9M',
    '9-12M',
    '12-18M',
    '18-24M',
    '2-3Y',
    '3-4Y',
    '4-5Y',
    '5-6Y',
    '6-7Y',
    '7-8Y',
    '8-9Y',
    '9-10Y',
    '10-11Y',
    '11-12Y',
    '12-13Y',
    '13-14Y',
  ];

  static const List<String> _sizeOptions = <String>[
    ..._childSizeOptions,
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '3XL',
    'Free Size',
    'One Size',
  ];

  late final Set<String> _selectedSizes = <String>{
    ...?widget.garment?.effectiveSizes,
  };

  static const List<String> _shoeSizeOptions = <String>[
    '36',
    '37',
    '38',
    '39',
    '40',
    '41',
    '42',
  ];

  List<String> get _categorySizeOptions =>
      _category == GarmentCategory.shoe ? _shoeSizeOptions : _sizeOptions;

  List<String> get _sizeItems => _optionsWithSavedValue(
    _categorySizeOptions,
    _selectedSizes.isEmpty ? null : _selectedSizes.first,
  );

  static const List<String> _topSubcategoryOptions = <String>[
    'Shirt',
    'T-shirt',
    'Blouse',
  ];

  static const List<String> _bottomSubcategoryOptions = <String>[
    'Trousers',
    'Pants',
    'Jeans',
  ];

  static const List<String> _dressSubcategoryOptions = <String>[
    'Maxi',
    'Jumpsuit',
    'Co-ord Set',
  ];

  static const List<String> _outerwearSubcategoryOptions = <String>[
    'Jacket',
    'Coat',
    'Shrug',
  ];

  static const List<String> _shoeSubcategoryOptions = <String>[
    'Shoes',
    'Sandals',
    'Sneakers',
  ];

  static const List<String> _bagSubcategoryOptions = <String>[
    'Handbag',
    'Tote',
    'Backpack',
  ];

  static const List<String> _accessorySubcategoryOptions = <String>[
    'Tie',
    'Scarf/Stole',
    'Hat/Cap',
  ];

  static const List<String> _jewelrySubcategoryOptions = <String>[
    'Necklace',
    'Earrings',
    'Cufflinks',
  ];

  static const List<String> _activewearSubcategoryOptions = <String>[
    'Tracksuit',
    'Sports Top',
  ];

  static const List<String> _sleepwearSubcategoryOptions = <String>[
    'Pajamas',
    'Nightdress',
    'Robe',
  ];

  static const List<String> _watchesSubcategoryOptions = <String>[
    'Analog',
    'Digital',
    'Smart',
  ];

  static const List<String> _fabricOptions = <String>[
    'Bamboo',
    'Canvas',
    'Cashmere',
    'Chambray',
    'Chiffon',
    'Corduroy',
    'Cotton',
    'Denim',
    'Flannel',
    'Fleece',
    'Georgette',
    'Jersey',
    'Khaddar',
    'Lawn',
    'Leather',
    'Linen',
    'Lycra/Spandex',
    'Modal',
    'Net/Tulle',
    'Nylon',
    'Organza',
    'Polyester',
    'Rayon/Viscose',
    'Satin',
    'Silk',
    'Suede',
    'Tweed',
    'Velvet',
    'Wool',
  ];

  late String? _selectedFabric = _cleanOptional(widget.garment?.fabric);

  late final List<String> _fabricDropdownItems = _buildFabricDropdownItems();

  List<String> _buildFabricDropdownItems() {
    final String? savedFabric = widget.garment?.fabric?.trim();

    if (savedFabric == null || savedFabric.isEmpty) {
      return _fabricOptions;
    }

    return _fabricOptions.contains(savedFabric)
        ? _fabricOptions
        : <String>[..._fabricOptions, savedFabric];
  }

  static const List<String> _fitOptions = <String>[
    'Regular',
    'Slim',
    'Relaxed',
    'Oversized',
    'Tailored',
    'Straight',
    'Tapered',
    'Wide-leg',
    'Skinny',
    'Flared',
    'Boxy',
    'Cropped',
    'Flowy',
    'Structured',
  ];

  static const List<String> _patternOptions = <String>[
    'Solid',
    'Striped',
    'Checked',
    'Floral',
    'Graphic',
    'Polka Dot',
    'Animal Print',
    'Abstract',
    'Embroidered',
    'Sequined',
    'Textured',
    'Other',
  ];

  static const List<String> _fabricWeightOptions = <String>[
    'Light',
    'Medium',
    'Heavy',
  ];

  static const List<String> _sleeveLengthOptions = <String>[
    'Sleeveless',
    'Short Sleeve',
    'Three-Quarter Sleeve',
    'Long Sleeve',
  ];

  late String? _selectedFit = _cleanOptional(widget.garment?.fit);
  late String? _selectedPattern = _cleanOptional(widget.garment?.pattern);
  late String? _selectedFabricWeight = _cleanOptional(
    widget.garment?.fabricWeight,
  );
  late String? _selectedSleeveLength = _cleanSleeveLength(
    widget.garment?.sleeveLength,
  );

  late final TextEditingController _details = TextEditingController(
    text: widget.garment?.details,
  );

  static const int _maximumDetailsLength = 100;

  late final TextEditingController _price = TextEditingController(
    text: widget.garment?.price?.toString(),
  );

  late final TextEditingController _purchaseDateController =
      TextEditingController(
        text: widget.garment?.purchaseDate == null
            ? ''
            : _formatDate(widget.garment!.purchaseDate!),
      );

  late DateTime? _purchaseDate = widget.garment?.purchaseDate;

  late GarmentCategory _category =
      widget.garment?.category ?? GarmentCategory.top;

  late String? _selectedSubcategory = _cleanOptional(
    widget.garment?.subcategory,
  );

  final TextEditingController _subcategoryCustom = TextEditingController();

  late GarmentAvailabilityStatus _availabilityStatus =
      widget.garment?.availabilityStatus ?? GarmentAvailabilityStatus.available;

  late StitchingStatus? _stitchingStatus = widget.garment?.stitchingStatus;

  late IroningStatus? _ironingStatus = widget.garment?.ironingStatus;

  late String? _selectedLocationId = widget.garment?.locationId;
  GarmentLocation? _createdLocationFallback;

  final TextEditingController _lendingPerson = TextEditingController();
  final TextEditingController _lendingDateController = TextEditingController();
  final TextEditingController _expectedReturnDateController =
      TextEditingController();
  final TextEditingController _lendingNotes = TextEditingController();

  DateTime? _lendingDate;
  DateTime? _expectedReturnDate;
  bool _lendingLoaded = false;

  static const int _maximumPhotos = 3;

  late final List<String> _existingPhotoPaths = <String>[
    ...?widget.garment?.photoPaths,
  ];

  late final List<String> _existingPhotoUrls = <String>[
    ...?widget.garment?.photoUrls,
  ];

  final List<XFile> _newImages = <XFile>[];
  final List<String> _removedPhotoPaths = <String>[];

  late String? _selectedExistingCoverPath = _existingPhotoPaths.isEmpty
      ? null
      : _existingPhotoPaths.first;

  String? _selectedNewCoverPath;

  bool _saving = false;
  bool _advancedOptionsExpanded = false;

  late String? _existingReceiptPath = widget.garment?.receiptPath;
  late String? _existingReceiptUrl = widget.garment?.receiptUrl;
  XFile? _newReceiptFile;
  String? _removedReceiptPath;

  static const String _addNewLocationValue = '__add_new_location__';

  FamilyMember? _mismatchedGarmentMember;
  static const List<String> _occasionOptions = <String>[
    'casual',
    'college',
    'ethnic',
    'formal',
    'home',
    'party',
    'sleep',
    'sport',
    'travel',
    'wedding',
    'work',
  ];

  static const List<String> _seasonOptions = <String>[
    'summer',
    'winter',
    'spring',
    'autumn',
    'all',
  ];

  static const List<String> _moodOptions = <String>[
    'bold',
    'cozy',
    'elegant',
    'minimal',
    'party',
    'professional',
    'relaxed',
    'sporty',
  ];
  late final Set<String> _selectedOccasions = <String>{
    ...?widget.garment?.occasions,
  };

  late final Set<String> _selectedSeasons = <String>{
    ...?widget.garment?.seasons,
  };

  late final Set<String> _selectedMoods = <String>{...?widget.garment?.moods};

  @override
  void initState() {
    super.initState();

    _subcategoryCustom.text = _cleanOptional(widget.garment?.subcategory) ?? '';

    if (widget.garment?.availabilityStatus == GarmentAvailabilityStatus.lent ||
        widget.garment?.availabilityStatus ==
            GarmentAvailabilityStatus.borrowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadActiveLendingRecord();
      });
    }
  }

  Future<void> _loadActiveLendingRecord() async {
    final Garment? garment = widget.garment;
    final String? memberId = garment?.memberId;

    if (garment == null || memberId == null || _lendingLoaded) {
      return;
    }

    try {
      final LendingRecord? record = await ref
          .read(lendingRepositoryProvider)
          .fetchActiveRecord(memberId: memberId, garmentId: garment.id);

      if (!mounted || record == null) {
        return;
      }

      setState(() {
        _lendingLoaded = true;
        _lendingPerson.text = record.personName;
        _lendingDate = record.dateOut;
        _lendingDateController.text = _formatDate(record.dateOut);
        _expectedReturnDate = record.expectedReturnDate;
        _expectedReturnDateController.text = record.expectedReturnDate == null
            ? ''
            : _formatDate(record.expectedReturnDate!);
        _lendingNotes.text = record.notes ?? '';
      });
    } catch (error) {
      debugPrint('Could not load active lending record: $error');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _purchaseStore.dispose();
    _details.dispose();
    _price.dispose();
    _purchaseDateController.dispose();
    _subcategoryCustom.dispose();
    _lendingPerson.dispose();
    _lendingDateController.dispose();
    _expectedReturnDateController.dispose();
    _lendingNotes.dispose();
    super.dispose();
  }

  String? _cleanOptional(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _cleanSleeveLength(String? value) {
    final String? cleaned = _cleanOptional(value);
    if (cleaned == null || cleaned.toLowerCase() == 'not applicable') {
      return null;
    }

    return cleaned;
  }

  static List<GarmentColorShade> _initialColorShades(Garment? garment) {
    if (garment == null) {
      return const <GarmentColorShade>[];
    }

    if (garment.colorShades.isNotEmpty) {
      return normalizeColorShades(garment.colorShades);
    }

    final List<GarmentColorShade> legacy = <GarmentColorShade>[];
    if (garment.colorName != null && garment.colorHex != null) {
      legacy.add(
        GarmentColorShade(
          name: garment.colorName!,
          hex: garment.colorHex!,
          isPrimary: true,
        ),
      );
    }
    if (garment.secondaryColorName != null &&
        garment.secondaryColorHex != null) {
      legacy.add(
        GarmentColorShade(
          name: garment.secondaryColorName!,
          hex: garment.secondaryColorHex!,
        ),
      );
    }

    return normalizeColorShades(legacy);
  }

  Future<void> _pickColor() async {
    final GarmentColorOption? picked =
        await showModalBottomSheet<GarmentColorOption>(
          context: context,
          isScrollControlled: true,
          builder: (BuildContext sheetContext) {
            return _GarmentColorPickerSheet(
              title: 'Select garment shade',
              selectedNames: _colorShades
                  .map((GarmentColorShade shade) => shade.name)
                  .toSet(),
            );
          },
        );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      final bool alreadySelected = _colorShades.any(
        (GarmentColorShade shade) =>
            shade.name.toLowerCase() == picked.name.toLowerCase(),
      );
      if (alreadySelected) {
        return;
      }

      _colorShades = normalizeColorShades(<GarmentColorShade>[
        ..._colorShades,
        GarmentColorShade(
          name: picked.name,
          hex: picked.hex,
          isPrimary: _colorShades.isEmpty,
        ),
      ]);
      _showPrimaryColorError = false;
    });
  }

  void _setPrimaryShade(GarmentColorShade selected) {
    setState(() {
      _colorShades = normalizeColorShades(
        _colorShades
            .map(
              (GarmentColorShade shade) => shade.copyWith(
                isPrimary:
                    shade.name.toLowerCase() == selected.name.toLowerCase(),
              ),
            )
            .toList(),
      );
      _showPrimaryColorError = false;
    });
  }

  void _removeColorShade(GarmentColorShade selected) {
    setState(() {
      _colorShades = normalizeColorShades(
        _colorShades
            .where(
              (GarmentColorShade shade) =>
                  shade.name.toLowerCase() != selected.name.toLowerCase(),
            )
            .toList(),
      );
    });
  }

  Future<void> _chooseImages() async {
    final int remainingSlots =
        _maximumPhotos - _existingPhotoPaths.length - _newImages.length;

    if (remainingSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 3 photos.')),
      );
      return;
    }
    final _GarmentImageSource? source =
        await showModalBottomSheet<_GarmentImageSource>(
          context: context,
          builder: (BuildContext sheetContext) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('Take photo'),
                    onTap: () {
                      Navigator.pop(sheetContext, _GarmentImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Choose from gallery'),
                    onTap: () {
                      Navigator.pop(sheetContext, _GarmentImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: const Text('Attach from Files'),
                    subtitle: const Text('JPG, JPEG, PNG or WEBP'),
                    onTap: () {
                      Navigator.pop(sheetContext, _GarmentImageSource.file);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Cancel'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );

    if (source == null) {
      return;
    }

    if (source == _GarmentImageSource.camera) {
      final XFile? image = await ref.read(imageServiceProvider).takePhoto();

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _newImages.add(image);

        if (_selectedExistingCoverPath == null &&
            _selectedNewCoverPath == null) {
          _selectedNewCoverPath = image.path;
        }
      });

      return;
    }

    if (source == _GarmentImageSource.file) {
      final XFile? image = await ref.read(imageServiceProvider).pickImageFile();

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _newImages.add(image);

        if (_selectedExistingCoverPath == null &&
            _selectedNewCoverPath == null) {
          _selectedNewCoverPath = image.path;
        }
      });

      return;
    }

    final List<XFile> selectedImages = await ref
        .read(imageServiceProvider)
        .pickMultipleFromGallery(limit: remainingSlots);

    if (!mounted || selectedImages.isEmpty) {
      return;
    }

    if (selectedImages.length > remainingSlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only add $remainingSlots more '
            '${remainingSlots == 1 ? 'photo' : 'photos'}.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _newImages.addAll(selectedImages);

      if (_selectedExistingCoverPath == null &&
          _selectedNewCoverPath == null &&
          _newImages.isNotEmpty) {
        _selectedNewCoverPath = _newImages.first.path;
      }
    });
  }

  void _removeExistingPhoto(int index) {
    setState(() {
      final String removedPath = _existingPhotoPaths.removeAt(index);

      if (index < _existingPhotoUrls.length) {
        _existingPhotoUrls.removeAt(index);
      }

      _removedPhotoPaths.add(removedPath);

      if (_selectedExistingCoverPath == removedPath) {
        _selectFirstAvailableCover();
      }
    });
  }

  void _removeNewPhoto(int index) {
    setState(() {
      final XFile removedImage = _newImages.removeAt(index);

      if (_selectedNewCoverPath == removedImage.path) {
        _selectFirstAvailableCover();
      }
    });
  }

  void _selectFirstAvailableCover() {
    if (_existingPhotoPaths.isNotEmpty) {
      _selectedExistingCoverPath = _existingPhotoPaths.first;
      _selectedNewCoverPath = null;
      return;
    }

    if (_newImages.isNotEmpty) {
      _selectedExistingCoverPath = null;
      _selectedNewCoverPath = _newImages.first.path;
      return;
    }

    _selectedExistingCoverPath = null;
    _selectedNewCoverPath = null;
  }

  void _setExistingPhotoAsCover(String path) {
    setState(() {
      _selectedExistingCoverPath = path;
      _selectedNewCoverPath = null;
    });
  }

  void _setNewPhotoAsCover(XFile image) {
    setState(() {
      _selectedNewCoverPath = image.path;
      _selectedExistingCoverPath = null;
    });
  }

  Future<void> _pickReceipt() async {
    final _GarmentImageSource? source =
        await showModalBottomSheet<_GarmentImageSource>(
          context: context,
          builder: (BuildContext sheetContext) {
            return SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('Take photo'),
                    subtitle: const Text('Capture the receipt'),
                    onTap: () {
                      Navigator.pop(sheetContext, _GarmentImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Choose from gallery'),
                    subtitle: const Text('Pick a saved receipt image'),
                    onTap: () {
                      Navigator.pop(sheetContext, _GarmentImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: const Text('Attach from Files'),
                    subtitle: const Text('JPG, JPEG, PNG or WEBP'),
                    onTap: () {
                      Navigator.pop(sheetContext, _GarmentImageSource.file);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Cancel'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );

    if (source == null) {
      return;
    }

    final ImageService imageService = ref.read(imageServiceProvider);
    final XFile? file = switch (source) {
      _GarmentImageSource.camera => await imageService.takePhoto(),
      _GarmentImageSource.gallery => await imageService.pickFromGallery(),
      _GarmentImageSource.file => await imageService.pickImageFile(),
    };

    if (file == null || !mounted) {
      return;
    }

    setState(() {
      if (_existingReceiptPath != null) {
        _removedReceiptPath = _existingReceiptPath;
        _existingReceiptPath = null;
        _existingReceiptUrl = null;
      }
      _newReceiptFile = file;
    });
  }

  void _removeReceipt() {
    setState(() {
      if (_existingReceiptPath != null) {
        _removedReceiptPath = _existingReceiptPath;
        _existingReceiptPath = null;
        _existingReceiptUrl = null;
      }
      _newReceiptFile = null;
    });
  }

  Future<void> _pickPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _purchaseDate = DateTime(picked.year, picked.month, picked.day);
      _purchaseDateController.text = _formatDate(_purchaseDate!);
    });
  }

  void _clearPurchaseDate() {
    setState(() {
      _purchaseDate = null;
      _purchaseDateController.clear();
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final List<GarmentColorShade> colorShades = normalizeColorShades(
      _colorShades,
    );
    final GarmentColorShade? primaryShade = colorShades.primaryShadeOrNull;
    final GarmentColorShade? secondaryShade = colorShades
        .where((GarmentColorShade shade) => shade != primaryShade)
        .firstOrNull;

    if (primaryShade == null) {
      setState(() {
        _showPrimaryColorError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one shade.')),
      );
      return;
    }

    if (_isLendingStatus) {
      final DateTime lentDate = _lendingDate ?? DateTime.now();
      if (_expectedReturnDate != null &&
          _expectedReturnDate!.isBefore(
            DateTime(lentDate.year, lentDate.month, lentDate.day),
          )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expected Return Date cannot be before Lent Date.'),
          ),
        );
        return;
      }
    }

    final selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No profile selected.')));
      }
      return;
    }

    if (widget.garment != null &&
        widget.garment!.memberId != null &&
        widget.garment!.memberId != selectedMember.id) {
      if (mounted) {
        final FamilyMember? owner = _mismatchedGarmentMember;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              owner == null
                  ? 'This garment belongs to a different profile. '
                        'Switch to that profile before saving it.'
                  : 'This garment belongs to "${owner.name}", but '
                        '"${selectedMember.name}" is selected. '
                        'Switch to ${owner.name}’s profile to save this item.',
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final String id = widget.garment?.id ?? const Uuid().v4();

      final List<String> photoPaths = List<String>.from(_existingPhotoPaths);

      String? uploadedNewCoverPath;

      for (int index = 0; index < _newImages.length; index++) {
        final XFile image = _newImages[index];

        final Uint8List bytes = await ref
            .read(imageServiceProvider)
            .readAndCompressBytes(image);

        final String uploadedPath = await ref
            .read(garmentRepositoryProvider)
            .uploadImage(garmentId: id, bytes: bytes, imageIndex: index);

        photoPaths.add(uploadedPath);

        if (_selectedNewCoverPath == image.path) {
          uploadedNewCoverPath = uploadedPath;
        }
      }

      String? uploadedReceiptPath;
      if (_newReceiptFile != null) {
        final Uint8List bytes = await ref
            .read(imageServiceProvider)
            .readAndCompressBytes(_newReceiptFile!);
        uploadedReceiptPath = await ref
            .read(garmentRepositoryProvider)
            .uploadReceipt(garmentId: id, bytes: bytes);
      }

      final String? selectedCoverPath =
          uploadedNewCoverPath ?? _selectedExistingCoverPath;

      if (selectedCoverPath != null && photoPaths.remove(selectedCoverPath)) {
        photoPaths.insert(0, selectedCoverPath);
      }
      final Garment garment = Garment(
        id: id,
        name: _name.text.trim(),
        category: _category,
        memberId: selectedMember.id,
        photoPaths: photoPaths,
        photoUrls: widget.garment?.photoUrls ?? const <String>[],
        receiptPath: uploadedReceiptPath ?? _existingReceiptPath,
        subcategory: _showSubcategory ? _selectedSubcategory : null,
        brand: _optional(_brand.text),
        purchaseStore: _optional(_purchaseStore.text),
        colorName: primaryShade.name,
        colorHex: primaryShade.hex,
        secondaryColorName: secondaryShade?.name,
        secondaryColorHex: secondaryShade?.hex,
        colorShades: colorShades,
        size: _selectedSizes.isEmpty ? null : _selectedSizes.first,
        sizes: _showSizes ? _selectedSizes.toList() : const <String>[],
        price: double.tryParse(_price.text.trim()),
        currency: widget.garment?.currency ?? 'PKR',
        occasions: _selectedOccasions.toList(),
        seasons: _selectedSeasons.toList(),
        moods: _selectedMoods.toList(),
        fabric: _isClothing ? _selectedFabric : null,
        fit: _isClothing ? _selectedFit : null,
        pattern: _isClothing ? _selectedPattern : null,
        fabricWeight: _isClothing ? _selectedFabricWeight : null,
        sleeveLength: _showSleeveLength ? _selectedSleeveLength : null,
        details: _optional(_details.text),
        washInstructions: widget.garment?.washInstructions,
        wearCount: widget.garment?.wearCount ?? 0,
        lastWornDate: widget.garment?.lastWornDate,
        purchaseDate: _purchaseDate,
        laundryStatus: widget.garment?.laundryStatus ?? LaundryStatus.clean,
        ironingStatus: _isClothing ? _ironingStatus : null,
        stitchingStatus: _isClothing ? _stitchingStatus : null,
        availabilityStatus: _availabilityStatus,
        locationId: _selectedLocationId,
        isArchived: widget.garment?.isArchived ?? false,
      );

      await ref
          .read(garmentRepositoryProvider)
          .saveGarment(garment, isNew: widget.garment == null);
      await ref
          .read(lendingRepositoryProvider)
          .syncForAvailability(
            memberId: selectedMember.id,
            garmentId: garment.id,
            status: _availabilityStatus,
            personName: _lendingPerson.text,
            dateOut: _lendingDate,
            expectedReturnDate: _expectedReturnDate,
            notes: _lendingNotes.text,
          );
      if (_removedPhotoPaths.isNotEmpty) {
        try {
          final List<String> pathsToDelete = <String>[
            ..._removedPhotoPaths,
            ?_removedReceiptPath,
          ];
          await ref.read(garmentRepositoryProvider).deleteImages(pathsToDelete);
        } catch (error) {
          debugPrint('Could not remove old garment photos: $error');
        }
      }
      ref.invalidate(garmentsProvider);
      ref.invalidate(analyticsSummaryProvider);
      ref.invalidate(garmentLocationsProvider);
      ref.invalidate(activeLendingRecordProvider(id));

      if (widget.garment != null) {
        ref.invalidate(garmentProvider(widget.garment!.id));
      }

      if (mounted) {
        context.pop();
      }
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrint(stackTrace.toString());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _showAddLocationDialog() async {
    final selectedMember = ref.read(selectedFamilyMemberProvider);

    if (selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a profile before adding a location.'),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => _AddLocationDialog(
        onSave: (String name) async {
          final List<GarmentLocation> currentLocations =
              ref.read(garmentLocationsProvider).valueOrNull ??
              const <GarmentLocation>[];

          if (hasDuplicateLocationName(currentLocations, name)) {
            throw LocationNameConflict(name.trim());
          }

          final GarmentLocation location = await ref
              .read(garmentLocationRepositoryProvider)
              .createLocation(memberId: selectedMember.id, name: name);

          if (!mounted) {
            return;
          }

          setState(() {
            _selectedLocationId = location.id;
            _createdLocationFallback = location;
          });

          try {
            final List<GarmentLocation> refreshedLocations = await ref.refresh(
              garmentLocationsProvider.future,
            );
            if (!mounted) {
              return;
            }

            setState(() {
              _selectedLocationId = location.id;
              if (refreshedLocations.any(
                (GarmentLocation item) => item.id == location.id,
              )) {
                _createdLocationFallback = null;
              }
            });
          } catch (error) {
            debugPrint('Could not refresh garment locations: $error');
          }
        },
      ),
    );
  }

  String? _optional(String value) {
    final String trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }

  bool get _isLendingStatus =>
      _availabilityStatus == GarmentAvailabilityStatus.lent ||
      _availabilityStatus == GarmentAvailabilityStatus.borrowed;

  Future<void> _pickLendingDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _lendingDate ?? today,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year + 10),
      helpText: _availabilityStatus == GarmentAvailabilityStatus.borrowed
          ? 'When was this garment borrowed?'
          : 'When was this garment lent?',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _lendingDate = DateTime(picked.year, picked.month, picked.day);
      _lendingDateController.text = _formatDate(_lendingDate!);
    });
  }

  Future<void> _pickExpectedReturnDate() async {
    final DateTime today = DateTime.now();
    final DateTime base = _lendingDate ?? today;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedReturnDate ?? base,
      firstDate: base,
      lastDate: DateTime(today.year + 10),
      helpText: 'Expected Return Date',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _expectedReturnDate = DateTime(picked.year, picked.month, picked.day);
      _expectedReturnDateController.text = _formatDate(_expectedReturnDate!);
    });
  }

  bool get _showSleeveLength =>
      _category == GarmentCategory.top ||
      _category == GarmentCategory.dress ||
      _category == GarmentCategory.outerwear;

  bool get _showSizes =>
      _category == GarmentCategory.top ||
      _category == GarmentCategory.bottom ||
      _category == GarmentCategory.dress ||
      _category == GarmentCategory.outerwear ||
      _category == GarmentCategory.shoe;

  bool get _showSubcategory => true;

  bool get _isClothing =>
      _category == GarmentCategory.top ||
      _category == GarmentCategory.bottom ||
      _category == GarmentCategory.dress ||
      _category == GarmentCategory.outerwear;

  String get _subcategoryLabel => switch (_category) {
    GarmentCategory.top => 'Tops Subcategory',
    GarmentCategory.bottom => 'Bottoms Subcategory',
    GarmentCategory.dress => 'Dresses Subcategory',
    GarmentCategory.outerwear => 'Outerwear Subcategory',
    GarmentCategory.shoe => 'Shoe Type',
    GarmentCategory.bag => 'Bag Type',
    GarmentCategory.accessory => 'Accessory Type',
    GarmentCategory.jewelry => 'Jewelry Type',
    GarmentCategory.activewear => 'Activewear Type',
    GarmentCategory.sleepwear => 'Sleep/Loungewear Type',
    GarmentCategory.watches => 'Watch Type',
    GarmentCategory.other => 'Custom Label',
  };

  String get _sizeLabel =>
      _category == GarmentCategory.shoe ? 'Shoe Sizes' : 'Sizes';

  List<String> get _subcategoryOptions {
    final List<String> options = switch (_category) {
      GarmentCategory.top => _topSubcategoryOptions,
      GarmentCategory.bottom => _bottomSubcategoryOptions,
      GarmentCategory.dress => _dressSubcategoryOptions,
      GarmentCategory.outerwear => _outerwearSubcategoryOptions,
      GarmentCategory.shoe => _shoeSubcategoryOptions,
      GarmentCategory.bag => _bagSubcategoryOptions,
      GarmentCategory.accessory => _accessorySubcategoryOptions,
      GarmentCategory.jewelry => _jewelrySubcategoryOptions,
      GarmentCategory.activewear => _activewearSubcategoryOptions,
      GarmentCategory.sleepwear => _sleepwearSubcategoryOptions,
      GarmentCategory.watches => _watchesSubcategoryOptions,
      GarmentCategory.other => const <String>[],
    };

    return _optionsWithSavedValue(options, _selectedSubcategory);
  }

  List<String> _optionsWithSavedValue(List<String> options, String? saved) {
    if (saved == null || saved.isEmpty || options.contains(saved)) {
      return options;
    }

    return <String>[...options, saved];
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<GarmentLocation>> locations = ref.watch(
      garmentLocationsProvider,
    );

    final FamilyMember? selectedMember = ref.watch(
      selectedFamilyMemberProvider,
    );

    final bool memberMismatch =
        widget.garment != null &&
        widget.garment!.memberId != null &&
        selectedMember != null &&
        widget.garment!.memberId != selectedMember.id;

    if (memberMismatch) {
      _mismatchedGarmentMember = ref
          .watch(familyMemberProvider(widget.garment!.memberId!))
          .valueOrNull;
    } else {
      _mismatchedGarmentMember = null;
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: Text(widget.garment == null ? 'Add Garment' : 'Edit Garment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            if (memberMismatch) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.person_off_outlined,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This item belongs to "${_mismatchedGarmentMember?.name ?? 'another profile'}", '
                        'but "${selectedMember.name}" is currently selected. '
                        'Switch to ${_mismatchedGarmentMember?.name ?? 'its'} profile to edit this item.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Garment photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Add up to 3 photos. The first photo will be used as the cover.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  for (
                    int index = 0;
                    index < _existingPhotoUrls.length;
                    index++
                  )
                    _GarmentPhotoPreview(
                      imageUrl: _existingPhotoUrls[index],
                      isCover:
                          _selectedExistingCoverPath ==
                          _existingPhotoPaths[index],
                      onSetCover: _saving
                          ? null
                          : () => _setExistingPhotoAsCover(
                              _existingPhotoPaths[index],
                            ),
                      onRemove: _saving
                          ? null
                          : () => _removeExistingPhoto(index),
                    ),

                  for (int index = 0; index < _newImages.length; index++)
                    _GarmentPhotoPreview(
                      imageFile: File(_newImages[index].path),
                      isCover: _selectedNewCoverPath == _newImages[index].path,
                      onSetCover: _saving
                          ? null
                          : () => _setNewPhotoAsCover(_newImages[index]),
                      onRemove: _saving ? null : () => _removeNewPhoto(index),
                    ),

                  if (_existingPhotoPaths.length + _newImages.length <
                      _maximumPhotos)
                    _AddPhotoTile(onTap: _saving ? null : _chooseImages),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Main Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a name';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GarmentCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: GarmentCategory.values
                  .map(
                    (GarmentCategory category) =>
                        DropdownMenuItem<GarmentCategory>(
                          value: category,
                          child: Text(category.label),
                        ),
                  )
                  .toList(),
              onChanged: (GarmentCategory? value) {
                if (value != null) {
                  setState(() {
                    _category = value;
                    if (!_showSubcategory) {
                      _selectedSubcategory = null;
                    }
                    if (!_showSizes) {
                      _selectedSizes.clear();
                    }
                    if (!_showSleeveLength) {
                      _selectedSleeveLength = null;
                    }
                    if (_category == GarmentCategory.other) {
                      _subcategoryCustom.text = _selectedSubcategory ?? '';
                    }
                  });
                }
              },
            ),
            if (_showSubcategory) ...<Widget>[
              const SizedBox(height: 12),
              if (_category == GarmentCategory.other)
                TextFormField(
                  controller: _subcategoryCustom,
                  decoration: InputDecoration(
                    labelText: _subcategoryLabel,
                    hintText: 'Optional',
                  ),
                  onChanged: (String value) {
                    setState(() {
                      _selectedSubcategory = _cleanOptional(value);
                    });
                  },
                )
              else
                DropdownButtonFormField<String?>(
                  initialValue:
                      _subcategoryOptions.contains(_selectedSubcategory)
                      ? _selectedSubcategory
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _subcategoryLabel,
                    hintText: 'Optional',
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ..._subcategoryOptions.map(
                      (String value) => DropdownMenuItem<String?>(
                        value: value,
                        child: Text(value),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            _GarmentColorSelection(
              shades: _colorShades,
              showError: _showPrimaryColorError,
              onAdd: _saving ? null : _pickColor,
              onSetPrimary: _saving ? null : _setPrimaryShade,
              onRemove: _saving ? null : _removeColorShade,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GarmentAvailabilityStatus>(
              initialValue: _availabilityStatus,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Item Status'),
              items: GarmentAvailabilityStatus.values
                  .map(
                    (GarmentAvailabilityStatus status) =>
                        DropdownMenuItem<GarmentAvailabilityStatus>(
                          value: status,
                          child: Text(status.label),
                        ),
                  )
                  .toList(),
              onChanged: (GarmentAvailabilityStatus? value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _availabilityStatus = value;
                });
              },
            ),
            if (_isLendingStatus) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                controller: _lendingPerson,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText:
                      _availabilityStatus == GarmentAvailabilityStatus.borrowed
                      ? 'Borrowed From *'
                      : 'Lent To *',
                ),
                validator: (String? value) {
                  if (!_isLendingStatus) {
                    return null;
                  }

                  if ((value ?? '').trim().isEmpty) {
                    return _availabilityStatus ==
                            GarmentAvailabilityStatus.borrowed
                        ? 'Enter who this was borrowed from'
                        : 'Enter who this was lent to';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lendingDateController,
                readOnly: true,
                onTap: _saving ? null : _pickLendingDate,
                decoration: InputDecoration(
                  labelText:
                      _availabilityStatus == GarmentAvailabilityStatus.borrowed
                      ? 'Borrowed Date'
                      : 'Lent Date',
                  hintText: 'Defaults to today',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expectedReturnDateController,
                readOnly: true,
                onTap: _saving ? null : _pickExpectedReturnDate,
                decoration: InputDecoration(
                  labelText: 'Expected Return Date',
                  hintText: 'Optional',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: _expectedReturnDate == null
                      ? null
                      : IconButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  setState(() {
                                    _expectedReturnDate = null;
                                    _expectedReturnDateController.clear();
                                  });
                                },
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear Expected Return Date',
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lendingNotes,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional',
                  alignLabelWithHint: true,
                ),
              ),
            ],
            const SizedBox(height: 12),
            locations.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => OutlinedButton.icon(
                onPressed: () => ref.invalidate(garmentLocationsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Locations'),
              ),
              data: (List<GarmentLocation> items) {
                final List<GarmentLocation> locationItems = <GarmentLocation>[
                  ...items,
                ];
                final GarmentLocation? fallback = _createdLocationFallback;
                if (fallback != null &&
                    !locationItems.any(
                      (GarmentLocation location) => location.id == fallback.id,
                    )) {
                  locationItems.add(fallback);
                }

                final bool containsSelected = locationItems.any(
                  (GarmentLocation location) =>
                      location.id == _selectedLocationId,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        key: ValueKey<String?>(
                          containsSelected ? _selectedLocationId : null,
                        ),
                        initialValue: containsSelected
                            ? _selectedLocationId
                            : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'Optional',
                        ),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Not Specified'),
                          ),
                          ...locationItems.map(
                            (GarmentLocation location) =>
                                DropdownMenuItem<String?>(
                                  value: location.id,
                                  child: Text(location.name),
                                ),
                          ),
                          const DropdownMenuItem<String?>(
                            value: _addNewLocationValue,
                            child: Text('+ Add New Location'),
                          ),
                        ],
                        onChanged: (String? value) async {
                          if (value == _addNewLocationValue) {
                            await Future<void>.delayed(Duration.zero);
                            if (!mounted) {
                              return;
                            }
                            await _showAddLocationDialog();
                            return;
                          }

                          setState(() {
                            _selectedLocationId = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: _saving
                          ? null
                          : () => context.push('/garment-locations'),
                      icon: const Icon(Icons.settings_outlined),
                      tooltip: 'Manage Locations',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (_showSizes) ...<Widget>[
              _ChipMultiSelect(
                title: _sizeLabel,
                options: _sizeItems,
                labelFor: (String value) => value,
                selected: _selectedSizes,
                enabled: !_saving,
                onChanged: (Set<String> values) {
                  setState(() {
                    _selectedSizes
                      ..clear()
                      ..addAll(values);
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Text('Seasons', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Choose the suitable seasons. Optional.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _seasonOptions.map((String season) {
                final bool selected = _selectedSeasons.contains(season);

                return FilterChip(
                  label: Text(season[0].toUpperCase() + season.substring(1)),
                  selected: selected,
                  onSelected: _saving
                      ? null
                      : (bool value) {
                          setState(() {
                            if (value) {
                              _selectedSeasons.add(season);
                            } else {
                              _selectedSeasons.remove(season);
                            }
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (_isClothing)
              DropdownButtonFormField<String?>(
                initialValue: _selectedFabric,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Fabric',
                  hintText: 'Select a fabric (optional)',
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not specified'),
                  ),
                  ..._fabricDropdownItems.map(
                    (String fabric) => DropdownMenuItem<String?>(
                      value: fabric,
                      child: Text(fabric),
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _selectedFabric = value;
                  });
                },
              ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () {
                setState(() {
                  _advancedOptionsExpanded = !_advancedOptionsExpanded;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Advanced Options',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      _advancedOptionsExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                  ],
                ),
              ),
            ),
            if (_advancedOptionsExpanded) ...<Widget>[
              const SizedBox(height: 12),
              _ChipMultiSelect(
                title: 'Mood and style',
                options: _moodOptions,
                labelFor: (String value) =>
                    value[0].toUpperCase() + value.substring(1),
                selected: _selectedMoods,
                enabled: !_saving,
                onChanged: (Set<String> values) {
                  setState(() {
                    _selectedMoods
                      ..clear()
                      ..addAll(values);
                  });
                },
              ),
              const SizedBox(height: 12),
              _ChipMultiSelect(
                title: 'Occasions',
                options: _occasionOptions,
                labelFor: (String value) =>
                    value[0].toUpperCase() + value.substring(1),
                selected: _selectedOccasions,
                enabled: !_saving,
                onChanged: (Set<String> values) {
                  setState(() {
                    _selectedOccasions
                      ..clear()
                      ..addAll(values);
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_isClothing) ...<Widget>[
                DropdownButtonFormField<StitchingStatus?>(
                  initialValue: _stitchingStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Stitching Status',
                    hintText: 'Optional',
                  ),
                  items: <DropdownMenuItem<StitchingStatus?>>[
                    const DropdownMenuItem<StitchingStatus?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ...StitchingStatus.values.map(
                      (StitchingStatus status) =>
                          DropdownMenuItem<StitchingStatus?>(
                            value: status,
                            child: Text(status.label),
                          ),
                    ),
                  ],
                  onChanged: (StitchingStatus? value) {
                    setState(() {
                      _stitchingStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<IroningStatus?>(
                  initialValue: _ironingStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ironing Status',
                    hintText: 'Optional',
                  ),
                  items: <DropdownMenuItem<IroningStatus?>>[
                    const DropdownMenuItem<IroningStatus?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ...IroningStatus.values.map(
                      (IroningStatus status) =>
                          DropdownMenuItem<IroningStatus?>(
                            value: status,
                            child: Text(status.label),
                          ),
                    ),
                  ],
                  onChanged: (IroningStatus? value) {
                    setState(() {
                      _ironingStatus = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedFit,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Fit',
                    hintText: 'Select a fit (optional)',
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ..._optionsWithSavedValue(_fitOptions, _selectedFit).map(
                      (String fit) => DropdownMenuItem<String?>(
                        value: fit,
                        child: Text(fit),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFit = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedPattern,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pattern',
                    hintText: 'Select a pattern (optional)',
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ..._optionsWithSavedValue(
                      _patternOptions,
                      _selectedPattern,
                    ).map(
                      (String pattern) => DropdownMenuItem<String?>(
                        value: pattern,
                        child: Text(pattern),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedPattern = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedFabricWeight,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Fabric Weight',
                    hintText: 'Select a fabric weight (optional)',
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ..._optionsWithSavedValue(
                      _fabricWeightOptions,
                      _selectedFabricWeight,
                    ).map(
                      (String weight) => DropdownMenuItem<String?>(
                        value: weight,
                        child: Text(weight),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedFabricWeight = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (_showSleeveLength) ...<Widget>[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedSleeveLength,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sleeve Length',
                    hintText: 'Select a sleeve length (optional)',
                  ),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Not specified'),
                    ),
                    ..._optionsWithSavedValue(
                      _sleeveLengthOptions,
                      _selectedSleeveLength,
                    ).map(
                      (String sleeveLength) => DropdownMenuItem<String?>(
                        value: sleeveLength,
                        child: Text(sleeveLength),
                      ),
                    ),
                  ],
                  onChanged: (String? value) {
                    setState(() {
                      _selectedSleeveLength = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _details,
                maxLength: _maximumDetailsLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  hintText: 'Optional extra information about this garment',
                  alignLabelWithHint: true,
                ),
                validator: (String? value) {
                  if ((value ?? '').characters.length > _maximumDetailsLength) {
                    return 'Details must be $_maximumDetailsLength characters '
                        'or fewer';
                  }

                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Purchase Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purchaseStore,
              decoration: const InputDecoration(
                labelText: 'Store And Location',
                hintText: 'For example: Outfitters - Centaurus Mall, Islamabad',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purchaseDateController,
              readOnly: true,
              onTap: _saving ? null : _pickPurchaseDate,
              decoration: InputDecoration(
                labelText: 'Purchase Date',
                hintText: 'Optional',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                suffixIcon: _purchaseDate == null
                    ? null
                    : IconButton(
                        onPressed: _saving ? null : _clearPurchaseDate,
                        icon: const Icon(Icons.close),
                        tooltip: 'Clear purchase date',
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price (PKR)'),
              validator: (String? value) {
                final String enteredPrice = value?.trim() ?? '';

                if (enteredPrice.isEmpty) {
                  return null;
                }

                final double? parsedPrice = double.tryParse(enteredPrice);

                if (parsedPrice == null) {
                  return 'Enter a valid price';
                }

                if (parsedPrice < 0) {
                  return 'Price cannot be negative';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            _ReceiptAttachment(
              receiptUrl: _existingReceiptUrl,
              receiptFile: _newReceiptFile,
              enabled: !_saving,
              onAdd: _pickReceipt,
              onRemove: _removeReceipt,
            ),

            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: (_saving || memberMismatch) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Saving Item...' : 'Save Item'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipMultiSelect extends StatelessWidget {
  const _ChipMultiSelect({
    required this.title,
    required this.options,
    required this.labelFor,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final String Function(String value) labelFor;
  final Set<String> selected;
  final bool enabled;
  final ValueChanged<Set<String>> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final Set<String>? result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return _StringPickerSheet(
          title: title,
          options: options,
          labelFor: labelFor,
          selected: selected,
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: title, hintText: 'Optional'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final String value in selected)
            InputChip(
              label: Text(labelFor(value)),
              onDeleted: enabled
                  ? () {
                      final Set<String> updated = <String>{...selected}
                        ..remove(value);
                      onChanged(updated);
                    }
                  : null,
            ),
          ActionChip(
            avatar: const Icon(Icons.add),
            label: const Text('Add'),
            onPressed: enabled ? () => _openPicker(context) : null,
          ),
        ],
      ),
    );
  }
}

class _StringPickerSheet extends StatefulWidget {
  const _StringPickerSheet({
    required this.title,
    required this.options,
    required this.labelFor,
    required this.selected,
  });

  final String title;
  final List<String> options;
  final String Function(String value) labelFor;
  final Set<String> selected;

  @override
  State<_StringPickerSheet> createState() => _StringPickerSheetState();
}

class _StringPickerSheetState extends State<_StringPickerSheet> {
  late final Set<String> _pending = <String>{...widget.selected};

  void _toggle(String value) {
    setState(() {
      if (_pending.contains(value)) {
        _pending.remove(value);
      } else {
        _pending.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _pending),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: widget.options.map((String value) {
                  final bool isSelected = _pending.contains(value);

                  return FilterChip(
                    label: Text(widget.labelFor(value)),
                    selected: isSelected,
                    onSelected: (_) => _toggle(value),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReceiptAttachment extends StatelessWidget {
  const _ReceiptAttachment({
    required this.receiptUrl,
    required this.receiptFile,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final String? receiptUrl;
  final XFile? receiptFile;
  final bool enabled;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool hasReceipt = receiptUrl != null || receiptFile != null;

    return InputDecorator(
      decoration: const InputDecoration(labelText: 'Receipt Attachment'),
      child: hasReceipt
          ? Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 44,
                    child: receiptFile != null
                        ? Image.file(File(receiptFile!.path), fit: BoxFit.cover)
                        : Image.network(
                            receiptUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) {
                              return const ColoredBox(
                                color: Colors.black12,
                                child: Icon(Icons.receipt_long_outlined),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    receiptFile != null
                        ? receiptFile!.name
                        : 'Receipt attached',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (enabled)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove receipt',
                  ),
              ],
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: enabled ? onAdd : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add receipt'),
              ),
            ),
    );
  }
}

class _GarmentPhotoPreview extends StatelessWidget {
  const _GarmentPhotoPreview({
    this.imageUrl,
    this.imageFile,
    required this.isCover,
    required this.onSetCover,
    required this.onRemove,
  });

  final String? imageUrl;
  final File? imageFile;
  final bool isCover;
  final VoidCallback? onSetCover;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 130,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            InkWell(
              onTap: isCover ? null : onSetCover,
              borderRadius: BorderRadius.circular(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageFile != null
                    ? Image.file(imageFile!, fit: BoxFit.cover)
                    : Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return const ColoredBox(
                            color: Colors.black12,
                            child: Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
              ),
            ),
            if (isCover)
              Positioned(
                left: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Cover'),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filledTonal(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
                tooltip: 'Remove photo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.add_a_photo_outlined, size: 32),
              SizedBox(height: 8),
              Text('Add photo'),
            ],
          ),
        ),
      ),
    );
  }
}

Color? _colorFromHex(String? hex) {
  final String cleaned = (hex ?? '').replaceFirst('#', '').trim();

  if (cleaned.length != 6) {
    return null;
  }

  final int? value = int.tryParse(cleaned, radix: 16);

  if (value == null) {
    return null;
  }

  return Color(0xFF000000 | value);
}

class _GarmentColorSelection extends StatelessWidget {
  const _GarmentColorSelection({
    required this.shades,
    required this.showError,
    required this.onAdd,
    required this.onSetPrimary,
    required this.onRemove,
  });

  final List<GarmentColorShade> shades;
  final bool showError;
  final VoidCallback? onAdd;
  final ValueChanged<GarmentColorShade>? onSetPrimary;
  final ValueChanged<GarmentColorShade>? onRemove;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Shades *',
        errorText: showError && shades.isEmpty
            ? 'Select at least one shade'
            : null,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          for (final GarmentColorShade shade in shades)
            InputChip(
              avatar: CircleAvatar(
                backgroundColor: _colorFromHex(shade.hex),
                child: shade.isPrimary
                    ? Icon(
                        Icons.star,
                        size: 14,
                        color:
                            (_colorFromHex(shade.hex)?.computeLuminance() ??
                                    0) >
                                0.5
                            ? Colors.black87
                            : Colors.white,
                      )
                    : null,
              ),
              label: Text(
                shade.isPrimary ? '${shade.name} (Primary)' : shade.name,
              ),
              onPressed: shade.isPrimary || onSetPrimary == null
                  ? null
                  : () => onSetPrimary!(shade),
              onDeleted: onRemove == null ? null : () => onRemove!(shade),
            ),
          ActionChip(
            avatar: const Icon(Icons.add),
            label: const Text('Add'),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

extension _PrimaryShadeList on List<GarmentColorShade> {
  GarmentColorShade? get primaryShadeOrNull {
    if (isEmpty) {
      return null;
    }

    return firstWhere(
      (GarmentColorShade shade) => shade.isPrimary,
      orElse: () => first,
    );
  }
}

class _GarmentColorPickerSheet extends StatelessWidget {
  const _GarmentColorPickerSheet({
    required this.title,
    required this.selectedNames,
  });

  final String title;
  final Set<String> selectedNames;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scrollController) {
        return Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  for (final GarmentColorFamily family
                      in GarmentColorPalette.families)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            family.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 16,
                            children: family.colors
                                .map(
                                  (GarmentColorOption option) =>
                                      _GarmentColorSwatch(
                                        option: option,
                                        isSelected: selectedNames.any(
                                          (String selected) =>
                                              selected.toLowerCase() ==
                                              option.name.toLowerCase(),
                                        ),
                                      ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AddLocationDialog extends StatefulWidget {
  const _AddLocationDialog({required this.onSave});

  final Future<void> Function(String name) onSave;

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Location'),
      content: TextField(
        controller: _controller,
        enabled: !_saving,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Location Name',
          hintText: 'Bedroom Almirah',
        ).copyWith(errorText: _errorText),
        onSubmitted: _saving ? null : (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }

    final String name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorText = 'Enter a location name';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _errorText = null;
    });

    try {
      await widget.onSave(name);
      if (mounted) {
        Navigator.pop(context);
      }
    } on LocationNameConflict catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorText = error.message;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorText = error.code == '23505'
            ? 'A location named "$name" already exists.'
            : 'Could not add this location';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorText = 'Could not add this location';
      });
    }
  }
}

class _GarmentColorSwatch extends StatelessWidget {
  const _GarmentColorSwatch({required this.option, required this.isSelected});

  final GarmentColorOption option;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Color swatch = _colorFromHex(option.hex)!;
    final bool lightSwatch = swatch.computeLuminance() > 0.5;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.pop(context, option),
      child: SizedBox(
        width: 72,
        child: Column(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: lightSwatch ? Colors.black87 : Colors.white,
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              option.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
