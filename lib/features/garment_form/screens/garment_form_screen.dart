import 'dart:io';
import 'dart:typed_data';
import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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

  late final TextEditingController _color = TextEditingController(
    text: widget.garment?.colorName,
  );

  static const List<String> _sizeOptions = <String>[
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

  late String? _selectedSize = widget.garment?.size?.trim().isEmpty == true
      ? null
      : widget.garment?.size?.trim();

  late final List<String> _sizeDropdownItems = _buildSizeDropdownItems();

  List<String> _buildSizeDropdownItems() {
    final String? savedSize = widget.garment?.size?.trim();

    if (savedSize == null || savedSize.isEmpty) {
      return _sizeOptions;
    }

    return _sizeOptions.contains(savedSize)
        ? _sizeOptions
        : <String>[..._sizeOptions, savedSize];
  }

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
  static const List<String> _occasionOptions = <String>[
    'casual',
    'work',
    'formal',
    'party',
    'wedding',
    'college',
    'sport',
    'travel',
    'home',
    'sleep',
    'ethnic',
  ];

  static const List<String> _seasonOptions = <String>[
    'summer',
    'winter',
    'spring',
    'autumn',
    'rainy',
    'all_season',
  ];

  static const List<String> _moodOptions = <String>[
    'relaxed',
    'professional',
    'cozy',
    'elegant',
    'sporty',
    'minimal',
    'bold',
    'party',
  ];
  late final Set<String> _selectedOccasions = <String>{
    ...?widget.garment?.occasions,
  };

  late final Set<String> _selectedSeasons = <String>{
    ...?widget.garment?.seasons,
  };

  late final Set<String> _selectedMoods = <String>{...?widget.garment?.moods};

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _purchaseStore.dispose();
    _color.dispose();
    _price.dispose();
    _purchaseDateController.dispose();
    super.dispose();
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

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(sheetContext, ImageSource.gallery);
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

    if (source == ImageSource.camera) {
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
        widget.garment!.memberId != selectedMember.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This garment does not belong to the selected profile.',
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
        subcategory: widget.garment?.subcategory,
        brand: _optional(_brand.text),
        purchaseStore: _optional(_purchaseStore.text),
        colorName: _optional(_color.text),
        colorHex: widget.garment?.colorHex,
        size: _selectedSize,
        price: double.tryParse(_price.text.trim()),
        currency: widget.garment?.currency ?? 'PKR',
        occasions: _selectedOccasions.toList(),
        seasons: _selectedSeasons.toList(),
        moods: _selectedMoods.toList(),
        fabric: widget.garment?.fabric,
        washInstructions: widget.garment?.washInstructions,
        wearCount: widget.garment?.wearCount ?? 0,
        lastWornDate: widget.garment?.lastWornDate,
        purchaseDate: _purchaseDate,
        laundryStatus: widget.garment?.laundryStatus ?? LaundryStatus.clean,
        isArchived: widget.garment?.isArchived ?? false,
      );

      await ref
          .read(garmentRepositoryProvider)
          .saveGarment(garment, isNew: widget.garment == null);
      if (_removedPhotoPaths.isNotEmpty) {
        try {
          await ref
              .read(garmentRepositoryProvider)
              .deleteImages(_removedPhotoPaths);
        } catch (error) {
          debugPrint('Could not remove old garment photos: $error');
        }
      }
      ref.invalidate(garmentsProvider);

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

  String? _optional(String value) {
    final String trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.garment == null ? 'Add garment' : 'Edit garment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
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
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purchaseStore,
              decoration: const InputDecoration(
                labelText: 'Store and location',
                hintText: 'For example: Outfitters - Centaurus Mall, Islamabad',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _color,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSize,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Size',
                hintText: 'Select a size (optional)',
              ),
              items: _sizeDropdownItems
                  .map(
                    (String size) => DropdownMenuItem<String>(
                      value: size,
                      child: Text(size),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _selectedSize = value;
                  });
                }
              },
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
            const SizedBox(height: 20),
            Text('Occasions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Choose where this garment can be worn. Optional.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _occasionOptions.map((String occasion) {
                final bool selected = _selectedOccasions.contains(occasion);

                return FilterChip(
                  label: Text(
                    occasion[0].toUpperCase() + occasion.substring(1),
                  ),
                  selected: selected,
                  onSelected: _saving
                      ? null
                      : (bool value) {
                          setState(() {
                            if (value) {
                              _selectedOccasions.add(occasion);
                            } else {
                              _selectedOccasions.remove(occasion);
                            }
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            Text(
              'Mood and style',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Choose the moods this garment represents. Optional.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moodOptions.map((String mood) {
                final bool selected = _selectedMoods.contains(mood);

                return FilterChip(
                  label: Text(mood[0].toUpperCase() + mood.substring(1)),
                  selected: selected,
                  onSelected: _saving
                      ? null
                      : (bool value) {
                          setState(() {
                            if (value) {
                              _selectedMoods.add(mood);
                            } else {
                              _selectedMoods.remove(mood);
                            }
                          });
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),
            TextFormField(
              controller: _purchaseDateController,
              readOnly: true,
              onTap: _saving ? null : _pickPurchaseDate,
              decoration: InputDecoration(
                labelText: 'Purchase date',
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
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save garment'),
            ),
          ],
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
