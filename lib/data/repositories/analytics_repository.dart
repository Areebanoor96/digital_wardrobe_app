import 'package:digital_wardrobe_app/data/models/analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final SupabaseClient _client;

  Future<AnalyticsSummary> fetchSummary({
    required String memberId,
  }) async {
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
        .select('name,wear_count')
        .eq('user_id', currentUser.id)
        .eq('member_id', memberId)
        .eq('is_archived', false);

    final List<Map<String, dynamic>> active = activeRows
        .map(
          (dynamic row) => Map<String, dynamic>.from(row as Map),
    )
        .toList()
      ..sort(
            (Map<String, dynamic> left, Map<String, dynamic> right) {
          final int leftWearCount = left['wear_count'] as int? ?? 0;
          final int rightWearCount = right['wear_count'] as int? ?? 0;

          return rightWearCount.compareTo(leftWearCount);
        },
      );

    final Map<String, dynamic>? most = active.isEmpty ? null : active.first;
    final Map<String, dynamic>? least = active.isEmpty ? null : active.last;

    final int totalWears = active.fold<int>(
      0,
          (int total, Map<String, dynamic> garment) {
        return total + (garment['wear_count'] as int? ?? 0);
      },
    );

    final int activeCount =
        (stats?['total_items'] as num?)?.toInt() ?? active.length;

    return AnalyticsSummary(
      totalGarments: activeCount + archivedRows.length,
      activeGarments: activeCount,
      archivedGarments: archivedRows.length,
      totalWears: totalWears,
      totalValue: (stats?['total_value'] as num?)?.toDouble(),
      averageCostPerWear: (stats?['avg_cpw'] as num?)?.toDouble(),
      mostWornName: most?['name'] as String?,
      mostWornCount: (most?['wear_count'] as num?)?.toInt(),
      leastWornName: least?['name'] as String?,
      leastWornCount: (least?['wear_count'] as num?)?.toInt(),
    );
  }

  Future<List<CostPerWearEntry>> fetchCostPerWear({
    required String memberId,
  }) async {
    final User? currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw StateError('No authenticated user.');
    }

    final List<dynamic> rows = await _client
        .from('v_cost_per_wear')
        .select()
        .eq('user_id', currentUser.id)
        .eq('member_id', memberId)
        .order('cost_per_wear');

    return rows
        .map(
          (dynamic row) => CostPerWearEntry.fromJson(
        Map<String, dynamic>.from(row as Map),
      ),
    )
        .toList();
  }
}