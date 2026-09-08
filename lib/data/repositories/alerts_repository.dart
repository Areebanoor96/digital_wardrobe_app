import 'package:digital_wardrobe_app/data/models/alert.dart';
import 'package:digital_wardrobe_app/data/models/garment.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/models/ootd_recommendation_snapshot.dart';
import 'package:digital_wardrobe_app/data/models/wear_log.dart';
import 'package:digital_wardrobe_app/data/repositories/ootd_recommendation_repository.dart';
import 'package:digital_wardrobe_app/features/alerts/services/alert_rule_service.dart';
import 'package:digital_wardrobe_app/features/ootd/services/outfit_recommendation_service.dart';
import 'package:digital_wardrobe_app/features/outfits/models/outfit_context.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertsRepository {
  AlertsRepository(
    this._client, {
    this.ruleService = const AlertRuleService(),
    OotdRecommendationRepository? ootdRecommendationRepository,
  }) : _ootdRecommendationRepository = ootdRecommendationRepository;

  final SupabaseClient _client;
  final AlertRuleService ruleService;
  final OotdRecommendationRepository? _ootdRecommendationRepository;

  Future<List<Alert>> fetchAlerts({required String memberId}) async {
    final String userId = _client.auth.currentUser!.id;

    final List<dynamic> rows = await _client
        .from('alerts')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('is_dismissed', false)
        .order('created_at', ascending: false);

    return rows
        .map(
          (dynamic row) =>
              Alert.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> markAsRead(String alertId) async {
    final String userId = _client.auth.currentUser!.id;

    await _client
        .from('alerts')
        .update(<String, Object?>{
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', alertId)
        .eq('user_id', userId);
  }

  Future<void> dismissAlert(String alertId) async {
    final String userId = _client.auth.currentUser!.id;

    await _client
        .from('alerts')
        .update(<String, Object?>{
          'is_dismissed': true,
          'dismissed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', alertId)
        .eq('user_id', userId);
  }

  Future<int> generateAndInsertAlerts({required String memberId}) async {
    final String userId = _client.auth.currentUser!.id;

    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);

    // Fetch the user's alert preferences.
    final Map<String, dynamic> profileRow = Map<String, dynamic>.from(
      await _client
              .from('profiles')
              .select(
                'id, '
                'unused_alerts_enabled, '
                'laundry_alerts_enabled, '
                'ootd_alerts_enabled',
              )
              .eq('id', userId)
              .single()
          as Map,
    );

    final Profile profile = Profile.fromJson(profileRow);

    // OOTD has a separate once-per-day duplicate rule. Only an ACTIVE
    // (undismissed) OOTD alert counts as today's alert: a dismissed one must
    // not permanently block a fresh alert for the rest of the day.
    final List<dynamic> todaysActiveOotdRows = await _client
        .from('alerts')
        .select('id')
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('type', 'ootd')
        .eq('is_dismissed', false)
        .gte('created_at', startOfToday.toUtc().toIso8601String())
        .limit(1);

    final bool hasActiveOotdAlert = todaysActiveOotdRows.isNotEmpty;

    // Fetch all active garments for the selected wardrobe profile.
    final List<dynamic> garmentRows = await _client
        .from('garments')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('is_archived', false);

    final List<Garment> garments = garmentRows
        .map(
          (dynamic row) =>
              Garment.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();

    // Remove alerts whose underlying condition no longer exists.
    await _resolveGarmentAlerts(
      userId: userId,
      memberId: memberId,
      garments: garments,
      unusedAlertsEnabled: profile.unusedAlertsEnabled,
      laundryAlertsEnabled: profile.laundryAlertsEnabled,
    );
    final bool isOotdEligible = const OutfitRecommendationService()
        .isEligibleForRecommendation(garments, memberId: memberId);
    await _resolveOotdAlert(
      userId: userId,
      memberId: memberId,
      enabled: profile.ootdAlertsEnabled,
    );
    // Active alerts are used to prevent duplicate garment alerts.
    final List<dynamic> existingRows = await _client
        .from('alerts')
        .select('type, garment_id')
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('is_dismissed', false);

    final Set<String> existingKeys = existingRows.map((dynamic row) {
      final Map<String, dynamic> value = Map<String, dynamic>.from(row as Map);

      return '${value['type']}_${value['garment_id']}';
    }).toSet();
    final List<Map<String, dynamic>> newAlerts = <Map<String, dynamic>>[];

    for (final Garment garment in garments) {
      newAlerts.addAll(
        ruleService.buildGarmentAlerts(
          garment: garment,
          userId: userId,
          memberId: memberId,
          existingKeys: existingKeys,
          unusedAlertsEnabled: profile.unusedAlertsEnabled,
          laundryAlertsEnabled: profile.laundryAlertsEnabled,
        ),
      );
    }

    // Generate today's OOTD alert if allowed and the wardrobe is eligible.
    final Map<String, dynamic>? ootdAlert = await _buildOotdAlert(
      userId: userId,
      memberId: memberId,
      garments: garments,
      enabled: profile.ootdAlertsEnabled,
      hasActiveOotdAlert: hasActiveOotdAlert,
      isOotdEligible: isOotdEligible,
    );

    if (ootdAlert != null) {
      newAlerts.add(ootdAlert);
    }

    if (newAlerts.isEmpty) {
      return 0;
    }

    await _client.from('alerts').insert(newAlerts);

    return newAlerts.length;
  }

  Future<Map<String, dynamic>?> _buildOotdAlert({
    required String userId,
    required String memberId,
    required List<Garment> garments,
    required bool enabled,
    required bool hasActiveOotdAlert,
    required bool isOotdEligible,
  }) async {
    if (!shouldCreateOotdAlert(
      enabled: enabled,
      hasActiveOotdAlert: hasActiveOotdAlert,
      isOotdEligible: isOotdEligible,
    )) {
      return null;
    }

    final OotdRecommendationRepository? snapshotRepository =
        _ootdRecommendationRepository;

    if (snapshotRepository == null) {
      return null;
    }

    final OutfitRecommendation recommendation;
    try {
      final List<WearLog> wearLogs = await _fetchOotdWearHistory(
        userId: userId,
        memberId: memberId,
      );
      recommendation = const OutfitRecommendationService().recommend(
        allGarments: garments,
        wearLogs: wearLogs,
        context: const OutfitContext(),
        memberId: memberId,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not build OOTD alert recommendation: $error');
      debugPrint(stackTrace.toString());
      return null;
    }

    if (recommendation.garments.isEmpty) {
      return null;
    }

    return buildOotdAlertWithSnapshot(
      userId: userId,
      memberId: memberId,
      recommendation: recommendation,
      enabled: enabled,
      hasActiveOotdAlert: hasActiveOotdAlert,
      isOotdEligible: isOotdEligible,
    );
  }

  /// Persists the OOTD recommendation snapshot and returns the alert row.
  ///
  /// A snapshot persistence failure is isolated here so it can never break the
  /// wider alerts feed: the OOTD alert is skipped for this generation attempt
  /// and all other alert types continue normally.
  Future<Map<String, dynamic>?> buildOotdAlertWithSnapshot({
    required String userId,
    required String memberId,
    required OutfitRecommendation recommendation,
    required bool enabled,
    required bool hasActiveOotdAlert,
    required bool isOotdEligible,
  }) async {
    final OotdRecommendationRepository? snapshotRepository =
        _ootdRecommendationRepository;

    if (snapshotRepository == null) {
      return null;
    }

    try {
      final OotdRecommendationSnapshot snapshot = await snapshotRepository
          .createSnapshot(
            memberId: memberId,
            recommendation: recommendation,
            context: const OutfitContext(),
          );

      return ruleService.buildOotdAlert(
        userId: userId,
        memberId: memberId,
        enabled: enabled,
        hasOotdAlertToday: hasActiveOotdAlert,
        isOotdEligible: isOotdEligible,
        snapshotId: snapshot.id,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not persist OOTD alert snapshot: $error');
      debugPrint(stackTrace.toString());
      return null;
    }
  }

  /// Whether a fresh OOTD alert may be created on this generation attempt.
  ///
  /// Creation requires the alert type to be enabled, the wardrobe to be
  /// eligible for a recommendation, and no ACTIVE (undismissed) OOTD alert to
  /// already exist for today. A dismissed OOTD alert does not block a new one.
  static bool shouldCreateOotdAlert({
    required bool enabled,
    required bool hasActiveOotdAlert,
    required bool isOotdEligible,
  }) {
    return enabled && !hasActiveOotdAlert && isOotdEligible;
  }

  /// Whether existing OOTD alerts should be auto-dismissed on a regeneration.
  ///
  /// Only a disabled OOTD alert preference resolves them. A temporarily
  /// ineligible wardrobe (e.g. freshly worn, dirty garments) never auto-dismisses
  /// an already-generated OOTD alert.
  static bool shouldResolveOotdAlert({required bool enabled}) => !enabled;

  Future<List<WearLog>> _fetchOotdWearHistory({
    required String userId,
    required String memberId,
  }) async {
    final DateTime start = DateTime.now().subtract(const Duration(days: 90));
    final String startDate =
        '${start.year}-'
        '${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';

    final List<dynamic> rows = await _client
        .from('wear_log')
        .select()
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .gte('worn_date', startDate)
        .order('worn_date', ascending: false);

    return rows
        .map(
          (dynamic row) =>
              WearLog.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> _resolveGarmentAlerts({
    required String userId,
    required String memberId,
    required List<Garment> garments,
    required bool unusedAlertsEnabled,
    required bool laundryAlertsEnabled,
  }) async {
    // Partition garments into those whose laundry / unused alert conditions no
    // longer hold. Using a single batched UPDATE per type (rather than one
    // UPDATE per garment) avoids 2N sequential round trips for large wardrobes.
    final List<String> laundryDismissIds = <String>[];
    final List<String> unusedDismissIds = <String>[];

    for (final Garment garment in garments) {
      if (!laundryAlertsEnabled || !ruleService.shouldHaveLaundryAlert(garment)) {
        laundryDismissIds.add(garment.id);
      }

      if (!unusedAlertsEnabled || !ruleService.shouldHaveUnusedAlert(garment)) {
        unusedDismissIds.add(garment.id);
      }
    }

    if (laundryDismissIds.isNotEmpty) {
      await _dismissGarmentAlerts(
        userId: userId,
        memberId: memberId,
        garmentIds: laundryDismissIds,
        type: 'laundry',
      );
    }

    if (unusedDismissIds.isNotEmpty) {
      await _dismissGarmentAlerts(
        userId: userId,
        memberId: memberId,
        garmentIds: unusedDismissIds,
        type: 'unused',
      );
    }
  }

  Future<void> _dismissGarmentAlerts({
    required String userId,
    required String memberId,
    required List<String> garmentIds,
    required String type,
  }) async {
    await _client
        .from('alerts')
        .update(<String, bool>{'is_dismissed': true})
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .inFilter('garment_id', garmentIds)
        .eq('type', type)
        .eq('is_dismissed', false);
  }

  Future<void> _resolveOotdAlert({
    required String userId,
    required String memberId,
    required bool enabled,
  }) async {
    if (!shouldResolveOotdAlert(enabled: enabled)) {
      return;
    }

    await _client
        .from('alerts')
        .update(<String, bool>{'is_dismissed': true})
        .eq('user_id', userId)
        .eq('member_id', memberId)
        .eq('type', 'ootd')
        .eq('is_dismissed', false);
  }
}
