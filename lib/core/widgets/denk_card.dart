import 'package:flutter/material.dart';

/// Clean card container with a subtle hairline border and soft background.
///
/// Avoids heavy artificial drop shadows in favor of modern, calm border surfaces.
class DenkCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        backgroundColor ?? theme.cardTheme.color ?? theme.colorScheme.surface;
    final strokeColor = borderColor ?? theme.colorScheme.outline;

    final decoration = BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: strokeColor, width: 1),
    );

    Widget result;
    if (onTap != null) {
      result = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: decoration,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
    } else {
      result = Container(
        decoration: decoration,
        padding: padding,
        child: child,
      );
    }

    if (margin != null) {
      return Padding(padding: margin!, child: result);
    }
    return result;
  }
}
