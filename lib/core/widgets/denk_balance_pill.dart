import 'package:flutter/material.dart';
import 'package:denk/core/constants/currencies.dart';
import 'package:denk/core/theme/app_colors.dart';
import 'package:denk/core/theme/app_typography.dart';

class DenkBalancePill extends StatelessWidget {
  final int balanceMinor;
  final Currency currency;
  final bool showLabel;
  final double fontSize;

  const DenkBalancePill({
    super.key,
    required this.balanceMinor,
    required this.currency,
    this.showLabel = false,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color fg;
    Color bg;
    String prefix;

    if (balanceMinor > 0) {
      fg = isDark ? AppColors.positiveBright : AppColors.positive;
      bg = isDark ? AppColors.positiveDark : AppColors.positiveLight;
      prefix = '+';
    } else if (balanceMinor < 0) {
      fg = isDark ? AppColors.negativeBright : AppColors.negative;
      bg = isDark ? AppColors.negativeDark : AppColors.negativeLight;
      prefix = '';
    } else {
      fg = isDark ? AppColors.settled : AppColors.settled;
      bg = isDark ? AppColors.settledDark : AppColors.settledLight;
      prefix = '';
    }

    final formatted = currency.formatMinor(balanceMinor);
    final displayText = balanceMinor > 0 ? '$prefix$formatted' : formatted;

    final semanticLabel = balanceMinor > 0
        ? 'Positive balance $displayText'
        : balanceMinor < 0
        ? 'Negative balance $displayText'
        : 'Settled balance $displayText';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayText,
          style: AppTypography.monetary(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
