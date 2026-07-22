import 'dart:io';

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
  late final TextEditingController _color = TextEditingController(
    text: widget.garment?.colorName,
  );
  late final TextEditingController _size = TextEditingController(
    text: widget.garment?.size,
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.garment?.price?.toString(),
  );
  late GarmentCategory _category =
      widget.garment?.category ?? GarmentCategory.top;
  XFile? _image;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _color.dispose();
    _size.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final XFile? image = source == ImageSource.camera
        ? await ref.read(imageServiceProvider).takePhoto()
        : await ref.read(imageServiceProvider).pickFromGallery();
    if (image != null && mounted) {
      setState(() => _image = image);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final String id = widget.garment?.id ?? const Uuid().v4();
      List<String> photoPaths = widget.garment?.photoPaths ?? const <String>[];
      if (_image != null) {
        photoPaths = <String>[
          await ref
              .read(garmentRepositoryProvider)
              .uploadImage(
                garmentId: id,
                bytes: await ref.read(imageServiceProvider).readBytes(_image!),
              ),
        ];
      }
      final Garment garment = Garment(
        id: id,
        name: _name.text.trim(),
        category: _category,
        photoPaths: photoPaths,
        photoUrls: widget.garment?.photoUrls ?? const <String>[],
        subcategory: widget.garment?.subcategory,
        brand: _optional(_brand.text),
        colorName: _optional(_color.text),
        colorHex: widget.garment?.colorHex,
        size: _optional(_size.text),
        price: double.tryParse(_price.text),
        currency: widget.garment?.currency ?? 'PKR',
        occasions: widget.garment?.occasions ?? const <String>[],
        seasons: widget.garment?.seasons ?? const <String>[],
        moods: widget.garment?.moods ?? const <String>[],
        fabric: widget.garment?.fabric,
        washInstructions: widget.garment?.washInstructions,
        wearCount: widget.garment?.wearCount ?? 0,
        lastWornDate: widget.garment?.lastWornDate,
        purchaseDate: widget.garment?.purchaseDate,
        laundryStatus: widget.garment?.laundryStatus ?? LaundryStatus.clean,
        isArchived: widget.garment?.isArchived ?? false,
      );
      await ref
          .read(garmentRepositoryProvider)
          .saveGarment(garment, isNew: widget.garment == null);
      ref.invalidate(garmentsProvider);
      if (widget.garment != null) {
        ref.invalidate(garmentProvider(widget.garment!.id));
      }
      if (mounted) {
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this garment.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.garment == null ? 'Add garment' : 'Edit garment'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          GestureDetector(
            onTap: _chooseImage,
            child: AspectRatio(
              aspectRatio: 1.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _image == null
                    ? GarmentImage(imageUrl: widget.garment?.coverImageUrl)
                    : Image.file(
                        File(_image!.path),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _chooseImage,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(
              _image == null && widget.garment?.coverImageUrl == null
                  ? 'Add a photo'
                  : 'Change photo',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name *'),
            validator: (String? value) =>
                value == null || value.trim().isEmpty ? 'Enter a name' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<GarmentCategory>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category *'),
            items: GarmentCategory.values
                .map(
                  (GarmentCategory category) => DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: (GarmentCategory? value) =>
                setState(() => _category = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _brand,
            decoration: const InputDecoration(labelText: 'Brand'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _color,
            decoration: const InputDecoration(labelText: 'Color'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _size,
            decoration: const InputDecoration(labelText: 'Size'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Price (PKR)'),
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
