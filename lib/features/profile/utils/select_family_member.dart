import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/core/services/profile_session_service.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool> selectFamilyMember({
  required BuildContext context,
  required WidgetRef ref,
  required FamilyMember member,
}) async {
  ref.read(selectedFamilyMemberProvider.notifier).state = member;

  await ProfileSessionService.saveSelectedProfile(member.id);

  return true;
}