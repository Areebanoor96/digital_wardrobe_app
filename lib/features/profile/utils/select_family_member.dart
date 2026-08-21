import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/growth_measurement.dart';
import 'package:digital_wardrobe_app/features/profile/Family/widgets/add_growth_measurement_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> selectFamilyMember({
  required BuildContext context,
  required WidgetRef ref,
  required FamilyMember member,
}) async {
  if (member.isChild) {
    final GrowthMeasurement? latest = await ref
        .read(growthRepositoryProvider)
        .fetchLatestMeasurement(memberId: member.id);

    if (!context.mounted) {
      return false;
    }

    if (latest == null) {
      final bool? measurementSaved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AddGrowthMeasurementDialog(
            member: member,
          );
        },
      );

      if (!context.mounted) {
        return false;
      }

      if (measurementSaved != true) {
        return false;
      }
    }
  }

  ref.read(selectedFamilyMemberProvider.notifier).state = member;

  await ProfileSessionService.saveSelectedProfile(member.id);

  return true;
}