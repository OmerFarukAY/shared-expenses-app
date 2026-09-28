import 'dart:math';

/// Helper for generating and sanitizing human-friendly invite codes.
///
/// Uses an unambiguous alphabet without easily confused glyphs (0/O, 1/I/L).
abstract class InviteCodeGenerator {
  static const String _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static final Random _random = Random.secure();

  /// Generates a standardized, high-entropy invite code formatted as `DNK-XXXXXX`
  /// using 6 cryptographically secure characters (30^6 = 729,000,000 combinations).
  static String generate() {
    final buffer = StringBuffer('DNK-');
    for (int i = 0; i < 6; i++) {
      final index = _random.nextInt(_alphabet.length);
      buffer.write(_alphabet[index]);
    }
    return buffer.toString();
  }

  /// Sanitizes user input for code resolution (e.g. "dnk 7x2k9p", "7x2k9p", "DNK-7X2K9P" -> "DNK-7X2K9P").
  static String sanitize(String input) {
    String clean = input
        .trim()
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('-', '');
    if (clean.startsWith('DNK')) {
      clean = clean.substring(3);
    }
    if (clean.isNotEmpty) {
      return 'DNK-$clean';
    }
    return '';
  }

  /// Validates format of an invite code (supports high-entropy 6-char codes
  /// as well as legacy 4-char codes for full backward compatibility).
  static bool isValidFormat(String code) {
    final clean = sanitize(code);
    final regex = RegExp(r'^DNK-[23456789ABCDEFGHJKMNPQRSTUVWXYZ]{4,6}$');
    return regex.hasMatch(clean);
  }
}
