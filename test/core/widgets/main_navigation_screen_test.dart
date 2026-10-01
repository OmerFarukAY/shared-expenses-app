import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/core/widgets/main_navigation_screen.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/domain/group_model.dart';
import 'package:denk/features/groups/presentation/group_controller.dart';
import 'package:denk/l10n/l10n.dart';

class _FakeUserProfileController extends UserProfileController {
  final UserProfile? _profile;
  _FakeUserProfileController(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;
}

void main() {
  testWidgets('MainNavigationScreen switches tabs smoothly without error', (tester) async {
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'user_1',
      displayName: 'Test User',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userProfileControllerProvider.overrideWith(() => _FakeUserProfileController(profile)),
          userGroupsStreamProvider.overrideWith((ref) => Stream.value(<GroupModel>[])),
          userJoinRequestsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: const MainNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially at index 0 (Groups screen)
    expect(find.text('Denk'), findsWidgets);
    expect(find.text('No groups yet'), findsOneWidget);

    // Tap Settings tab
    final settingsNav = find.text('Settings');
    expect(settingsNav, findsWidgets);
    await tester.tap(settingsNav.last);
    await tester.pumpAndSettle();

    // Should now show Settings screen contents
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);

    // Tap Denk tab back
    final denkNav = find.text('Denk');
    await tester.tap(denkNav.last);
    await tester.pumpAndSettle();

    expect(find.text('No groups yet'), findsOneWidget);
  });
}
