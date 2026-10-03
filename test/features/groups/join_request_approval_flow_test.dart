import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/denk_skeleton.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/groups_list_screen.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/expenses/presentation/expense_controller.dart';
import 'package:denk/features/settlements/presentation/settlement_controller.dart';
import 'package:denk/l10n/l10n.dart';

class FakeGroupRepository implements GroupRepository {
  String? deletedGroupId;
  String? deletedUid;
  final GroupModel testGroup;

  FakeGroupRepository(this.testGroup);

  @override
  Future<GroupModel?> getGroup(String groupId) async => testGroup;

  @override
  Future<void> deleteUserJoinRequest({
    required String groupId,
    required String uid,
  }) async {
    deletedGroupId = groupId;
    deletedUid = uid;
  }

  @override
  Stream<List<GroupModel>> watchUserGroups(String uid) =>
      Stream.value([testGroup]);

  @override
  Stream<List<JoinRequestModel>> watchUserJoinRequests(String uid) =>
      const Stream.empty();

  @override
  Stream<List<JoinRequestModel>> watchGroupJoinRequests(String groupId) =>
      const Stream.empty();

  @override
  Stream<List<GroupMember>> watchGroupMembers(String groupId) =>
      const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();
  final testGroup = GroupModel(
    id: 'grp_test_approved',
    name: 'Approval Target Group',
    defaultCurrency: 'TRY',
    inviteCode: 'DNK-APPR',
    createdBy: 'user_admin',
    createdAt: now,
    updatedAt: now,
    memberCount: 2,
  );

  testWidgets(
    'GroupsListScreen auto-detects approved join request, selects group, and cleans up request doc',
    (tester) async {
      final fakeRepo = FakeGroupRepository(testGroup);
      final requestController =
          StreamController<List<JoinRequestModel>>.broadcast();

      GroupModel? navigatedGroup;

      final pendingReq = JoinRequestModel(
        id: 'user_requester',
        groupId: 'grp_test_approved',
        uid: 'user_requester',
        displayName: 'Requester',
        status: JoinRequestStatus.pending,
        inviteCode: 'DNK-APPR',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(fakeRepo),
            userGroupsStreamProvider.overrideWith(
              (ref) => Stream.value([testGroup]),
            ),
            userJoinRequestsStreamProvider.overrideWith(
              (ref) => requestController.stream,
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: GroupsListScreen(
              onGroupSelected: (g) => navigatedGroup = g,
            ),
          ),
        ),
      );

      // Emit pending request first
      requestController.add([pendingReq]);
      await tester.pumpAndSettle();

      expect(navigatedGroup, isNull);
      expect(fakeRepo.deletedGroupId, isNull);

      // Now admin approves: emit approved request
      final approvedReq = pendingReq.copyWith(
        status: JoinRequestStatus.approved,
      );
      requestController.add([approvedReq]);
      await tester.pumpAndSettle();

      // Verify the requester was automatically directed to the approved group
      expect(navigatedGroup, isNotNull);
      expect(navigatedGroup!.id, 'grp_test_approved');
      expect(navigatedGroup!.name, 'Approval Target Group');

      // Verify the join request document was deleted from users/{uid}/join_requests/{groupId}
      expect(fakeRepo.deletedGroupId, 'grp_test_approved');
      expect(fakeRepo.deletedUid, 'user_requester');

      await requestController.close();
    },
  );

  test('groupDashboardDataProvider unifies members, expenses, and settlements synchronously', () async {
    final container = ProviderContainer(
      overrides: [
        groupMembersStreamProvider('grp_1').overrideWith(
          (ref) => Stream.value([
            GroupMember(
              uid: 'u1',
              displayName: 'Alice',
              role: MemberRole.owner,
              joinedAt: now,
            ),
          ]),
        ),
        groupExpensesStreamProvider('grp_1').overrideWith(
          (ref) => Stream.value([
            ExpenseModel(
              id: 'e1',
              groupId: 'grp_1',
              title: 'Dinner',
              category: ExpenseCategory.food,
              currency: 'TRY',
              totalMinor: 10000,
              date: now,
              splitMethod: SplitMethod.equal,
              payers: const {'u1': 10000},
              participants: const ['u1'],
              splits: const {'u1': 10000},
              createdBy: 'u1',
              createdAt: now,
              updatedAt: now,
            ),
          ]),
        ),
        groupSettlementsStreamProvider('grp_1').overrideWith(
          (ref) => Stream.value([]),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Initial read
    final subscription = container.listen(
      groupDashboardDataProvider('grp_1'),
      (prev, next) {},
    );

    // Await stream provider values
    await container.read(groupMembersStreamProvider('grp_1').future);
    await container.read(groupExpensesStreamProvider('grp_1').future);
    await container.read(groupSettlementsStreamProvider('grp_1').future);

    final state = container.read(groupDashboardDataProvider('grp_1'));
    expect(state.hasValue, isTrue);
    expect(state.value!.members.length, 1);
    expect(state.value!.expenses.length, 1);
    expect(state.value!.settlements.isEmpty, isTrue);

    subscription.close();
  });

  testWidgets('DenkDashboardSkeleton and DenkGroupsListSkeleton render cleanly without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: DenkDashboardSkeleton(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DenkDashboardSkeleton), findsOneWidget);
    expect(find.byType(DenkSkeleton), findsWidgets);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: DenkGroupsListSkeleton(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DenkGroupsListSkeleton), findsOneWidget);
    expect(find.byType(DenkSkeleton), findsWidgets);
  });
}
