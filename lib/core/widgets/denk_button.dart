import 'package:flutter/material.dart';
import 'package:denk/core/theme/app_colors.dart';

enum DenkButtonVariant { primary, secondary, destructive, text }

class DenkButton extends StatefulWidget {
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
  State<DenkButton> createState() => _DenkButtonState();
}

class _DenkButtonState extends State<DenkButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
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

    final Widget content = widget.isLoading
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
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          );

    final bool isDisabled = widget.isLoading || widget.onPressed == null;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Material(
          color: isDisabled ? bgColor.withValues(alpha: 0.5) : bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderSide,
          ),
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            button: true,
            enabled: !isDisabled,
            label: widget.label,
            excludeSemantics: true,
            child: InkWell(
              onHighlightChanged: (isHighlighted) {
                if (!isDisabled) {
                  setState(() => _isPressed = isHighlighted);
                }
              },
              onTap: isDisabled ? null : widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
