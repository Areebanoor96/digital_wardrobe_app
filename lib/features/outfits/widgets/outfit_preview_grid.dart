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
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: preview.isEmpty
            ? const GarmentImage(imageUrl: null)
            : GridView.count(
          crossAxisCount: preview.length == 1 ? 1 : 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
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
