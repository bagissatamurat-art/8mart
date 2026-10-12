import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';

/// Баннер главной (01 Главная, mobile 358×140, r20): картинка на всю площадь (букет справа), слева заголовок и подпись.
/// Картинка светлая в обеих темах — текст всегда тёмный (MartColors.light.ink1), как фото товаров всегда на белом.
class MartBanner extends StatelessWidget {
  const MartBanner({super.key, required this.image, required this.title, required this.text, this.onTap});
  final String image, title, text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ink = MartColors.light;
    return Semantics(
      button: onTap != null, label: '$title. $text',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(MartRadius.card),
          child: SizedBox(height: 140, child: Stack(fit: StackFit.expand, children: [
            ColoredBox(color: ink.primary100, child: Image.asset(image, package: MartAssets.package, fit: BoxFit.cover, alignment: const Alignment(.56, 0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: MartSpace.s16),
              child: ExcludeSemantics(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(title, style: MartText.h3.copyWith(fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.18, color: ink.ink1))),
                const SizedBox(height: 6),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(text, style: MartText.small.copyWith(fontSize: 13, height: 1.35, color: ink.ink1))),
              ])),
            ),
          ])),
        ),
      ),
    );
  }
}
