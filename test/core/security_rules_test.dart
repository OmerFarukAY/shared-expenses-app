import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security & Invariants Validation Suite', () {
    test(
      'ExpenseModel enforces positive totalMinor and valid ISO currency',
      () {
        final valid = ExpenseModel(
          id: 'e-1',
          groupId: 'g-1',
          title: 'Dinner',
          totalMinor: 5000,
          currency: 'EUR',
          category: ExpenseCategory.food,
          date: DateTime.now(),
          createdBy: 'u-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          payers: {'u-1': 5000},
          participants: ['u-1'],
          splitMethod: SplitMethod.equal,
          splits: {'u-1': 5000},
        );

        expect(valid.totalMinor, greaterThan(0));
        expect(valid.currency.length, equals(3));
        expect(valid.toMap()['totalMinor'], equals(5000));

        expect(
          () => ExpenseModel(
            id: 'e-bad',
            groupId: 'g-1',
            title: 'Invalid',
            totalMinor: -100, // Negative amount not allowed
            currency: 'EUR',
            category: ExpenseCategory.food,
            date: DateTime.now(),
            createdBy: 'u-1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            payers: {'u-1': -100},
            participants: ['u-1'],
            splitMethod: SplitMethod.equal,
            splits: {'u-1': -100},
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('GroupMember enforces MemberRole serialization integrity', () {
      final owner = GroupMember(
        uid: 'u-owner',
        displayName: 'Owner User',
        role: MemberRole.owner,
        joinedAt: DateTime(2026, 1, 1),
      );
      final member = GroupMember(
        uid: 'u-member',
        displayName: 'Normal Member',
        role: MemberRole.member,
        joinedAt: DateTime(2026, 1, 2),
      );

      expect(owner.isOwner, isTrue);
      expect(owner.toMap()['role'], equals('owner'));

      expect(member.isOwner, isFalse);
      expect(member.toMap()['role'], equals('member'));
    });

    test(
      'GroupModel verifies invite code length and active flag invariants',
      () {
        final group = GroupModel(
          id: 'grp-test',
          name: 'Apartment 4B',
          defaultCurrency: 'TRY',
          inviteCode: 'DNK-9999',
          createdBy: 'u-creator',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          memberCount: 3,
          active: true,
        );

        final map = group.toMap();
        expect(map['inviteCode'].length, inInclusiveRange(6, 12));
        expect(map['active'], isTrue);
        expect(map['memberCount'], greaterThanOrEqualTo(1));
      },
    );
  });
}
