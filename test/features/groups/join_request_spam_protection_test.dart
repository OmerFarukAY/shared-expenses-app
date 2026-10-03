import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/widgets.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/join_group_sheet.dart';
import 'package:denk/l10n/l10n.dart';

class SpamTestGroupRepository implements GroupRepository {
  final GroupModel group;
  JoinRequestModel? existingRequest;
  bool createCalled = false;

  SpamTestGroupRepository({
    required this.group,
    this.existingRequest,
  });

  @override
  Future<GroupModel> resolveInviteCode(String inviteCode) async => group;

  @override
  Future<JoinRequestModel?> getJoinRequest({
    required String groupId,
    required String uid,
  }) async {
    return existingRequest;
  }

  @override
  Future<JoinRequestModel> createJoinRequest({
    required String inviteCode,
    required UserProfile user,
  }) async {
    createCalled = true;
    final model = JoinRequestModel(
      id: user.uid,
      groupId: group.id,
      uid: user.uid,
      displayName: user.displayName,
      status: JoinRequestStatus.pending,
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rejectionCount: existingRequest?.rejectionCount ?? 0,
    );
    existingRequest = model;
    return model;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestUserProfileController extends UserProfileController {
  final UserProfile? _profile;
  _TestUserProfileController(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;
}

void main() {
  final now = DateTime.now();
  final testUser = UserProfile(
    uid: 'u_applicant',
    displayName: 'Applicant User',
    createdAt: now,
    updatedAt: now,
  );

  final testGroup = GroupModel(
    id: 'grp_spam',
    name: 'Board Gamers',
    defaultCurrency: 'TRY',
    inviteCode: 'DNK-7X2K',
    createdBy: 'u_admin',
    createdAt: now,
    updatedAt: now,
    memberCount: 4,
  );

  testWidgets(
    'Displays "Bu gruba katılma sınırınızı doldurdunuz" warning card and disables button when rejectionCount >= 3',
    (tester) async {
      final blockedRequest = JoinRequestModel(
        id: testUser.uid,
        groupId: testGroup.id,
        uid: testUser.uid,
        displayName: testUser.displayName,
        status: JoinRequestStatus.rejected,
        inviteCode: testGroup.inviteCode,
        createdAt: now,
        updatedAt: now,
        rejectionCount: 3,
      );

      final fakeRepo = SpamTestGroupRepository(
        group: testGroup,
        existingRequest: blockedRequest,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(testUser),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            theme: AppTheme.light,
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

      // Enter valid code
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'DNK-7X2K');
      await tester.pumpAndSettle();

      // Verify group card appeared
      expect(find.text('Board Gamers'), findsOneWidget);

      // Verify the limit warning card is displayed with the exact text requested
      expect(find.text('Bu gruba katılma sınırınızı doldurdunuz'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);

      // Verify the button is disabled (onPressed is null)
      final btnFinder = find.byType(DenkButton);
      expect(btnFinder, findsOneWidget);
      final denkButton = tester.widget<DenkButton>(btnFinder);
      expect(denkButton.onPressed, isNull);

      // Tap button and verify createJoinRequest was NOT called
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();
      expect(fakeRepo.createCalled, isFalse);
    },
  );

  testWidgets(
    'Displays attempts used banner and allows re-requesting when rejectionCount < 3',
    (tester) async {
      final rejectedOnceRequest = JoinRequestModel(
        id: testUser.uid,
        groupId: testGroup.id,
        uid: testUser.uid,
        displayName: testUser.displayName,
        status: JoinRequestStatus.rejected,
        inviteCode: testGroup.inviteCode,
        createdAt: now,
        updatedAt: now,
        rejectionCount: 1,
      );

      final fakeRepo = SpamTestGroupRepository(
        group: testGroup,
        existingRequest: rejectedOnceRequest,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(testUser),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            theme: AppTheme.light,
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

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'DNK-7X2K');
      await tester.pumpAndSettle();

      // Verify attempts banner shows 1/3
      expect(find.textContaining('1/3 hak kullanıldı'), findsOneWidget);

      // Verify button says "Tekrar İstek Gönder" and is enabled
      expect(find.text('Tekrar İstek Gönder'), findsOneWidget);
      final btnFinder = find.byType(DenkButton);
      final denkButton = tester.widget<DenkButton>(btnFinder);
      expect(denkButton.onPressed, isNotNull);

      // Tap to submit re-request
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Verify createJoinRequest was called and transitioned to Request Sent
      expect(fakeRepo.createCalled, isTrue);
      expect(find.text('İstek Gönderildi'), findsOneWidget);
    },
  );

  testWidgets(
    'Displays pending approval banner and disables button when request is already pending',
    (tester) async {
      final pendingRequest = JoinRequestModel(
        id: testUser.uid,
        groupId: testGroup.id,
        uid: testUser.uid,
        displayName: testUser.displayName,
        status: JoinRequestStatus.pending,
        inviteCode: testGroup.inviteCode,
        createdAt: now,
        updatedAt: now,
        rejectionCount: 0,
      );

      final fakeRepo = SpamTestGroupRepository(
        group: testGroup,
        existingRequest: pendingRequest,
      );

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
            theme: AppTheme.light,
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

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'DNK-7X2K');
      await tester.pumpAndSettle();

      // Verify pending approval banner is displayed
      expect(find.text('Waiting for group owner approval.'), findsOneWidget);

      // Verify button is disabled
      final btnFinder = find.byType(DenkButton);
      final denkButton = tester.widget<DenkButton>(btnFinder);
      expect(denkButton.onPressed, isNull);
    },
  );
}
