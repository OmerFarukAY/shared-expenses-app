import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/app.dart';
import 'package:denk/core/widgets/denk_button.dart';
import 'package:denk/features/auth/presentation/onboarding_display_name_screen.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/auth/domain/user_profile.dart';

class FakeUserProfileController extends UserProfileController {
  String? setCurrency;

  @override
  Future<UserProfile?> build() async {
    return null; // Force onboarding
  }

  @override
  Future<void> setDisplayName(
    String name, {
    String? preferredCurrency,
    String? languageCode,
  }) async {
    setCurrency = preferredCurrency;
  }
}

void main() {
  testWidgets('App starts with system locale and correct default currency', (
    tester,
  ) async {
    final fakeController = FakeUserProfileController();
    final providerScope = ProviderScope(
      overrides: [
        userProfileControllerProvider.overrideWith(() => fakeController),
      ],
      child: const DenkApp(forcedLocale: Locale('es', 'ES')),
    );

    await tester.pumpWidget(providerScope);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDisplayNameScreen), findsOneWidget);

    // Enter name and submit
    await tester.enterText(find.byType(TextField), 'Test User');
    await tester.tap(find.byType(DenkButton));
    await tester.pumpAndSettle();

    expect(fakeController.setCurrency, 'EUR');
  });

  testWidgets('App starts with EN locale defaults to USD', (tester) async {
    final fakeController = FakeUserProfileController();
    final providerScope = ProviderScope(
      overrides: [
        userProfileControllerProvider.overrideWith(() => fakeController),
      ],
      child: const DenkApp(forcedLocale: Locale('en', 'US')),
    );

    await tester.pumpWidget(providerScope);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDisplayNameScreen), findsOneWidget);

    // Enter name and submit
    await tester.enterText(find.byType(TextField), 'Test User');
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(fakeController.setCurrency, 'USD');
  });
}
