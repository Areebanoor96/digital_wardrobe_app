import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/wardrobe/widgets/garment_image.dart';
import 'package:flutter/material.dart';

class OotdCard extends StatefulWidget {
  const OotdCard({
    super.key,
    required this.recommendation,
    this.onRefresh,
    required this.outfitContext,
    this.onContextChanged,
    this.onSave,
    this.onWear,
    this.isSaving = false,
    this.isWearing = false,
  });

  final OutfitRecommendation recommendation;
  final VoidCallback? onRefresh;
  final ValueChanged<OutfitRecommendation>? onSave;
  final ValueChanged<OutfitRecommendation>? onWear;
  final bool isSaving;
  final bool isWearing;
  final OutfitContext outfitContext;
  final ValueChanged<OutfitContext>? onContextChanged;

  @override
  State<OotdCard> createState() => _OotdCardState();
}

class _OotdCardState extends State<OotdCard> {
  int _selectedIndex = 0;

  /// The full recommendation set: best match plus its alternatives.
  List<OutfitRecommendation> get _pool => <OutfitRecommendation>[
    widget.recommendation,
    ...widget.recommendation.alternatives,
  ];

  OutfitRecommendation get _current {
    final List<OutfitRecommendation> pool = _pool;
    if (_selectedIndex >= pool.length) {
      return pool.last;
    }
    return pool[_selectedIndex];
  }

