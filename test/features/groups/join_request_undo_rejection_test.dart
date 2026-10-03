import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/data/group_repository.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/domain/join_request_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/join_requests_sheet.dart';
import 'package:denk/l10n/l10n.dart';

class UndoTestGroupRepository implements GroupRepository {
  final GroupModel group;
  final List<JoinRequestModel> requests;
  bool rejectCalled = false;
  bool undoCalled = false;
  String? lastRejectedUid;
  String? lastUndoneUid;

  UndoTestGroupRepository({
    required this.group,
    required this.requests,
  });

  @override
  Stream<List<JoinRequestModel>> watchGroupJoinRequests(String groupId) {
    return Stream.value(requests.where((r) => r.isPending).toList());
  }

  @override
  Future<void> rejectJoinRequest({
    required String groupId,
    required String requestUid,
    required String rejectedBy,
  }) async {
    rejectCalled = true;
    lastRejectedUid = requestUid;
    final index = requests.indexWhere((r) => r.uid == requestUid);
    if (index != -1) {
      requests[index] = requests[index].copyWith(
        status: JoinRequestStatus.rejected,
        rejectionCount: requests[index].rejectionCount + 1,
      );
    }
  }

  @override
  Future<void> undoRejectJoinRequest({
    required String groupId,
    required String requestUid,
  }) async {
    undoCalled = true;
    lastUndoneUid = requestUid;
    final index = requests.indexWhere((r) => r.uid == requestUid);
    if (index != -1) {
      requests[index] = requests[index].copyWith(
        status: JoinRequestStatus.pending,
        rejectionCount: requests[index].rejectionCount - 1,
      );
    }
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
  final testOwner = UserProfile(
    uid: 'owner_1',
    displayName: 'Owner User',
    preferredCurrency: 'TRY',
    createdAt: now,
    updatedAt: now,
  );

  final testGroup = GroupModel(
    id: 'grp_undo',
    name: 'Trip Pals',
    defaultCurrency: 'TRY',
    inviteCode: 'TRIP-1234',
    createdBy: 'owner_1',
    createdAt: now,
    updatedAt: now,
    memberCount: 1,
  );

  testWidgets(
    'Rejecting a join request displays SnackBar with Undo action and clicking it triggers undoRejectJoinRequest',
    (tester) async {
      final initialRequest = JoinRequestModel(
        id: 'user_req_1',
        groupId: testGroup.id,
        uid: 'user_req_1',
        displayName: 'Requester Bob',
        status: JoinRequestStatus.pending,
        inviteCode: testGroup.inviteCode,
        createdAt: now,
        updatedAt: now,
        rejectionCount: 0,
      );

      final fakeRepo = UndoTestGroupRepository(
        group: testGroup,
        requests: [initialRequest],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(testOwner),
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
            home: Scaffold(
              body: JoinRequestsSheet(group: testGroup),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Requester Bob is shown in list
      expect(find.text('Requester Bob'), findsOneWidget);

      // Find the reject button by tooltip
      final rejectBtn = find.byTooltip('Reddet');
      expect(rejectBtn, findsOneWidget);
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      // Verify repo reject was called
      expect(fakeRepo.rejectCalled, isTrue);
      expect(fakeRepo.lastRejectedUid, 'user_req_1');

      // Verify SnackBar appeared with 'Talep reddedildi' and 'Geri Al'
      expect(find.text('Talep reddedildi'), findsOneWidget);
      expect(find.text('Geri Al'), findsOneWidget);

      // Tap 'Geri Al' (Undo) action button
      await tester.tap(find.text('Geri Al'));
      await tester.pumpAndSettle();

      // Verify undoRejectJoinRequest was called
      expect(fakeRepo.undoCalled, isTrue);
      expect(fakeRepo.lastUndoneUid, 'user_req_1');
    },
  );

  testWidgets(
    'English locale displays "Request rejected" and "Undo"',
    (tester) async {
      final initialRequest = JoinRequestModel(
        id: 'user_req_2',
        groupId: testGroup.id,
        uid: 'user_req_2',
        displayName: 'Requester Alice',
        status: JoinRequestStatus.pending,
        inviteCode: testGroup.inviteCode,
        createdAt: now,
        updatedAt: now,
        rejectionCount: 0,
      );

      final fakeRepo = UndoTestGroupRepository(
        group: testGroup,
        requests: [initialRequest],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(testOwner),
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
            home: Scaffold(
              body: JoinRequestsSheet(group: testGroup),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rejectBtn = find.byTooltip('Reject');
      expect(rejectBtn, findsOneWidget);
      await tester.tap(rejectBtn);
      await tester.pumpAndSettle();

      expect(find.text('Request rejected'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(fakeRepo.undoCalled, isTrue);
      expect(fakeRepo.lastUndoneUid, 'user_req_2');
    },
  );
}
