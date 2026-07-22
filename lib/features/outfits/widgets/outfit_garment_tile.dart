import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';

class OutfitGarmentTile extends StatelessWidget {
  const OutfitGarmentTile({super.key, required this.garment});
  final Garment garment;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: SizedBox(
      width: 48,
      height: 48,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GarmentImage(imageUrl: garment.coverImageUrl),
      ),
    ),
    title: Text(garment.name),
    subtitle: Text(garment.category.label),
  );
}
