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
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    final logoMark = CustomPaint(
      size: Size(size * 0.6, size * 0.6),
      painter: _DenkLogoPainter(color: effectiveColor),
    );

    if (!showBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: logoMark),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.primary900.withValues(alpha: 0.3)
        : AppColors.primary50;
    final borderColor = isDark
        ? AppColors.primary700.withValues(alpha: 0.4)
        : AppColors.primary100;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(child: logoMark),
    );
  }
}

class _DenkLogoPainter extends CustomPainter {
  final Color color;

  _DenkLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // We scale the drawing to a 100x100 virtual coordinate system
    // and then apply the actual size.
    final scale = size.width / 100.0;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 24 * scale;

    // Top Row (Y = 32)
    // Dot at (22, 32)
    canvas.drawCircle(
      Offset(22 * scale, 32 * scale),
      12 * scale,
      paint,
    );
    // Line from (54, 32) to (78, 32)
    canvas.drawLine(
      Offset(54 * scale, 32 * scale),
      Offset(78 * scale, 32 * scale),
      strokePaint,
    );

    // Bottom Row (Y = 68)
    // Line from (22, 68) to (46, 68)
    canvas.drawLine(
      Offset(22 * scale, 68 * scale),
      Offset(46 * scale, 68 * scale),
      strokePaint,
    );
    // Dot at (78, 68)
    canvas.drawCircle(
      Offset(78 * scale, 68 * scale),
      12 * scale,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DenkLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
