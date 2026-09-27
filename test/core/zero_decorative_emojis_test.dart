import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Non-Negotiable UI Rule: Zero Decorative Emojis', () {
    final emojiRegex = RegExp(
      r'[\u{1F300}-\u{1F9FF}\u{1FA00}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F1E6}-\u{1F1FF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}]',
      unicode: true,
    );

    test('lib/ source files must contain zero hardcoded decorative emojis', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File &&
            (entity.path.endsWith('.dart') || entity.path.endsWith('.arb'))) {
          final lines = entity.readAsLinesSync();
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (emojiRegex.hasMatch(line)) {
              violations.add('${entity.path}:${i + 1} -> "$line"');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Violations of non-negotiable rule "Zero decorative emojis in UI":\n'
            '${violations.join('\n')}\n'
            'Emojis must not be used as substitutes for icons, illustrations, badges, or copy.',
      );
    });

    test('All ARB localization files contain zero decorative emojis', () {
      final l10nDir = Directory('lib/l10n');
      expect(l10nDir.existsSync(), isTrue);

      final violations = <String>[];

      for (final entity in l10nDir.listSync()) {
        if (entity is File && entity.path.endsWith('.arb')) {
          final content = entity.readAsStringSync();
          final matches = emojiRegex.allMatches(content);
          if (matches.isNotEmpty) {
            violations.add(
              '${entity.path} has ${matches.length} emoji characters',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Localization strings must never contain decorative emojis.',
      );
    });
  });
}
