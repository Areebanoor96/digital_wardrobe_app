import 'package:digital_wardrobe_app/data/models/family_member.dart';
import 'package:digital_wardrobe_app/features/profile/Family/Widgets/add_family_member_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isChildBirthDateValid', () {
    test('child requires a birth date', () {
      expect(
        isChildBirthDateValid(
          relationship: RelationshipType.child,
          birthDate: null,
        ),
        isFalse,
      );
    });

    test('child with a birth date is valid', () {
      expect(
        isChildBirthDateValid(
          relationship: RelationshipType.child,
          birthDate: DateTime(2015, 1, 1),
        ),
        isTrue,
      );
    });

    test('non-child does not require a birth date', () {
      expect(
        isChildBirthDateValid(
          relationship: RelationshipType.self,
          birthDate: null,
        ),
        isTrue,
      );
    });

    test('adult with a birth date is valid', () {
      expect(
        isChildBirthDateValid(
          relationship: RelationshipType.sister,
          birthDate: DateTime(2000, 1, 1),
        ),
        isTrue,
      );
    });
  });
}
