import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/app.dart';
import 'package:denk/core/errors/app_exception.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/denk_button.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/join_group_sheet.dart';
import 'package:denk/features/groups/presentation/join_requests_sheet.dart';
import 'package:denk/l10n/l10n.dart';

class BugFixTestRepository implements GroupRepository {
  final GroupModel group;
  final JoinRequestModel? existingRequest;
  final Completer<JoinRequestModel>? createCompleter;
  final bool shouldThrowOnCreate;
  final String? createErrorCode;
  bool createCalled = false;
  bool rejectCalled = false;
  bool undoCalled = false;

  BugFixTestRepository({
    required this.group,
    this.existingRequest,
    this.createCompleter,
    this.shouldThrowOnCreate = false,
    this.createErrorCode,
  });

  @override
  Future<GroupModel> resolveInviteCode(String inviteCode) async {
    return group;
  }

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
    if (createCompleter != null) {
      return createCompleter!.future;
    }
    if (shouldThrowOnCreate) {
      throw AppException(
        message: 'Permission denied',
        code: createErrorCode ?? 'permission-denied',
      );
    }
    return JoinRequestModel(
      id: user.uid,
      groupId: group.id,
      uid: user.uid,
      displayName: user.displayName,
      status: JoinRequestStatus.pending,
      inviteCode: group.inviteCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      rejectionCount: existingRequest?.rejectionCount ?? 0,
    );
  }

  @override
  Stream<List<JoinRequestModel>> watchGroupJoinRequests(String groupId) {
    if (existingRequest != null && existingRequest!.isPending) {
      return Stream.value([existingRequest!]);
    }
    return Stream.value([]);
  }

  @override
  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestUid,
    required String rejectedBy,
  }) async {
    rejectCalled = true;
  }

  @override
  Future<void> undoRejectJoinRequest({
    required String groupId,
    required String requestUid,
  }) async {
    undoCalled = true;
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
    uid: 'test_user_1',
    displayName: 'Test Requester',
    preferredCurrency: 'TRY',
    createdAt: now,
    updatedAt: now,
  );

  final testGroup = GroupModel(
    id: 'grp_bug_fix',
    name: 'Bug Fix Group',
    defaultCurrency: 'TRY',
    inviteCode: 'DNK-7X2K',
    createdBy: 'admin_1',
    createdAt: now,
    updatedAt: now,
    memberCount: 2,
  );

  testWidgets(
    'Issue 3: Re-request shows spinner during loading and does NOT flicker into success state when request fails',
    (tester) async {
      final rejectedRequest = JoinRequestModel(
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

      final completer = Completer<JoinRequestModel>();
      final fakeRepo = BugFixTestRepository(
        group: testGroup,
        existingRequest: rejectedRequest,
        createCompleter: completer,
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
            scaffoldMessengerKey: rootScaffoldMessengerKey,
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

      // Verify attempts banner shows 1/3
      expect(find.textContaining('1/3 hak kullanıldı'), findsOneWidget);
      expect(find.text('Tekrar İstek Gönder'), findsOneWidget);

      // Tap "Tekrar İstek Gönder"
      final btnFinder = find.byType(DenkButton);
      await tester.tap(btnFinder);
      await tester.pump(); // Advance microtasks to enter loading state

      // 1. Verify button is in loading state (CircularProgressIndicator visible)
      expect(fakeRepo.createCalled, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 2. Verify UI has NOT prematurely shifted to "İstek Gönderildi" (no optimistic false state)
      expect(find.text('İstek Gönderildi'), findsNothing);

      // Simulate failure from Firestore (permission-denied)
      completer.completeError(
        const AppException(
          message: 'Permission denied',
          code: 'permission-denied',
        ),
      );
      await tester.pumpAndSettle();

      // 3. Verify screen stayed on the sheet with error displayed and button restored
      expect(find.text('İstek Gönderildi'), findsNothing);
      expect(find.text('Tekrar İstek Gönder'), findsOneWidget);
      expect(find.textContaining('Erişim kısıtlandı'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 3: Re-request transitions to success screen ONLY when createJoinRequest successfully resolves',
    (tester) async {
      final rejectedRequest = JoinRequestModel(
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

      final fakeRepo = BugFixTestRepository(
        group: testGroup,
        existingRequest: rejectedRequest,
        shouldThrowOnCreate: false,
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
            scaffoldMessengerKey: rootScaffoldMessengerKey,
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

      // Tap "Tekrar İstek Gönder"
      final btnFinder = find.byType(DenkButton);
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Verify successful transition
      expect(fakeRepo.createCalled, isTrue);
      expect(find.text('İstek Gönderildi'), findsOneWidget);
      expect(find.text('Tamam'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 2: Admin rejection triggers SnackBar via rootScaffoldMessengerKey with Undo action',
    (tester) async {
      final pendingReq = JoinRequestModel(
        id: 'req_admin_test',
        groupId: testGroup.id,
        uid: 'req_admin_test',
        displayName: 'Requester Alice',
        status: JoinRequestStatus.pending,
        inviteCode: testGroup.inviteCode,
        createdAt: now,
        updatedAt: now,
        rejectionCount: 0,
      );

      final fakeRepo = BugFixTestRepository(
        group: testGroup,
        existingRequest: pendingReq,
      );

      final adminUser = UserProfile(
        uid: 'admin_1',
        displayName: 'Admin User',
        preferredCurrency: 'TRY',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(adminUser),
            ),
          ],
          child: MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            locale: const Locale('tr'),
            theme: AppTheme.light,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: JoinRequestsSheet(group: testGroup),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify request is displayed
      expect(find.text('Requester Alice'), findsOneWidget);

      // Tap reject button
      final rejectBtn = find.byTooltip('Reddet');
      expect(rejectBtn, findsOneWidget);
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      // Verify repo reject was called
      expect(fakeRepo.rejectCalled, isTrue);

      // Verify global SnackBar appeared with 'Talep reddedildi' and 'Geri Al'
      expect(find.text('Talep reddedildi'), findsOneWidget);
      expect(find.text('Geri Al'), findsOneWidget);

      // Tap "Geri Al"
      await tester.tap(find.text('Geri Al'));
      await tester.pumpAndSettle();

      // Verify undo was called
      expect(fakeRepo.undoCalled, isTrue);
    },
  );
}
