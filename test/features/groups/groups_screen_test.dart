import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/groups/domain/group_model.dart';
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
    ValueChanged<GroupModel>? onGroupSelected,
  }) {
    return ProviderScope(
      overrides: [
        userGroupsStreamProvider.overrideWith((ref) => Stream.value(groups)),
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
}
