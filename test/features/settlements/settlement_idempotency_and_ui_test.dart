import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/denk_button.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/expenses/domain/expense_category.dart';
import 'package:denk/features/expenses/domain/expense_model.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/features/groups/presentation/group_dashboard_screen.dart';
import 'package:denk/features/settlements/data/settlement_repository.dart';
import 'package:denk/features/settlements/domain/settlement_model.dart';
import 'package:denk/features/settlements/presentation/settlement_controller.dart';
import 'package:denk/l10n/app_localizations.dart';

class FakeIdempotentSettlementRepository implements SettlementRepository {
  final Map<String, SettlementRecord> storedRecords = {};
  int recordCallCount = 0;
  Completer<void>? recordCompleter;

  @override
  Future<void> recordSettlement(SettlementRecord settlement) async {
    recordCallCount++;
    if (recordCompleter != null) {
      await recordCompleter!.future;
    }
    // Idempotent transaction simulation:
    // If the doc ID already exists, safely no-op without duplicating.
    if (storedRecords.containsKey(settlement.id)) {
      return;
    }
    storedRecords[settlement.id] = settlement;
  }

  @override
  Stream<List<SettlementRecord>> watchGroupSettlements(String groupId) {
    return Stream.value(storedRecords.values.toList());
  }

  @override
  Future<void> deleteSettlement({
    required String groupId,
    required String settlementId,
  }) async {
    storedRecords.remove(settlementId);
  }
}

