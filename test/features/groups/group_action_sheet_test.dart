import 'package:denk/core/theme/app_theme.dart';
import 'package:denk/features/groups/presentation/group_action_sheet.dart';
import 'package:denk/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestable({Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => GroupActionSheet.show(context),
              child: const Text('Open Sheet'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('GroupActionSheet renders create and join options', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupActionSheet), findsOneWidget);
    expect(find.text('Group Actions'), findsOneWidget);
    expect(find.text('Create Group'), findsOneWidget);
    expect(find.text('Join Group'), findsOneWidget);
  });

  testWidgets('GroupActionSheet displays Turkish localizations properly', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestable(locale: const Locale('tr')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.byType(GroupActionSheet), findsOneWidget);
    expect(find.text('Grup İşlemleri'), findsOneWidget);
    expect(find.text('Grup Oluştur'), findsOneWidget);
    expect(find.text('Gruba Katıl'), findsOneWidget);
  });
}
