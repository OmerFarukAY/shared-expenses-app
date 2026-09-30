import 'package:flutter/material.dart';

/// Clean card container with a subtle hairline border and soft background.
///
/// Avoids heavy artificial drop shadows in favor of modern, calm border surfaces.
class DenkCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const DenkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
  });

  @override
  State<DenkCard> createState() => _DenkCardState();
}

class _DenkCardState extends State<DenkCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final cardColor = widget.backgroundColor ??
        theme.cardTheme.color ??
        theme.colorScheme.surface;
    final strokeColor = widget.borderColor ?? theme.colorScheme.outline;

    final decoration = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      border: Border.all(color: strokeColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );

    Widget result;
    if (widget.onTap != null) {
      result = AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (isHighlighted) {
              setState(() => _isPressed = isHighlighted);
            },
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Ink(
              decoration: decoration,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      );
    } else {
      result = Container(
        decoration: decoration,
        padding: widget.padding,
        child: widget.child,
      );
    }

    if (widget.margin != null) {
      return Padding(padding: widget.margin!, child: result);
    }
    return result;
  }
}
