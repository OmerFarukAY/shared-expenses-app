import 'package:flutter/material.dart';

/// Design tokens for Denk's refined, calm, trustworthy color palette.
///
/// Designed to avoid generic SaaS purple gradients or artificial fluorescent glows.
/// Uses tailored slate, sage, teal, emerald, and terracotta tones with high contrast.
abstract class AppColors {
  // Brand Primary (Pine / Slate Teal)
  static const Color primary50 = Color(0xFFF0FDFA);
  static const Color primary100 = Color(0xFFCCFBF1);
  static const Color primary500 = Color(0xFF14B8A6);
  static const Color primary600 = Color(0xFF0D9488);
  static const Color primary700 = Color(0xFF0F766E);
  static const Color primary800 = Color(0xFF115E59);
  static const Color primary900 = Color(0xFF134E4A);

  // Financial Status - Positive (You are owed / Credit)
  static const Color positive = Color(0xFF16A34A); // Emerald 600
  static const Color positiveLight = Color(0xFFDCFCE7); // Emerald 100
  static const Color positiveDark = Color(0xFF052E16); // Emerald 950
  static const Color positiveBright = Color(0xFF22C55E); // Emerald 500

  // Financial Status - Negative (You owe / Debt)
  static const Color negative = Color(0xFFDC2626); // Crimson 600
  static const Color negativeLight = Color(0xFFFEE2E2); // Crimson 100
  static const Color negativeDark = Color(0xFF450A0A); // Crimson 950
  static const Color negativeBright = Color(0xFFF87171); // Crimson 400

  // Financial Status - Settled / Neutral
  static const Color settled = Color(0xFF64748B); // Slate 500
  static const Color settledLight = Color(0xFFF1F5F9); // Slate 100
  static const Color settledDark = Color(0xFF1E293B); // Slate 800

  // Neutrals - Light Theme
  static const Color lightBg = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextTertiary = Color(0xFF94A3B8); // Slate 400

  // Neutrals - Dark Theme
  static const Color darkBg = Color(0xFF0B0F17); // Obsidian slate
  static const Color darkSurface = Color(0xFF111827); // Gray 900
  static const Color darkSurfaceSubtle = Color(0xFF1A2234);
  static const Color darkBorder = Color(0xFF1F2937); // Gray 800
  static const Color darkBorderSubtle = Color(0xFF18202F);
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextTertiary = Color(0xFF64748B); // Slate 500

  // Expense Category Color Accents (Muted & Harmonious)
  static const Color categoryFood = Color(0xFFEA580C); // Warm amber orange
  static const Color categoryGroceries = Color(0xFF16A34A); // Leaf green
  static const Color categoryTransport = Color(0xFF0284C7); // Sky blue
  static const Color categoryHome = Color(0xFF8B5CF6); // Soft indigo
  static const Color categoryEntertainment = Color(0xFFD946EF); // Fuchsia berry
  static const Color categoryTravel = Color(0xFF0D9488); // Teal
  static const Color categoryBills = Color(0xFFCA8A04); // Honey amber
  static const Color categoryShopping = Color(0xFFE11D48); // Rose
  static const Color categoryOther = Color(0xFF64748B); // Slate
}