  @override
  void didUpdateWidget(OotdCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recommendation != widget.recommendation) {
      _selectedIndex = 0;
    }
  }

  void _select(int index) {
    if (index < 0 || index >= _pool.length || index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<OutfitRecommendation> pool = _pool;
    final OutfitRecommendation rec = _current;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.primary.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    _headlinePill(
                      colors: colors,
                      theme: theme,
                      icon: Icons.auto_awesome,
                      label: 'Outfit of the Day',
                      background: colors.primaryContainer,
                      foreground: colors.onPrimaryContainer,
                    ),
                    if (rec.score > 0)
                      _headlinePill(
                        colors: colors,
                        theme: theme,
                        label: '${rec.score}% match',
                        background: colors.primary,
                        foreground: colors.onPrimary,
                        bold: true,
                      ),
                  ],
                ),
                if (rec.garments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _showWhySheet(context),
                          icon: const Icon(Icons.insights_outlined),
                          tooltip: 'Why this look?',
                          visualDensity: VisualDensity.compact,
                        ),
                        if (widget.onContextChanged != null)
                          IconButton(
                            onPressed: () => _showPersonalizeSheet(context),
                            icon: const Icon(Icons.tune),
                            tooltip: 'Personalize outfit',
                            visualDensity: VisualDensity.compact,
                          ),
                        if (widget.onRefresh != null)
                          IconButton.filledTonal(
                            onPressed: widget.onRefresh,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'New look',
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (rec.garments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  rec.reason,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              )
            else ...<Widget>[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey<String>(_stripKey(rec)),
                  child: _GarmentStrip(rec: rec),
                ),
              ),
              if (pool.length > 1) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (int index = 0; index < pool.length; index++)
                      FilterChip(
                        selected: index == _selectedIndex,
                        showCheckmark: false,
                        avatar: Icon(
                          index == _selectedIndex
                              ? Icons.check
                              : Icons.swap_horiz,
                          size: 16,
                        ),
                        label: Text(
                          '${pool[index].label} ${pool[index].score}%',
                        ),
                        onSelected: (_) => _select(index),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.isSaving ? null : () => widget.onSave?.call(rec),
                      icon: widget.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.bookmark_outline, size: 18),
                      label: Text(widget.isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.isWearing ? null : () => widget.onWear?.call(rec),
                      icon: widget.isWearing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(widget.isWearing ? 'Wearing...' : 'Wear'),
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

  Widget _headlinePill({
    required ColorScheme colors,
    required ThemeData theme,
    required String label,
    required Color background,
    required Color foreground,
    IconData? icon,
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: (bold
                      ? theme.textTheme.labelMedium
                      : theme.textTheme.labelSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _stripKey(OutfitRecommendation rec) {
    return rec.garments.map((Garment garment) => garment.id).join('|');
  }

  Future<void> _showWhySheet(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final OutfitRecommendation rec = _current;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Why this look?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rec.score}% match — ${rec.label}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (rec.reasons.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 20),
                  Text(
                    'Why this works',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...rec.reasons.map(
                    (String reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reason,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Score breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ..._scoreBreakdown(rec, theme: theme, colors: colors),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _scoreBreakdown(
    OutfitRecommendation rec, {
    required ThemeData theme,
    required ColorScheme colors,
  }) {
    final List<(String label, int value)> rows = <(String, int)>[
      ('Weather fit', rec.weatherScore),
      ('Occasion fit', rec.occasionScore),
      ('Color harmony', rec.colorScore),
      ('Style match', rec.styleScore),
      ('Rotation balance', rec.rotationScore),
      ('Preference match', rec.preferenceScore),
      ('Season fit', rec.seasonScore),
      ('Novelty', rec.noveltyScore),
    ];

    return <Widget>[
      for (final (String label, int value) in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(label, style: theme.textTheme.bodySmall),
                  ),
                  Text(
                    '$value%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (value / 100).clamp(0, 1).toDouble(),
                  minHeight: 5,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Future<void> _showPersonalizeSheet(BuildContext context) async {
    String? selectedOccasion = widget.outfitContext.occasion;
    String? selectedMood = widget.outfitContext.mood;
    String? selectedDressCode = widget.outfitContext.dressCode;
    int? selectedActivity = widget.outfitContext.expectedActivityLevel;
    String selectedPlace = widget.outfitContext.indoor == true
        ? 'indoor'
        : widget.outfitContext.outdoor == true
        ? 'outdoor'
        : 'both';

    final OutfitContext?
    updatedContext = await showModalBottomSheet<OutfitContext>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
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
                      'Season is automatic. Add optional context or just pick.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: selectedOccasion,
                      decoration: const InputDecoration(labelText: 'Occasion'),
                      items:
                          const <String>[
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
                      initialValue: selectedDressCode,
                      decoration: const InputDecoration(
                        labelText: 'Dress code',
                      ),
                      items:
                          const <String>[
                                'casual',
                                'smart casual',
                                'business casual',
                                'formal',
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
                          selectedDressCode = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMood,
                      decoration: const InputDecoration(labelText: 'Mood'),
                      items:
                          const <String>[
                                'bold',
                                'cozy',
                                'elegant',
                                'minimal',
                                'party',
                                'professional',
                                'relaxed',
                                'sporty',
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

                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: selectedActivity,
                      decoration: const InputDecoration(labelText: 'Activity'),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem<int>(value: 2, child: Text('Low')),
                        DropdownMenuItem<int>(
                          value: 5,
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem<int>(value: 8, child: Text('High')),
                      ],
                      onChanged: (int? value) {
                        setModalState(() {
                          selectedActivity = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'indoor',
                          label: Text('Indoor'),
                          icon: Icon(Icons.home_outlined),
                        ),
                        ButtonSegment<String>(
                          value: 'both',
                          label: Text('Both'),
                          icon: Icon(Icons.compare_arrows),
                        ),
                        ButtonSegment<String>(
                          value: 'outdoor',
                          label: Text('Outdoor'),
                          icon: Icon(Icons.wb_sunny_outlined),
                        ),
                      ],
                      selected: <String>{selectedPlace},
                      onSelectionChanged: (Set<String> values) {
                        setModalState(() {
                          selectedPlace = values.single;
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
                          child: const Text('Just pick for me'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              OutfitContext(
                                occasion: selectedOccasion,
                                mood: selectedMood,
                                dressCode: selectedDressCode,
                                expectedActivityLevel: selectedActivity,
                                indoor: selectedPlace == 'indoor'
                                    ? true
                                    : selectedPlace == 'outdoor'
                                    ? false
                                    : null,
                                outdoor: selectedPlace == 'outdoor'
                                    ? true
                                    : selectedPlace == 'indoor'
                                    ? false
                                    : null,
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
      widget.onContextChanged?.call(updatedContext);
    }
  }
}

class _GarmentStrip extends StatelessWidget {
  const _GarmentStrip({required this.rec});

  final OutfitRecommendation rec;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rec.garments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final Garment garment = rec.garments[index];
          final bool isHero = garment.id == rec.heroGarment?.id;
          return SizedBox(
            width: 76,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: GarmentImage(imageUrl: garment.coverImageUrl),
                      ),
                      if (isHero)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 10,
                            child: Icon(Icons.star_rounded, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  garment.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.75),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}