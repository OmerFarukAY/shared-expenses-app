import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/auth/domain/user_profile.dart';
import 'package:denk/features/auth/presentation/auth_controller.dart';
import 'package:denk/features/groups/presentation/create_group_sheet.dart';
import 'package:denk/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserProfileController extends UserProfileController {
  final UserProfile? profile;
  FakeUserProfileController(this.profile);

  @override
  Future<UserProfile?> build() async => profile;
}

void main() {
  final testProfile = UserProfile(
    uid: 'user_omer',
    displayName: 'Ömer',
    preferredCurrency: 'USD',
    languageCode: 'tr',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Widget buildTestable({required Locale locale}) {
    return ProviderScope(
      overrides: [
        userProfileControllerProvider.overrideWith(
          () => FakeUserProfileController(testProfile),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: CreateGroupSheet()),
      ),
    );
  }

  testWidgets(
    'CreateGroupSheet defaults to TRY for Turkish locale',
    (tester) async {
      await tester.pumpWidget(buildTestable(locale: const Locale('tr')));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<Currency>>(
        find.byType(DropdownButton<Currency>),
      );
      expect(dropdown.value?.code, 'TRY');
      expect(find.text('TRY (₺) — Turkish Lira'), findsOneWidget);
    },
  );

  testWidgets(
    'CreateGroupSheet defaults to USD for English locale',
    (tester) async {
      await tester.pumpWidget(buildTestable(locale: const Locale('en')));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<Currency>>(
        find.byType(DropdownButton<Currency>),
      );
      expect(dropdown.value?.code, 'USD');
      expect(find.text('USD (\$) — US Dollar'), findsOneWidget);
    },
  );

  testWidgets(
    'CreateGroupSheet defaults to EUR for Spanish / French / Italian locale',
    (tester) async {
      await tester.pumpWidget(buildTestable(locale: const Locale('es')));
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownButton<Currency>>(
        find.byType(DropdownButton<Currency>),
      );
      expect(dropdown.value?.code, 'EUR');
      expect(find.text('EUR (€) — Euro'), findsOneWidget);
    },
  );
}
