import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/denk_button.dart';
import 'package:denk/core/widgets/denk_card.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/join_group_sheet.dart';
import 'package:denk/l10n/l10n.dart';

class DarkModeTestGroupRepository implements GroupRepository {
  final GroupModel testGroup;

  DarkModeTestGroupRepository(this.testGroup);

  @override
  Future<GroupModel> resolveInviteCode(String inviteCode) async => testGroup;

  @override
  Future<JoinRequestModel> createJoinRequest({
    required String inviteCode,
    required UserProfile user,
  }) async {
    return JoinRequestModel(
      id: user.uid,
      groupId: testGroup.id,
      uid: user.uid,
      displayName: user.displayName,
      status: JoinRequestStatus.pending,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<JoinRequestModel?> getJoinRequest({
    required String groupId,
    required String uid,
  }) async => null;

  @override
  Future<void> undoRejectJoinRequest({
    required String groupId,
    required String requestUid,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime.now();
  final testGroup = GroupModel(
    id: 'grp_dark_mode',
    name: 'Night Owls',
    defaultCurrency: 'USD',
    inviteCode: 'DNK-7X2K',
    createdBy: 'u_owl',
    createdAt: now,
    updatedAt: now,
    memberCount: 3,
  );

  final testUser = UserProfile(
    uid: 'u_seeker',
    displayName: 'Seeker',
    createdAt: now,
    updatedAt: now,
  );

  testWidgets(
    'JoinGroupSheet renders readable high-contrast card in dark theme upon submission',
    (tester) async {
      final fakeRepo = DarkModeTestGroupRepository(testGroup);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(testUser),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            theme: AppTheme.dark,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: JoinGroupSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invite code
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'DNK-7X2K');
      await tester.pumpAndSettle();

      // Verify group preview card appears
      expect(find.text('Night Owls'), findsOneWidget);

      // Tap Request to Join
      final requestBtn = find.byType(DenkButton);
      expect(requestBtn, findsOneWidget);
      await tester.tap(requestBtn);
      await tester.pumpAndSettle();

      // Verify Request Sent card is displayed
      expect(find.text('Request Sent'), findsOneWidget);

      // Verify that DenkCard is NOT using hardcoded light green AppColors.positiveLight
      final cardFinder = find.byType(DenkCard);
      expect(cardFinder, findsOneWidget);
      final denkCard = tester.widget<DenkCard>(cardFinder);

      expect(denkCard.backgroundColor, isNot(equals(AppColors.positiveLight)));
      // It uses dark-mode compatible translucent green
      expect(denkCard.backgroundColor, equals(AppColors.positive.withValues(alpha: 0.12)));

      // Verify Done button is rendered
      expect(find.text('Done'), findsOneWidget);
    },
  );
}

class _TestUserProfileController extends UserProfileController {
  final UserProfile _profile;
  _TestUserProfileController(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;
}
