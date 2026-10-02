import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:denk/core/theme/app_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('AppHaptics Tests', () {
    test('AppHaptics.selection triggers HapticFeedbackType.selectionClick', () async {
      await AppHaptics.selection();
      expect(log, isNotEmpty);
      expect(log.last.method, 'HapticFeedback.vibrate');
      expect(log.last.arguments, 'HapticFeedbackType.selectionClick');
    });

    test('AppHaptics.light triggers HapticFeedbackType.lightImpact', () async {
      await AppHaptics.light();
      expect(log, isNotEmpty);
      expect(log.last.method, 'HapticFeedback.vibrate');
      expect(log.last.arguments, 'HapticFeedbackType.lightImpact');
    });

    test('AppHaptics.medium triggers HapticFeedbackType.mediumImpact', () async {
      await AppHaptics.medium();
      expect(log, isNotEmpty);
      expect(log.last.method, 'HapticFeedback.vibrate');
      expect(log.last.arguments, 'HapticFeedbackType.mediumImpact');
    });

    test('AppHaptics.heavy triggers HapticFeedbackType.heavyImpact', () async {
      await AppHaptics.heavy();
      expect(log, isNotEmpty);
      expect(log.last.method, 'HapticFeedback.vibrate');
      expect(log.last.arguments, 'HapticFeedbackType.heavyImpact');
    });
  });
}
