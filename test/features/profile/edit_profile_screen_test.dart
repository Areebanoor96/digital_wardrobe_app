import 'dart:io';
import 'dart:typed_data';

import 'package:digital_wardrobe_app/core/providers/app_providers.dart';
import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/data/models/profile.dart';
import 'package:digital_wardrobe_app/data/repositories/family_repository.dart';
import 'package:digital_wardrobe_app/data/repositories/profile_repository.dart';
import 'package:digital_wardrobe_app/features/profile/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the last [FamilyRepository.updateMemberProfileDetails] payload so
/// the save path can be asserted without a backend.
class _RecordingFamilyRepository implements FamilyRepository {
  Map<String, dynamic>? lastUpdate;
  FamilyMember storedMember;

  _RecordingFamilyRepository(this.storedMember);

  @override
  Future<void> updateMemberProfileDetails({
    required String id,
    required String name,
    required String relationship,
    DateTime? birthDate,
    String? pronouns,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? shoeSize,
    String? shoeUnit,
    String? topsSize,
    String? bottomsSize,
    List<String>? styleAesthetics,
    List<String>? colorPreferences,
  }) async {
    lastUpdate = <String, dynamic>{
      'id': id,
      'name': name,
      'relationship': relationship,
      'birthDate': birthDate,
      'pronouns': pronouns,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'shoeSize': shoeSize,
      'shoeUnit': shoeUnit,
      'topsSize': topsSize,
      'bottomsSize': bottomsSize,
      'styleAesthetics': styleAesthetics,
      'colorPreferences': colorPreferences,
    };
  }

  @override
  Future<FamilyMember?> getFamilyMemberById(String id) async => storedMember;

  @override
  Future<List<FamilyMember>> fetchFamilyMembers() async => <FamilyMember>[
    storedMember,
  ];

  @override
  Future<FamilyMember> addFamilyMember({
    required String name,
    required String relationship,
    Uint8List? avatarBytes,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
    String? currentSize,
    String? shoeSize,
  }) async => storedMember;

  @override
  Future<void> deleteFamilyMember(FamilyMember member) async {}

  @override
  Future<void> updateFamilyMember({
    required String id,
    required String name,
    required String relationship,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
  }) async {}

  @override
  Future<void> updateMemberShoeSize({
    required String id,
    required String? shoeSize,
  }) async {}

  @override
  Future<String> uploadAvatar({
    required String memberId,
    required Uint8List bytes,
  }) async => 'avatars/fake_path.jpg';

  @override
  Future<void> updateAvatarPath({
    required String memberId,
    required String? avatarPath,
  }) async {}

  @override
  Future<void> updateAvatar({
    required String memberId,
    required Uint8List bytes,
  }) async {}

  @override
  Future<void> removeAvatar(FamilyMember member) async {}
}

/// Records the mirrored `profiles` write that only happens for the account
/// holder.
class _RecordingProfileRepository implements ProfileRepository {
  Map<String, dynamic>? lastUpdate;

  @override
  Future<Profile> fetchProfile() async => throw UnimplementedError();

  @override
  Future<String?> getAvatarSignedUrl(String path) async => null;

  @override
  Future<String> uploadAvatar(File file) async => 'avatars/fake_path.jpg';

  @override
  Future<void> updateProfileDetails({
    required String fullName,
    required String username,
    String? pronouns,
    String? gender,
  }) async {
    lastUpdate = <String, dynamic>{
      'fullName': fullName,
      'username': username,
      'pronouns': pronouns,
      'gender': gender,
    };
  }

  @override
  Future<void> updateGrowthAlertsEnabled(bool enabled) async {}

  @override
  Future<void> updateLocationCity(String? city) async {}

  @override
  Future<void> updateCountryCode(String? countryCode) async {}

  @override
  Future<void> updateAlertPreferences({
    required bool unusedAlertsEnabled,
    required bool laundryAlertsEnabled,
    required bool ootdAlertsEnabled,
    bool? growthAlertsEnabled,
  }) async {}
}

const FamilyMember _adult = FamilyMember(
  id: 'member-1',
  name: 'Bilal',
  relationship: RelationshipType.brother,
);

const FamilyMember _account = FamilyMember(
  id: 'member-self',
  name: 'Ayesha',
  relationship: RelationshipType.self,
);

