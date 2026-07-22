import 'package:flutter/material.dart';

class GarmentImage extends StatelessWidget {
  const GarmentImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });
  final String? imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const ColoredBox(
        color: Color(0xFFF4F4F8),
        child: Center(child: Icon(Icons.checkroom_outlined, size: 36)),
      );
    }
    return Image.network(
      imageUrl!,
      fit: fit,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFF4F4F8),
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}