class _TestUserProfileController extends UserProfileController {
  final UserProfile _profile;
  _TestUserProfileController(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;
}

void main() {
  final now = DateTime.now();

  group('Settlement Deterministic ID Generation', () {
    test('generateDeterministicId is pure and deterministic for identical inputs', () {
      final id1 = SettlementRecord.generateDeterministicId(
        groupId: 'grp_trip_123',
        fromUid: 'usr_alice',
        toUid: 'usr_bob',
        currency: 'TRY',
        amountMinor: 15000,
        activityToken: 'exp_1_stl_0',
      );

      final id2 = SettlementRecord.generateDeterministicId(
        groupId: 'grp_trip_123',
        fromUid: 'usr_alice',
        toUid: 'usr_bob',
        currency: 'TRY',
        amountMinor: 15000,
        activityToken: 'exp_1_stl_0',
      );

      expect(id1, equals(id2));
      expect(id1.startsWith('stl_'), isTrue);
      expect(id1.contains('grptrip123'), isTrue);
      expect(id1.contains('usralice'), isTrue);
      expect(id1.contains('usrbob'), isTrue);
      expect(id1.contains('TRY'), isTrue);
      expect(id1.contains('15000'), isTrue);
    });

    test('generateDeterministicId distinguishes amounts, currencies, and activity tokens', () {
      final baseId = SettlementRecord.generateDeterministicId(
        groupId: 'grp_1',
        fromUid: 'u1',
        toUid: 'u2',
        currency: 'USD',
        amountMinor: 5000,
        activityToken: 'token_a',
      );

      final diffAmountId = SettlementRecord.generateDeterministicId(
        groupId: 'grp_1',
        fromUid: 'u1',
        toUid: 'u2',
        currency: 'USD',
        amountMinor: 6000,
        activityToken: 'token_a',
      );

      final diffCurrencyId = SettlementRecord.generateDeterministicId(
        groupId: 'grp_1',
        fromUid: 'u1',
        toUid: 'u2',
        currency: 'EUR',
        amountMinor: 5000,
        activityToken: 'token_a',
      );

      final diffTokenId = SettlementRecord.generateDeterministicId(
        groupId: 'grp_1',
        fromUid: 'u1',
        toUid: 'u2',
        currency: 'USD',
        amountMinor: 5000,
        activityToken: 'token_b',
      );

      expect(baseId, isNot(equals(diffAmountId)));
      expect(baseId, isNot(equals(diffCurrencyId)));
      expect(baseId, isNot(equals(diffTokenId)));
    });
  });

  group('Settlement Idempotent Transaction Execution', () {
    test('Simultaneous duplicate settlement records are idempotent and do not duplicate', () async {
      final fakeRepo = FakeIdempotentSettlementRepository();

      final record = SettlementRecord(
        id: SettlementRecord.generateDeterministicId(
          groupId: 'grp_test',
          fromUid: 'u1',
          toUid: 'u2',
          currency: 'TRY',
          amountMinor: 10000,
          activityToken: 'exp_10',
        ),
        groupId: 'grp_test',
        fromUid: 'u1',
        fromName: 'Alice',
        toUid: 'u2',
        toName: 'Bob',
        amountMinor: 10000,
        currency: 'TRY',
        settledAt: now,
        createdBy: 'u1',
      );

      // Execute first record
      await fakeRepo.recordSettlement(record);
      expect(fakeRepo.storedRecords.length, equals(1));
      expect(fakeRepo.recordCallCount, equals(1));

      // Execute duplicate record with the same deterministic ID (concurrent tap or 2nd device)
      await fakeRepo.recordSettlement(record);
      // Still only 1 record stored
      expect(fakeRepo.storedRecords.length, equals(1));
      expect(fakeRepo.recordCallCount, equals(2));
    });
  });

  group('Settlement UI Confirmation & Button States', () {
    final testGroup = GroupModel(
      id: 'grp_settle_ui',
      name: 'Holiday Squad',
      defaultCurrency: 'TRY',
      inviteCode: 'DNK-SETTLE',
      createdBy: 'u_alice',
      createdAt: now,
      updatedAt: now,
      memberCount: 2,
    );

    final testUser = UserProfile(
      uid: 'u_alice',
      displayName: 'Alice',
      createdAt: now,
      updatedAt: now,
    );

    final testMembers = [
      GroupMember(
        uid: 'u_alice',
        displayName: 'Alice',
        role: MemberRole.owner,
        joinedAt: now,
      ),
      GroupMember(
        uid: 'u_bob',
        displayName: 'Bob',
        role: MemberRole.member,
        joinedAt: now,
      ),
    ];

    // Expense: Bob paid 200 TRY for both Alice and Bob. Alice owes Bob 100 TRY.
    final testExpense = ExpenseModel(
      id: 'exp_hotel_1',
      groupId: 'grp_settle_ui',
      title: 'Hotel',
      category: ExpenseCategory.transport,
      currency: 'TRY',
      totalMinor: 20000,
      date: now,
      splitMethod: SplitMethod.equal,
      payers: const {'u_bob': 20000},
      participants: const ['u_alice', 'u_bob'],
      splits: const {'u_alice': 10000, 'u_bob': 10000},
      createdBy: 'u_bob',
      createdAt: now,
      updatedAt: now,
    );

    testWidgets('Settlement dialog displays localized confirmation in Turkish', (tester) async {
      final fakeRepo = FakeIdempotentSettlementRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(testUser),
            ),
            groupDashboardDataProvider(testGroup.id).overrideWithValue(
              AsyncValue.data(
                GroupDashboardData(
                  members: testMembers,
                  expenses: [testExpense],
                  settlements: const [],
                ),
              ),
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
            home: GroupDashboardScreen(group: testGroup),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Settle Up tab (tab index 2)
      final settleTabFinder = find.byType(Tab).at(2);
      expect(settleTabFinder, findsOneWidget);
      await tester.tap(settleTabFinder);
      await tester.pumpAndSettle();

      // Find 'Ödendi Olarak İşaretle' button
      final markAsSettledBtn = find.widgetWithText(DenkButton, 'Ödendi Olarak İşaretle');
      expect(markAsSettledBtn, findsOneWidget);

      // Tap to open confirmation dialog
      await tester.tap(markAsSettledBtn);
      await tester.pumpAndSettle();

      // Verify localized confirmation text is present and NOT in English
      expect(find.text('Alice kişisinin Bob kişisine ödeme yaptığını onaylıyor musunuz?'), findsOneWidget);
      expect(find.text('Confirm that Alice paid Bob?'), findsNothing);

      // Verify Cancel and Confirm buttons are in Turkish
      expect(find.text('İptal'), findsOneWidget);
      expect(find.text('Onayla'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Onayla'));
      await tester.pumpAndSettle();

      // Verify recordSettlement was called on repository with deterministic ID
      expect(fakeRepo.storedRecords.length, equals(1));
      final recordedDoc = fakeRepo.storedRecords.values.first;
      expect(recordedDoc.fromUid, equals('u_alice'));
      expect(recordedDoc.toUid, equals('u_bob'));
      expect(recordedDoc.amountMinor, equals(10000));
      expect(recordedDoc.id.startsWith('stl_'), isTrue);
    });

    testWidgets('Settlement button enters disabled loading state during in-flight operation', (tester) async {
      final fakeRepo = FakeIdempotentSettlementRepository();
      // Keep settlement operation in-flight with an open completer
      fakeRepo.recordCompleter = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settlementRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileControllerProvider.overrideWith(
              () => _TestUserProfileController(testUser),
            ),
            groupDashboardDataProvider(testGroup.id).overrideWithValue(
              AsyncValue.data(
                GroupDashboardData(
                  members: testMembers,
                  expenses: [testExpense],
                  settlements: const [],
                ),
              ),
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
            home: GroupDashboardScreen(group: testGroup),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Settle tab (tab index 2)
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      // Tap Mark as Settled
      final markAsSettledBtn = find.widgetWithText(DenkButton, 'Mark as Settled');
      await tester.tap(markAsSettledBtn);
      await tester.pumpAndSettle();

      // Verify English localized subtitle
      expect(find.text('Confirm that Alice paid Bob?'), findsOneWidget);

      // Tap Confirm in dialog
      await tester.tap(find.text('Confirm'));
      // Pump once to close dialog and trigger in-flight state
      await tester.pump();

      // Verify that while operation is in-flight, the DenkButton has isLoading: true
      final denkButton = tester.widget<DenkButton>(find.byType(DenkButton));
      expect(denkButton.isLoading, isTrue);
      expect(denkButton.onPressed, isNull);

      // Attempt second tap while in-flight (should be ignored / no-op)
      await tester.tap(find.byType(DenkButton), warnIfMissed: false);
      await tester.pump();
      expect(fakeRepo.recordCallCount, equals(1));

      // Resolve in-flight completer
      fakeRepo.recordCompleter!.complete();
      await tester.pumpAndSettle();

      // Verify final success
      expect(fakeRepo.storedRecords.length, equals(1));
    });
  });
}
