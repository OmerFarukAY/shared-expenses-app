import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart' show AuthProvider, AuthCredential;
import 'package:denk/features/auth/domain/account_deletion_service.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/settings/presentation/settings_screen.dart';
import 'package:denk/l10n/l10n.dart';

void main() {
  final now = DateTime.now();

  testWidgets(
    'SettingsScreen renders profile, language selector, and privacy explanation',
    (tester) async {
      final fakeController = _MockUserProfileController(
        UserProfile(
          uid: 'anon_user_123456789',
          displayName: 'Ömer',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileControllerProvider.overrideWith(() => fakeController),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Profile Info
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Ömer'), findsOneWidget);
      expect(find.text('Anonymous Firebase Account'), findsOneWidget);
      expect(find.textContaining('UID: anon_use...'), findsOneWidget);

      // Verify Preferences items
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);

      // Verify Privacy Info & Destructive deletion
      expect(find.text('Privacy Information'), findsOneWidget);
      expect(find.text('Delete Account'), findsWidgets);

      // Tap Language to open selection dialog
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // All 5 languages should be present in dialog
      expect(find.text('English'), findsWidgets);
      expect(find.text('Türkçe'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);

      // Select Türkçe
      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();

      // Verify Privacy Info Dialog
      await tester.ensureVisible(find.text('Read'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read'));
      await tester.pumpAndSettle();
      expect(
        find.text('Privacy-First, Data-Minimized Architecture'),
        findsOneWidget,
      );

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('SettingsScreen delete account triggers confirmation dialog', (
    tester,
  ) async {
    final fakeController = _MockUserProfileController(
      UserProfile(
        uid: 'anon_user_123',
        displayName: 'Ömer',
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileControllerProvider.overrideWith(() => fakeController),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to reveal destructive delete button
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    // Tap Delete Account (new label)
    final deleteButtons = find.text('Delete Account');
    expect(deleteButtons, findsWidgets);
    await tester.tap(deleteButtons.last);
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog - new flow uses 'Confirm' not 'Delete'
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Permanently Delete Account?'), findsOneWidget);

    // Tap Confirm in dialog
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(fakeController.deleteCalled, isTrue);
  });
}

class _MockUserProfileController extends AsyncNotifier<UserProfile?>
    implements UserProfileController {
  final UserProfile? _profile;
  bool deleteCalled = false;
  String? updatedName;

  _MockUserProfileController(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;

  @override
  Future<void> setDisplayName(
    String name, {
    String? preferredCurrency,
    String? languageCode,
  }) async {}

  @override
  Future<void> updateDisplayName(String name) async {
    updatedName = name;
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalled = true;
    state = const AsyncValue.data(null);
  }

  @override
  Future<List<OwnedGroupBlock>> analyzeOwnershipBlocks() async => const [];

  @override
  Future<void> transferGroupOwnership({
    required String groupId,
    required String currentOwnerUid,
    required String newOwnerUid,
    required String newOwnerDisplayName,
  }) async {}

  @override
  Future<void> deleteAccountFull() async {
    deleteCalled = true;
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> linkGoogle({AuthProvider? customProvider}) async {}

  @override
  Future<void> linkApple({AuthProvider? customProvider}) async {}

  @override
  Future<void> switchToExistingAccount(AuthCredential credential) async {}

  @override
  Future<void> switchToExistingProvider(AuthProvider provider) async {}
}
