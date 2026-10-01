import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/app.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/features/auth/presentation/onboarding_display_name_screen.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/auth/domain/user_profile.dart';

class FakeUserProfileController extends UserProfileController {
  @override
  Future<UserProfile?> build() async {
    return null; // Force onboarding
  }
}

void main() {
  testWidgets('App starts with system locale and correct default currency', (tester) async {
    // Override the user profile to force onboarding
    final providerScope = ProviderScope(
      overrides: [
        userProfileControllerProvider.overrideWith(() => FakeUserProfileController()),
      ],
      // We force the locale in DenkApp for testing
      child: const DenkApp(forcedLocale: Locale('es', 'ES')),
    );

    await tester.pumpWidget(providerScope);
    await tester.pumpAndSettle();

    // Verify OnboardingDisplayNameScreen is present
    expect(find.byType(OnboardingDisplayNameScreen), findsOneWidget);

    // Verify language is Spanish (checking a known localized string if possible)
    // Or just verify the default currency dropdown value. For 'es', it should be EUR.
    
    // Find the DropdownButton<Currency>
    final dropdownFinder = find.byType(DropdownButton<Currency>);
    expect(dropdownFinder, findsOneWidget);

    final DropdownButton<Currency> dropdown = tester.widget(dropdownFinder);
    expect(dropdown.value, Currency.eurCurrency);
  });

  testWidgets('App starts with EN locale defaults to USD', (tester) async {
    final providerScope = ProviderScope(
      overrides: [
        userProfileControllerProvider.overrideWith(() => FakeUserProfileController()),
      ],
      child: const DenkApp(forcedLocale: Locale('en', 'US')),
    );

    await tester.pumpWidget(providerScope);
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingDisplayNameScreen), findsOneWidget);
    
    final dropdownFinder = find.byType(DropdownButton<Currency>);
    expect(dropdownFinder, findsOneWidget);

    final DropdownButton<Currency> dropdown = tester.widget(dropdownFinder);
    expect(dropdown.value, Currency.usdCurrency);
  });
}
