import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';

/// Фото товара: всегда на белой подложке (и в тёмной теме). http → кеш на диске (офлайн).
class MartImage extends StatelessWidget {
  const MartImage(this.src, {super.key, this.radius = 12, this.fit = BoxFit.contain});
  /// Скриншот-тесты: сетевые фото не грузим (в тестах нет файлового кеша) — серый плейсхолдер.
  static bool offline = false;
  final String src;
  final double radius;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final ph = ColoredBox(color: context.mc.surface2);
    final img = src.isEmpty
        ? ph
        : src.startsWith('http') && offline
            ? ph
            : src.startsWith('http')
            ? CachedNetworkImage(imageUrl: src, fit: fit, placeholder: (_, __) => ph, errorWidget: (_, __, ___) => ph)
            : Image.asset(src, package: MartAssets.package, fit: fit);
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: ColoredBox(color: MartColors.photoBg, child: SizedBox.expand(child: img)));
  }
}
