import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/widgets/widgets.dart';

void main() {
  Widget buildTestable(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Design System Widgets', () {
    testWidgets('DenkLogo renders cleanly', (tester) async {
      await tester.pumpWidget(buildTestable(const DenkLogo(size: 64)));
      expect(find.byType(DenkLogo), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DenkLogo),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('DenkButton executes onTap and displays loading state', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestable(
          DenkButton(label: 'Submit', onPressed: () => tapped = true),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.text('Submit'));
      expect(tapped, isTrue);

      // Loading state test
      await tester.pumpWidget(
        buildTestable(
          DenkButton(label: 'Submit', isLoading: true, onPressed: () {}),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets(
      'DenkBalancePill renders positive, negative, and zero balances correctly',
      (tester) async {
        final currency = Currency.tryCurrency;

        // Positive balance
        await tester.pumpWidget(
          buildTestable(
            DenkBalancePill(balanceMinor: 80000, currency: currency),
          ),
        );
        expect(find.text('+₺800.00'), findsOneWidget);

        // Negative balance
        await tester.pumpWidget(
          buildTestable(
            DenkBalancePill(balanceMinor: -40000, currency: currency),
          ),
        );
        expect(find.text('-₺400.00'), findsOneWidget);

        // Zero balance
        await tester.pumpWidget(
          buildTestable(DenkBalancePill(balanceMinor: 0, currency: currency)),
        );
        expect(find.text('₺0.00'), findsOneWidget);
      },
    );

    testWidgets('DenkEmptyState renders and triggers action', (tester) async {
      bool actionTriggered = false;
      await tester.pumpWidget(
        buildTestable(
          DenkEmptyState(
            icon: Icons.group_add_outlined,
            title: 'No groups yet',
            subtitle: 'Create a group to start sharing expenses.',
            actionLabel: 'Create Group',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No groups yet'), findsOneWidget);
      expect(
        find.text('Create a group to start sharing expenses.'),
        findsOneWidget,
      );
      expect(find.text('Create Group'), findsOneWidget);

      await tester.tap(find.text('Create Group'));
      expect(actionTriggered, isTrue);
    });
  });
}