void main() {
  Future<void> pumpEditProfile(
    WidgetTester tester,
    _RecordingFamilyRepository familyRepository,
    _RecordingProfileRepository profileRepository, {
    required FamilyMember member,
    Profile? profile,
  }) async {
    await tester.binding.setSurfaceSize(const Size(600, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          familyRepositoryProvider.overrideWithValue(familyRepository),
          profileRepositoryProvider.overrideWithValue(profileRepository),
          profileProvider.overrideWith(
            (ref) async =>
                profile ??
                const Profile(id: 'user-1', fullName: 'Ayesha', username: 'ayesha'),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EditProfileScreen(
                        member: member,
                        profile: profile,
                      ),
                    ),
                  ),
                  child: const Text('open editor'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open editor'));
    await tester.pumpAndSettle();
  }

  /// The unit dropdowns are labelled "Unit" twice: height first, weight second.
  Finder unitDropdownAt(int index) =>
      find.widgetWithText(DropdownButtonFormField<String>, 'Unit').at(index);

  group('current_size derivation', () {
    test('mirrors tops_size so the outgrowth engine can rank garments', () {
      final Map<String, dynamic> row = FamilyRepository.buildProfileDetailsRow(
        name: 'Bilal',
        relationship: RelationshipType.brother.name,
        topsSize: '2-3Y',
      );

      expect(row['current_size'], '2-3Y');
      expect(row['tops_size'], '2-3Y');
    });

    test('clears current_size when no tops size is given', () {
      final Map<String, dynamic> row = FamilyRepository.buildProfileDetailsRow(
        name: 'Bilal',
        relationship: RelationshipType.brother.name,
      );

      expect(row['current_size'], isNull);
    });
  });

  testWidgets('renders the three titled sections and their fields', (
    tester,
  ) async {
    await pumpEditProfile(
      tester,
      _RecordingFamilyRepository(_adult),
      _RecordingProfileRepository(),
      member: _adult,
    );

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Sizing & Measurements'), findsOneWidget);
    expect(find.text('Style Preferences'), findsOneWidget);

    expect(find.widgetWithText(TextFormField, 'Full Name'), findsOneWidget);
    expect(
      find.widgetWithText(DropdownButtonFormField<RelationshipType>, 'Relationship'),
      findsOneWidget,
    );
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'Pronouns (Optional)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'Gender'),
      findsOneWidget,
    );

    // Sizing and measurements.
    expect(find.widgetWithText(TextFormField, 'Size'), findsOneWidget);
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'System'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'Tops'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(DropdownButtonFormField<String>, 'Bottoms'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Height'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Weight'), findsOneWidget);
    expect(unitDropdownAt(0), findsOneWidget);
    expect(unitDropdownAt(1), findsOneWidget);

    // Style preferences.
    for (final String aesthetic in <String>[
      'Casual',
      'Minimalist',
      'Streetwear',
      'Formal',
      'Traditional',
      'Sporty',
    ]) {
      expect(find.widgetWithText(FilterChip, aesthetic), findsOneWidget);
    }
    expect(find.widgetWithText(ChoiceChip, 'Navy'), findsOneWidget);

    // Explicit product constraint: no dress size is offered.
    expect(find.textContaining('Dress'), findsNothing);
    expect(find.textContaining('dress'), findsNothing);
  });

  testWidgets('hides the username field for a non-account member', (
    tester,
  ) async {
    await pumpEditProfile(
      tester,
      _RecordingFamilyRepository(_adult),
      _RecordingProfileRepository(),
      member: _adult,
    );

    expect(find.widgetWithText(TextFormField, 'Username'), findsNothing);
  });

  testWidgets('shows the username field for the account holder', (
    tester,
  ) async {
    await pumpEditProfile(
      tester,
      _RecordingFamilyRepository(_account),
      _RecordingProfileRepository(),
      member: _account,
      profile: const Profile(
        id: 'user-1',
        fullName: 'Ayesha',
        username: 'ayesha',
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Username'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
  });

  testWidgets('hydrates sizing and style values from the family member', (
    tester,
  ) async {
    final FamilyMember member = _adult.copyWith(
      shoeSize: '38',
      shoeUnit: 'UK',
      topsSize: 'M',
      bottomsSize: '32',
      heightCm: 180,
      weightKg: 70,
      styleAesthetics: const <String>['Minimalist', 'Formal'],
      colorPreferences: const <String>['Navy'],
    );

    await pumpEditProfile(
      tester,
      _RecordingFamilyRepository(member),
      _RecordingProfileRepository(),
      member: member,
    );

    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Full Name'),
          )
          .controller
          ?.text,
      'Bilal',
    );
    expect(find.text('38'), findsOneWidget);
    expect(find.text('180'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);

    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Minimalist'))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, 'Casual'))
          .selected,
      isFalse,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Navy'))
          .selected,
      isTrue,
    );
  });

  testWidgets('switching the body metric units converts the stored value', (
    tester,
  ) async {
    await pumpEditProfile(
      tester,
      _RecordingFamilyRepository(
        _adult.copyWith(heightCm: 180, weightKg: 70),
      ),
      _RecordingProfileRepository(),
      member: _adult.copyWith(heightCm: 180, weightKg: 70),
    );

    await tester.tap(unitDropdownAt(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ft').last);
    await tester.pumpAndSettle();

    await tester.tap(unitDropdownAt(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('lbs').last);
    await tester.pumpAndSettle();

    // 180cm -> 5.9ft, 70kg -> 154.3lbs.
    expect(find.text('5.9'), findsOneWidget);
    expect(find.text('154.3'), findsOneWidget);
  });

  testWidgets('saving persists the full dataset and returns to the caller', (
    tester,
  ) async {
    final _RecordingFamilyRepository familyRepository =
        _RecordingFamilyRepository(_adult);

    await pumpEditProfile(
      tester,
      familyRepository,
      _RecordingProfileRepository(),
      member: _adult,
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Size'), '38');
    await tester.enterText(find.widgetWithText(TextFormField, 'Height'), '180');
    await tester.enterText(find.widgetWithText(TextFormField, 'Weight'), '70');

    // A child age size, which the outgrowth engine ranks.
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Tops'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2-3Y').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Casual'));
    await tester.tap(find.widgetWithText(FilterChip, 'Casual'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Navy'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(familyRepository.lastUpdate, isNotNull);
    expect(familyRepository.lastUpdate!['id'], 'member-1');
    expect(familyRepository.lastUpdate!['name'], 'Bilal');
    expect(familyRepository.lastUpdate!['relationship'], 'brother');
    expect(familyRepository.lastUpdate!['shoeSize'], '38');
    expect(familyRepository.lastUpdate!['shoeUnit'], 'EU');
    expect(familyRepository.lastUpdate!['topsSize'], '2-3Y');
    expect(familyRepository.lastUpdate!['heightCm'], 180.0);
    expect(familyRepository.lastUpdate!['weightKg'], 70.0);
    expect(familyRepository.lastUpdate!['styleAesthetics'], <String>['Casual']);
    expect(
      familyRepository.lastUpdate!['colorPreferences'],
      <String>['Navy'],
    );

    // The screen popped back to whatever pushed it.
    expect(find.text('open editor'), findsOneWidget);
    expect(find.byType(EditProfileScreen), findsNothing);
  });

  testWidgets('saving the account holder also syncs the profiles row', (
    tester,
  ) async {
    final _RecordingFamilyRepository familyRepository =
        _RecordingFamilyRepository(_account);
    final _RecordingProfileRepository profileRepository =
        _RecordingProfileRepository();

    await pumpEditProfile(
      tester,
      familyRepository,
      profileRepository,
      member: _account,
      profile: const Profile(
        id: 'user-1',
        fullName: 'Ayesha',
        username: 'ayesha',
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name'),
      'Ayesha K',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'ayesha-k',
    );

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(profileRepository.lastUpdate, isNotNull);
    expect(profileRepository.lastUpdate!['fullName'], 'Ayesha K');
    expect(profileRepository.lastUpdate!['username'], 'ayesha-k');
    expect(familyRepository.lastUpdate!['name'], 'Ayesha K');
  });

  testWidgets('saving a non-account member does not touch the profiles row', (
    tester,
  ) async {
    final _RecordingProfileRepository profileRepository =
        _RecordingProfileRepository();

    await pumpEditProfile(
      tester,
      _RecordingFamilyRepository(_adult),
      profileRepository,
      member: _adult,
    );

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(profileRepository.lastUpdate, isNull);
  });

  testWidgets('refuses to save a child profile without a date of birth', (
    tester,
  ) async {
    final _RecordingFamilyRepository familyRepository =
        _RecordingFamilyRepository(_adult);

    await pumpEditProfile(
      tester,
      familyRepository,
      _RecordingProfileRepository(),
      member: _adult,
    );

    await tester.tap(
      find.widgetWithText(
        DropdownButtonFormField<RelationshipType>,
        'Relationship',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Child').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(familyRepository.lastUpdate, isNull);
    expect(
      find.text('Add a date of birth for a child profile.'),
      findsOneWidget,
    );
  });

  testWidgets('saves the body metrics in canonical cm and kg', (
    tester,
  ) async {
    final _RecordingFamilyRepository familyRepository =
        _RecordingFamilyRepository(_adult);

    await pumpEditProfile(
      tester,
      familyRepository,
      _RecordingProfileRepository(),
      member: _adult.copyWith(heightCm: 180, weightKg: 70),
    );

    await tester.tap(unitDropdownAt(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ft').last);
    await tester.pumpAndSettle();
    await tester.tap(unitDropdownAt(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('lbs').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    // Displayed as 5.9ft / 154.3lbs but persisted in centimetres/kilograms.
    expect(familyRepository.lastUpdate!['heightCm'], closeTo(179.7, 0.5));
    expect(familyRepository.lastUpdate!['weightKg'], closeTo(70, 0.1));
  });
}
