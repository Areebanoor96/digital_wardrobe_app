import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter/material.dart';

class OotdCard extends StatelessWidget {
  const OotdCard({
    super.key,
    required this.recommendation,
    required this.onRefresh,
    required this.outfitContext,
    required this.onContextChanged,
    this.onSave,
    this.onWear,
    this.isSaving = false,
    this.isWearing = false,
  });

  final OutfitRecommendation recommendation;
  final VoidCallback onRefresh;
  final VoidCallback? onSave;
  final VoidCallback? onWear;
  final bool isSaving;
  final bool isWearing;
  final OutfitContext outfitContext;
  final ValueChanged<OutfitContext> onContextChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<Garment> items = recommendation.garments;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Outfit of the Day',

                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      if (recommendation.score > 0) ...<Widget>[
                        Text(
                          '${recommendation.score}% match',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showPersonalizeSheet(context),
                  icon: const Icon(Icons.tune),
                  tooltip: 'Personalize outfit',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh suggestion',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  recommendation.reason,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final Garment g = items[index];
                    final bool isHero = g.id == recommendation.heroGarment?.id;
                    return SizedBox(
                      width: 72,
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: GarmentImage(
                                    imageUrl: g.coverImageUrl,
                                  ),
                                ),

                                if (isHero)
                                  const Positioned(
                                    top: 4,
                                    right: 4,
                                    child: CircleAvatar(
                                      radius: 10,
                                      child: Icon(Icons.star, size: 12),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            g.name,
                            style: Theme.of(context).textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recommendation.reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (recommendation.reasons.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),

                Text(
                  'Why this works',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 4),

                ...recommendation.reasons
                    .take(3)
                    .map(
                      (String reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Icon(Icons.check_circle_outline, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                reason,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSaving ? null : onSave,
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bookmark_outline, size: 18),
                      label: Text(isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isWearing ? null : onWear,
                      icon: isWearing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(isWearing ? 'Wearing...' : 'Wear'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPersonalizeSheet(BuildContext context) async {
    String? selectedOccasion = outfitContext.occasion;
    String? selectedSeason = outfitContext.season;
    String? selectedMood = outfitContext.mood;

    final OutfitContext?
    updatedContext = await showModalBottomSheet<OutfitContext>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Personalize today\'s outfit',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose an occasion, season and mood.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: selectedOccasion,
                      decoration: const InputDecoration(labelText: 'Occasion'),
                      items:
                          const <String>[
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
                              ]
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value[0].toUpperCase() + value.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (String? value) {
                        setModalState(() {
                          selectedOccasion = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedSeason,
                      decoration: const InputDecoration(labelText: 'Season'),
                      items:
                          const <String>[
                                'summer',
                                'winter',
                                'spring',
                                'autumn',
                                'rainy',
                                'all',
                              ]
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value
                                        .replaceAll('_', ' ')
                                        .split(' ')
                                        .map(
                                          (String word) =>
                                              word[0].toUpperCase() +
                                              word.substring(1),
                                        )
                                        .join(' '),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (String? value) {
                        setModalState(() {
                          selectedSeason = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMood,
                      decoration: const InputDecoration(labelText: 'Mood'),
                      items:
                          const <String>[
                                'relaxed',
                                'professional',
                                'cozy',
                                'elegant',
                                'sporty',
                                'minimal',
                                'bold',
                                'party',
                              ]
                              .map(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value[0].toUpperCase() + value.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (String? value) {
                        setModalState(() {
                          selectedMood = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(sheetContext, const OutfitContext());
                          },
                          child: const Text('Clear'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              OutfitContext(
                                occasion: selectedOccasion,
                                season: selectedSeason,
                                mood: selectedMood,
                              ),
                            );
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (updatedContext != null) {
      onContextChanged(updatedContext);
    }
  }
}
