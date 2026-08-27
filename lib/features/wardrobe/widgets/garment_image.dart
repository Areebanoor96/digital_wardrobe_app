import 'package:flutter/material.dart';

class GarmentImage extends StatelessWidget {
  const GarmentImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.aspectRatio,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final Widget image;

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      image = const ColoredBox(
        color: Color(0xFFF4F4F8),
        child: Center(child: Icon(Icons.checkroom_outlined, size: 36)),
      );
    } else {
      image = Image.network(
        imageUrl!,
        fit: fit,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: Color(0xFFF4F4F8),
          child: Center(child: Icon(Icons.broken_image_outlined)),
        ),
      );
    }

    if (aspectRatio == null) {
      return image;
    }

    return AspectRatio(aspectRatio: aspectRatio!, child: image);
  }
}
