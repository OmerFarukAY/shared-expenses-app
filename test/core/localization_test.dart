import 'package:denk/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Coverage Tests (5 Languages)', () {
    const supportedLocales = [
      Locale('en'),
      Locale('tr'),
      Locale('es'),
      Locale('fr'),
      Locale('it'),
    ];

    test(
      'All 5 locales are supported by AppLocalizations.supportedLocales',
      () {
        final supportedCodes = AppLocalizations.supportedLocales
            .map((l) => l.languageCode)
            .toSet();

        for (final locale in supportedLocales) {
          expect(
            supportedCodes.contains(locale.languageCode),
            isTrue,
            reason: 'Locale ${locale.languageCode} must be supported',
          );
        }
      },
    );

    for (final locale in supportedLocales) {
      testWidgets('Loads all core keys for locale: ${locale.languageCode}', (
        tester,
      ) async {
        late AppLocalizations l10n;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: Builder(
              builder: (context) {
                l10n = AppLocalizations.of(context)!;
                return Container();
              },
            ),
          ),
        );

        // Core Brand & Navigation
        expect(l10n.appName, isNotEmpty);
        expect(l10n.appTagline, isNotEmpty);
        expect(l10n.welcomeTitle, isNotEmpty);
        expect(l10n.commonSave, isNotEmpty);
        expect(l10n.commonCancel, isNotEmpty);
        expect(l10n.commonDelete, isNotEmpty);
        expect(l10n.commonDone, isNotEmpty);

        // Groups
        expect(l10n.navGroups, isNotEmpty);
        expect(l10n.createGroup, isNotEmpty);
        expect(l10n.joinGroup, isNotEmpty);
        expect(l10n.membersLabel, isNotEmpty);

        // Expenses & Splits
        expect(l10n.addExpense, isNotEmpty);
        expect(l10n.splitEqual, isNotEmpty);
        expect(l10n.splitCustom, isNotEmpty);
        expect(l10n.splitPercentage, isNotEmpty);
        expect(l10n.paidBy, isNotEmpty);
        expect(l10n.splitBetween, isNotEmpty);

        // Settlements
        expect(l10n.settleTab, isNotEmpty);
        expect(l10n.markAsSettled, isNotEmpty);
        expect(l10n.allSettled, isNotEmpty);

        // Settings & Themes & Privacy
        expect(l10n.settingsTitle, isNotEmpty);
        expect(l10n.settingsPreferences, isNotEmpty);
        expect(l10n.themeTitle, isNotEmpty);
        expect(l10n.themeSystem, isNotEmpty);
        expect(l10n.themeLight, isNotEmpty);
        expect(l10n.themeDark, isNotEmpty);
        expect(l10n.settingsPrivacyInfo, isNotEmpty);
        expect(l10n.anonymousAccount, isNotEmpty);
        expect(l10n.copyId, isNotEmpty);
      });
    }

    testWidgets('Turkish localization contains correct characters and words', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return Container();
            },
          ),
        ),
      );

      expect(l10n.createGroup, contains('Oluştur'));
      expect(l10n.settleTab, contains('Hesap Kapat'));
      expect(l10n.settingsPreferences, equals('Tercihler'));
      expect(l10n.themeSystem, equals('Sistem Varsayılanı'));
    });

    testWidgets('Spanish localization contains natural terminology', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return Container();
            },
          ),
        ),
      );

      expect(l10n.createGroup, contains('Crear'));
      expect(l10n.splitEqual, equals('A partes iguales'));
      expect(l10n.settingsPreferences, equals('Preferencias'));
      expect(l10n.themeTitle, equals('Tema'));
    });

    testWidgets('French localization contains natural terminology', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return Container();
            },
          ),
        ),
      );

      expect(l10n.createGroup, contains('Créer'));
      expect(l10n.splitEqual, equals('À parts égales'));
      expect(l10n.settingsPreferences, equals('Préférences'));
      expect(l10n.themeDark, equals('Sombre'));
    });

    testWidgets('Italian localization contains natural terminology', (
      tester,
    ) async {
      late AppLocalizations l10n;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return Container();
            },
          ),
        ),
      );

      expect(l10n.createGroup, contains('Crea'));
      expect(l10n.splitEqual, equals('In parti uguali'));
      expect(l10n.settingsPreferences, equals('Preferenze'));
      expect(l10n.themeLight, equals('Chiaro'));
    });
  });
}
