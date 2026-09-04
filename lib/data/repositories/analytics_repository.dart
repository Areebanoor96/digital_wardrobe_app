import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final SupabaseClient _client;

  Future<AnalyticsSummary> fetchSummary({required String memberId}) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    final List<dynamic> statsRows = await _client
        .from('v_wardrobe_stats')
        .select()
        .eq('user_id', currentUser.id)
        .eq('member_id', memberId);

    final Map<String, dynamic>? stats = statsRows.isEmpty
        ? null
        : Map<String, dynamic>.from(statsRows.single as Map);

    final List<dynamic> archivedRows = await _client
        .from('garments')
        .select('id')
        .eq('user_id', currentUser.id)
        .eq('member_id', memberId)
        .eq('is_archived', true);

    final List<dynamic> activeRows = await _client
        .from('garments')
        .select('name,wear_count,category')
        .eq('user_id', currentUser.id)
        .eq('member_id', memberId)
        .eq('is_archived', false);

    final List<Map<String, dynamic>> active =
        activeRows
            .map((dynamic row) => Map<String, dynamic>.from(row as Map))
            .toList()
          ..sort((Map<String, dynamic> left, Map<String, dynamic> right) {
            final int leftWearCount = left['wear_count'] as int? ?? 0;
            final int rightWearCount = right['wear_count'] as int? ?? 0;

            return rightWearCount.compareTo(leftWearCount);
          });

    final Map<String, dynamic>? most = active.isEmpty ? null : active.first;
    final Map<String, dynamic>? least = active.isEmpty ? null : active.last;

    final int totalWears = active.fold<int>(0, (
      int total,
      Map<String, dynamic> garment,
    ) {
      return total + (garment['wear_count'] as int? ?? 0);
    });

    final int activeCount =
        (stats?['total_items'] as num?)?.toInt() ?? active.length;

    final Map<String, int> categoryDistribution =
        _computeCategoryDistribution(active);
    final Map<String, int> wearDistribution =
        _computeWearDistribution(active);

    return AnalyticsSummary(
      totalGarments: activeCount + archivedRows.length,
      activeGarments: activeCount,
      archivedGarments: archivedRows.length,
      totalWears: totalWears,
      totalValue: (stats?['total_value'] as num?)?.toDouble(),
      mostWornName: most?['name'] as String?,
      mostWornCount: (most?['wear_count'] as num?)?.toInt(),
      leastWornName: least?['name'] as String?,
      leastWornCount: (least?['wear_count'] as num?)?.toInt(),
      categoryDistribution: categoryDistribution,
      wearDistribution: wearDistribution,
    );
  }

  static Map<String, int> _computeCategoryDistribution(
    List<Map<String, dynamic>> activeGarments,
  ) {
    final Map<String, int> counts = <String, int>{};
    for (final Map<String, dynamic> g in activeGarments) {
      final String rawCategory = g['category'] as String? ?? 'other';
      final String label = GarmentCategory.values
          .where((GarmentCategory c) => c.name == rawCategory)
          .map((GarmentCategory c) => c.label)
          .first;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts;
  }

  static Map<String, int> _computeWearDistribution(
    List<Map<String, dynamic>> activeGarments,
  ) {
    final Map<String, int> buckets = <String, int>{
      'Never worn': 0,
      '1–5 wears': 0,
      '6–15 wears': 0,
      '16+ wears': 0,
    };
    for (final Map<String, dynamic> g in activeGarments) {
      final int wc = g['wear_count'] as int? ?? 0;
      if (wc == 0) {
        buckets['Never worn'] = buckets['Never worn']! + 1;
      } else if (wc <= 5) {
        buckets['1–5 wears'] = buckets['1–5 wears']! + 1;
      } else if (wc <= 15) {
        buckets['6–15 wears'] = buckets['6–15 wears']! + 1;
      } else {
        buckets['16+ wears'] = buckets['16+ wears']! + 1;
      }
    }
    return buckets;
  }
}
