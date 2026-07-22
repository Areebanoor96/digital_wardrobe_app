import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';

class OutfitPreviewGrid extends StatelessWidget {
  const OutfitPreviewGrid({super.key, required this.garments, this.size = 72});
  final List<Garment> garments;
  final double size;

  @override
  Widget build(BuildContext context) {
    final List<Garment> preview = garments.take(4).toList();
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: preview.isEmpty
            ? const GarmentImage(imageUrl: null)
            : GridView.count(
                crossAxisCount: preview.length == 1 ? 1 : 2,
                physics: const NeverScrollableScrollPhysics(),
                children: preview
                    .map(
                      (Garment garment) =>
                          GarmentImage(imageUrl: garment.coverImageUrl),
                    )
                    .toList(),
              ),
      ),
    );
  }
}
