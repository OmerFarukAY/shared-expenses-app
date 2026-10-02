import 'package:flutter/material.dart';
import 'package:denk/core/theme/app_colors.dart';

/// Clean geometric vector logo for Denk.
///
/// Concept: "The Offset Balance"
/// Features two horizontal axes, each containing a dot (representing a person)
/// and a line (representing the shared expense). The 180-degree rotational
/// symmetry communicates equality, balance, and the name "Denk" (Equal),
/// while the separation of elements signifies splitting and sharing.
class DenkLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showBackground;

  const DenkLogo({
    super.key,
    this.size = 48,
    this.color,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!showBackground) {
      if (isDark) {
        return Image.asset(
          'assets/branding/logo_no_bg.png',
          width: size,
          fit: BoxFit.contain,
          color: Colors.white,
        );
      }
      return Image.asset(
        'assets/branding/logo_no_bg.png',
        width: size,
        fit: BoxFit.contain,
      );
    }

    if (isDark) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceSubtle,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: AppColors.darkBorder, width: 1.5),
        ),
        child: Center(
          child: Image.asset(
            'assets/branding/logo_no_bg.png',
            width: size * 0.6,
            fit: BoxFit.contain,
            color: Colors.white,
          ),
        ),
      );
    }

    final bgColor = AppColors.primary50;
    final borderColor = AppColors.primary100;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(
        child: Image.asset(
          'assets/branding/logo_no_bg.png',
          width: size * 0.6,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
