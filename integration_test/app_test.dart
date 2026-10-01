import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:denk/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Performance Profiling', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Start timeline tracing
    await binding.traceAction(() async {
      await Future.delayed(const Duration(seconds: 2));
      
      final settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 1));
      }
      
    }, reportKey: 'app_performance_timeline');
  });
}
