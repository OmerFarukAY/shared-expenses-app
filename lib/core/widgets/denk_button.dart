import 'package:flutter/material.dart';
import 'package:denk/core/theme/app_colors.dart';

enum DenkButtonVariant { primary, secondary, destructive, text }

class DenkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DenkButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const DenkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DenkButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case DenkButtonVariant.primary:
        bgColor = isDark ? AppColors.primary500 : AppColors.primary700;
        fgColor = isDark ? const Color(0xFF042F2E) : Colors.white;
        break;
      case DenkButtonVariant.secondary:
        bgColor = isDark
            ? AppColors.darkSurfaceSubtle
            : AppColors.lightSurfaceSubtle;
        fgColor = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        borderSide = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        );
        break;
      case DenkButtonVariant.destructive:
        bgColor = isDark ? AppColors.negativeDark : AppColors.negativeLight;
        fgColor = isDark ? AppColors.negativeBright : AppColors.negative;
        borderSide = BorderSide(
          color: isDark
              ? AppColors.negative.withValues(alpha: 0.3)
              : AppColors.negative.withValues(alpha: 0.2),
          width: 1,
        );
        break;
      case DenkButtonVariant.text:
        bgColor = Colors.transparent;
        fgColor = isDark ? AppColors.primary500 : AppColors.primary700;
        break;
    }

    final Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: onPressed == null ? bgColor.withValues(alpha: 0.5) : bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderSide,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
