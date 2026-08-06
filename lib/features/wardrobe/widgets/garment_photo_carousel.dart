import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';

class GarmentPhotoCarousel extends StatefulWidget {
  const GarmentPhotoCarousel({super.key, required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<GarmentPhotoCarousel> createState() => _GarmentPhotoCarouselState();
}

class _GarmentPhotoCarouselState extends State<GarmentPhotoCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.photoUrls.isEmpty) {
      return const AspectRatio(
        aspectRatio: 1,
        child: GarmentImage(imageUrl: null),
      );
    }

    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            itemCount: widget.photoUrls.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (BuildContext context, int index) {
              return GarmentImage(imageUrl: widget.photoUrls[index]);
            },
          ),
        ),
        if (widget.photoUrls.length > 1) ...<Widget>[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(widget.photoUrls.length, (
              int index,
            ) {
              final bool selected = index == _currentPage;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 18 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
