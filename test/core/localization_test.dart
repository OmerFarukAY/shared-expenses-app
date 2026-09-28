import 'dart:convert';
import 'dart:io';
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

        // Phase 15 Join Requests & Approvals
        expect(l10n.requestToJoinButton, isNotEmpty);
        expect(l10n.joinRequestSentTitle, isNotEmpty);
        expect(
          l10n.joinRequestSentSubtitle('Test Group'),
          contains('Test Group'),
        );
        expect(l10n.joinRequestPending, isNotEmpty);
        expect(l10n.joinRequestApproved, isNotEmpty);
        expect(l10n.joinRequestRejected, isNotEmpty);
        expect(l10n.joinRequestsTitle, isNotEmpty);
        expect(l10n.approveButton, isNotEmpty);
        expect(l10n.rejectButton, isNotEmpty);
        expect(l10n.noPendingRequests, isNotEmpty);
        expect(l10n.cancelRequestButton, isNotEmpty);
        expect(l10n.joinRequestCancelled, isNotEmpty);
        expect(l10n.pendingApprovalCardTitle, isNotEmpty);
        expect(l10n.pendingApprovalCardSubtitle, isNotEmpty);
        expect(l10n.invalidOrInactiveInvite, isNotEmpty);
        expect(l10n.alreadyMemberError, isNotEmpty);
        expect(l10n.requestAlreadyPendingError, isNotEmpty);
        expect(l10n.manageJoinRequestsTooltip, isNotEmpty);
        expect(l10n.pendingRequestsBadge(3), isNotEmpty);

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
      expect(l10n.joinRequestsTitle, equals('Katılım İstekleri'));
      expect(l10n.approveButton, equals('Onayla'));
      expect(l10n.rejectButton, equals('Reddet'));
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
      expect(l10n.joinRequestsTitle, equals('Solicitudes de unión'));
      expect(l10n.approveButton, equals('Aprobar'));
      expect(l10n.rejectButton, equals('Rechazar'));
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
      expect(l10n.joinRequestsTitle, equals('Demandes d\'adhésion'));
      expect(l10n.approveButton, equals('Approuver'));
      expect(l10n.rejectButton, equals('Rejeter'));
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
      expect(l10n.joinRequestsTitle, equals('Richieste di adesione'));
      expect(l10n.approveButton, equals('Approva'));
      expect(l10n.rejectButton, equals('Rifiuta'));
    });

    test(
      'All 5 ARB files have exact 100% key parity across EN, TR, ES, FR, IT',
      () {
        final arbFiles = [
          'app_en.arb',
          'app_tr.arb',
          'app_es.arb',
          'app_fr.arb',
          'app_it.arb',
        ];
        final keySets = <String, Set<String>>{};

        for (final fileName in arbFiles) {
          final file = File('lib/l10n/$fileName');
          expect(file.existsSync(), isTrue, reason: '$fileName must exist');
          final jsonMap =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          final contentKeys = jsonMap.keys
              .where((k) => !k.startsWith('@'))
              .toSet();
          keySets[fileName] = contentKeys;
        }

        final enKeys = keySets['app_en.arb']!;
        expect(enKeys.length, equals(128), reason: 'Expected 128 content keys');

        for (final entry in keySets.entries) {
          if (entry.key == 'app_en.arb') continue;
          final diffMissing = enKeys.difference(entry.value);
          final diffExtra = entry.value.difference(enKeys);

          expect(
            diffMissing,
            isEmpty,
            reason: '${entry.key} is missing keys: $diffMissing',
          );
          expect(
            diffExtra,
            isEmpty,
            reason: '${entry.key} has unexpected extra keys: $diffExtra',
          );
        }
      },
    );
  });
}
