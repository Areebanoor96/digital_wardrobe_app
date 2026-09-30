import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/features/calendar/screens/calendar_screen.dart';
import 'package:digital_wardrobe_app/data/models/outfit.dart';
import 'package:digital_wardrobe_app/features/ootd/providers/ootd_provider.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/ootd/widgets/ootd_card.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:digital_wardrobe_app/features/outfits/widgets/outfit_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OutfitsScreen extends ConsumerStatefulWidget {
  const OutfitsScreen({
    super.key,
    this.canNavigateBack = false,
    this.onNavigateBack,
  });

  final bool canNavigateBack;
  final VoidCallback? onNavigateBack;

  @override
  ConsumerState<OutfitsScreen> createState() => _OutfitsScreenState();
}
class _OutfitsScreenState extends ConsumerState<OutfitsScreen> {

  int _selectedTabIndex = 0;
  late final TabController _tabController;

  @override
  Widget build(BuildContext context) {
    final outfits = ref.watch(outfitsProvider);
    final garments = ref.watch(garmentsProvider);
    final ootd = ref.watch(ootdProvider);
    final actionState = ref.watch(ootdActionControllerProvider);
    final DateTime? selectedCalendarDay = ref.watch(
      selectedCalendarDayProvider,
    );

    return Scaffold(
      appBar: AppBar(
        leading: widget.canNavigateBack
            ? BackArrowButton(onPressed: widget.onNavigateBack)
            : null,
        title: const Text('My Outfits'),

      ),
      floatingActionButton: _selectedTabIndex == 1 && selectedCalendarDay != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/outfits/new'),
              icon: const Icon(Icons.add),
              label: const Text('Create outfit'),
            ),
      body: Column(
        children: [
          // Custom Editorial Pill Segment Controller
          Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? Theme.of(context).colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _selectedTabIndex == 0
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          'Stylist Suggestions',
                          style: TextStyle(
                            fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.w500,
                            color: _selectedTabIndex == 0
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? Theme.of(context).colorScheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _selectedTabIndex == 1
                            ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          'Outfit Calendar',
                          style: TextStyle(
                            fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.w500,
                            color: _selectedTabIndex == 1
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content Area
          Expanded(
            child: _selectedTabIndex == 0
                ? outfits.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _OutfitFeedback(
                title: 'We could not load your outfits',
                message: 'Check your connection and try again.',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(outfitsProvider),
              ),
              data: (List<Outfit> saved) {
                final List<Garment> wardrobe =
                    garments.valueOrNull ?? const <Garment>[];
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(outfitsProvider);
                    ref.invalidate(ootdProvider);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                    children: <Widget>[
                      ootd.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 0,
                            child: SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (OutfitRecommendation rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OotdCard(
                            recommendation: rec,
                            onRefresh: () =>
                            ref.read(ootdRefreshTokenProvider.notifier).state++,
                            outfitContext: ref.watch(ootdContextProvider),
                            onContextChanged: (OutfitContext value) {
                              ref.read(ootdContextProvider.notifier).state = value;
                            },
                            onSave: actionState.isLoading
                                ? null
                                : (current) => ref
                                .read(ootdActionControllerProvider.notifier)
                                .saveAsOutfit(current.garments),
                            onWear: actionState.isLoading
                                ? null
                                : (current) => ref
                                .read(ootdActionControllerProvider.notifier)
                                .wearOutfit(current.garments),
                            isSaving: actionState.isLoading,
                            isWearing: actionState.isLoading,
                          ),
                        ),
                      ),
                      if (saved.isEmpty)
                        _OutfitFeedback(
                          title: 'No saved outfits yet',
                          message:
                          'Combine garments from your wardrobe into outfits you can reuse.',
                          actionLabel: 'Create outfit',
                          onAction: () => context.push('/outfits/new'),
                        )
                      else
                        ...saved.map((Outfit outfit) {
                          final List<Garment> items = outfit.garmentIds
                              .map(
                                (String id) => wardrobe
                                .where((Garment garment) => garment.id == id)
                                .firstOrNull,
                          )
                              .whereType<Garment>()
                              .toList();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OutfitCard(
                              outfit: outfit,
                              garments: items,
                              onTap: () => context.push('/outfits/${outfit.id}'),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            )
                : const CalendarScreen(),
          ),
        ],
      ),   // Closes TabBarView
    );     // Closes Scaffold
  }
}

class _OutfitFeedback extends StatelessWidget {
  const _OutfitFeedback({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
