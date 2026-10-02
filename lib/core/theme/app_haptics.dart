import 'package:flutter/services.dart';

/// Centralized utility for subtle, platform-appropriate haptic feedback.
///
/// Haptic feedback is kept restrained and applied only to meaningful interaction
/// points (successful creations, settlement confirmations, chip selections,
/// and destructive actions). It automatically respects system accessibility
/// and vibration settings on iOS and Android.
abstract final class AppHaptics {
  /// Subtle feedback for chip / segmented control selections.
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Gracefully ignore on unsupported platforms or environments
    }
  }

  /// Subtle feedback for toggle buttons or minor state confirmations.
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Gracefully ignore on unsupported platforms or environments
    }
  }

  /// Feedback for positive primary actions: expense created, settlement completed, group created.
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Gracefully ignore on unsupported platforms or environments
    }
  }

  /// Distinct feedback for destructive confirmations: expense deletion, group deletion, member removal.
  static Future<void> heavy() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Gracefully ignore on unsupported platforms or environments
    }
  }
}
