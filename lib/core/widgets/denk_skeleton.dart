import 'package:flutter/material.dart';

/// Modern theme-adaptive skeleton loading placeholder for smooth page transitions.
///
/// Prevents harsh layout shift (CLS) and stale content flickers during
/// screen pushes, tab transitions, and async operations.
class DenkSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final ShapeBorder? shape;

  const DenkSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.margin,
    this.shape,
  });

  const DenkSkeleton.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = size / 2,
        shape = const CircleBorder();

  const DenkSkeleton.line({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
    this.margin,
  }) : shape = null;

  const DenkSkeleton.card({
    super.key,
    this.width = double.infinity,
    this.height = 84,
    this.borderRadius = 16,
    this.margin = const EdgeInsets.only(bottom: 12),
  }) : shape = null;

  @override
  State<DenkSkeleton> createState() => _DenkSkeletonState();
}

class _DenkSkeletonState extends State<DenkSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: ShapeDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            shape: widget.shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
          ),
        );
      },
    );
  }
}

/// Full-page dashboard skeleton matching the hero balance card and expense list.
class DenkDashboardSkeleton extends StatelessWidget {
  const DenkDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Currency Selector / Top Pill
        const Align(
          alignment: Alignment.centerLeft,
          child: DenkSkeleton.line(width: 80, height: 28, borderRadius: 14),
        ),
        const SizedBox(height: 12),

        // Hero Balance Card
        const DenkSkeleton.card(height: 150, borderRadius: 20),
        const SizedBox(height: 16),

        // Tab Bar Placeholder
        const Row(
          children: [
            Expanded(child: DenkSkeleton.line(height: 38, borderRadius: 10)),
            SizedBox(width: 8),
            Expanded(child: DenkSkeleton.line(height: 38, borderRadius: 10)),
            SizedBox(width: 8),
            Expanded(child: DenkSkeleton.line(height: 38, borderRadius: 10)),
          ],
        ),
        const SizedBox(height: 16),

        // Search Bar Placeholder
        const DenkSkeleton.line(height: 44, borderRadius: 10),
        const SizedBox(height: 16),

        // List item cards
        const DenkSkeleton.card(height: 76),
        const DenkSkeleton.card(height: 76),
        const DenkSkeleton.card(height: 76),
      ],
    );
  }
}

/// Full-page groups list skeleton matching the groups list screen cards.
class DenkGroupsListSkeleton extends StatelessWidget {
  const DenkGroupsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        DenkSkeleton.card(height: 92, borderRadius: 16),
        DenkSkeleton.card(height: 92, borderRadius: 16),
        DenkSkeleton.card(height: 92, borderRadius: 16),
      ],
    );
  }
}
