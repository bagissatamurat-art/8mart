import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';

/// Скелетон загрузки: мягкая пульсация surface2 ↔ surface3.
class MartSkeleton extends StatefulWidget {
  const MartSkeleton({super.key, this.width, this.height = 16, this.radius = MartRadius.badge});
  final double? width;
  final double height, radius;
  @override
  State<MartSkeleton> createState() => _MartSkeletonState();
}

class _MartSkeletonState extends State<MartSkeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    return AnimatedBuilder(animation: _c, builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(color: Color.lerp(mc.surface2, mc.surface3, _c.value), borderRadius: BorderRadius.circular(widget.radius)),
    ));
  }
}

class MartSkeletonCard extends StatelessWidget {
  const MartSkeletonCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: context.mc.surface, borderRadius: BorderRadius.circular(MartRadius.field)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(aspectRatio: 1, child: MartSkeleton(radius: MartRadius.photo)),
          SizedBox(height: 10), MartSkeleton(height: 12), SizedBox(height: 6), MartSkeleton(width: 90, height: 12),
          SizedBox(height: 10), MartSkeleton(width: 70, height: 16), Spacer(), MartSkeleton(height: 40, radius: MartRadius.pill),
        ]),
      );
}

class MartSkeletonRow extends StatelessWidget {
  const MartSkeletonRow({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.mc.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
        child: const Row(children: [
          MartSkeleton(width: 48, height: 48, radius: MartRadius.photo), SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [MartSkeleton(width: 160), SizedBox(height: 8), MartSkeleton(width: 100, height: 12)])),
        ]),
      );
}
