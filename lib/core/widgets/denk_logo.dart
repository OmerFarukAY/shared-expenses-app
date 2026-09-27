import 'package:flutter/material.dart';
import 'package:denk/core/theme/app_colors.dart';

/// Clean geometric vector logo for Denk.
///
/// Features two balanced horizontal beams in harmonious equilibrium,
/// communicating equality, clarity, and fairness.
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
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.16;

    // Top horizontal beam (representing equal share)
    final y1 = size.height * 0.28;
    canvas.drawLine(
      Offset(size.width * 0.15, y1),
      Offset(size.width * 0.85, y1),
      paint,
    );

    // Bottom horizontal beam (representing balance / settlement)
    final y2 = size.height * 0.72;
    canvas.drawLine(
      Offset(size.width * 0.15, y2),
      Offset(size.width * 0.85, y2),
      paint,
    );

    // Central equilibrium accent: vertical bridge
    final bridgePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.1,
      bridgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DenkLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
