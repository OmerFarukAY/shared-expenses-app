import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/groups_list_screen.dart';
import 'package:denk/l10n/l10n.dart';

void main() {
  final testGroup = GroupModel(
    id: 'grp_123',
    name: 'Ankara Flat',
    defaultCurrency: 'TRY',
    inviteCode: 'DNK-7X2K',
    createdBy: 'user_1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    memberCount: 2,
  );

  Widget buildTestable({
    required List<GroupModel> groups,
    List<JoinRequestModel> userRequests = const [],
    ValueChanged<GroupModel>? onGroupSelected,
  }) {
    return ProviderScope(
      overrides: [
        userGroupsStreamProvider.overrideWith((ref) => Stream.value(groups)),
        userJoinRequestsStreamProvider.overrideWith(
          (ref) => Stream.value(userRequests),
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
        home: GroupsListScreen(onGroupSelected: onGroupSelected),
      ),
    );
  }

  testWidgets('GroupsListScreen renders empty state when no groups exist', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable(groups: []));
    await tester.pumpAndSettle();

    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.text('Create Group'), findsOneWidget);
    expect(find.text('Join Group'), findsOneWidget);
  });

  testWidgets('GroupsListScreen renders group cards and selects group on tap', (
    tester,
  ) async {
    GroupModel? selected;

    await tester.pumpWidget(
      buildTestable(groups: [testGroup], onGroupSelected: (g) => selected = g),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ankara Flat'), findsOneWidget);
    expect(find.text('2 members • TRY'), findsOneWidget);
    expect(find.text('Invite Code: DNK-7X2K'), findsOneWidget);

    await tester.tap(find.text('Ankara Flat'));
    await tester.pumpAndSettle();

    expect(selected, isNotNull);
    expect(selected!.id, 'grp_123');
  });

  testWidgets(
    'GroupsListScreen displays pending join request card without exposing group',
    (tester) async {
      final pendingReq = JoinRequestModel(
        id: 'user_bob',
        groupId: 'grp_secret_999',
        uid: 'user_bob',
        displayName: 'Bob',
        status: JoinRequestStatus.pending,
        inviteCode: 'DNK-9999',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        buildTestable(groups: [], userRequests: [pendingReq]),
      );
      await tester.pumpAndSettle();

      // Verify pending approval card is rendered
      expect(find.text('Pending Approval'), findsWidgets);
      expect(find.text('Waiting for group owner approval.'), findsWidgets);
      expect(find.text('Cancel Request'), findsOneWidget);

      // Verify secret group is NOT listed as a joined group
      expect(find.text('grp_secret_999'), findsNothing);
      expect(find.text('Secret Group'), findsNothing);
    },
  );
}
