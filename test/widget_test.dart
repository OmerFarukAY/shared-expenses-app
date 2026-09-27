import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:denk/app.dart';

void main() {
  testWidgets('DenkApp renders brand title and tagline smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DenkApp()));
    await tester.pumpAndSettle();

    expect(find.text('Denk'), findsOneWidget);
    expect(find.text('Shared expenses, settled simply'), findsOneWidget);
  });
}
