import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';

/// Шапка отправления: метка (Курьер/Газель/Точка/Склад) · «Доставка 1 из 2» · когда · машина, вес · стоимость.
class ShipmentHead extends StatelessWidget {
  const ShipmentHead({super.key, required this.tag, required this.cargo, this.label, required this.when, required this.meta, this.feeText, this.compact = true});
  /// compact (корзина, оформление 390) — «когда» 16, иначе 18.
  final bool compact;
  final String tag, when, meta;
  final String? label, feeText;
  final bool cargo;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(height: 22, padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.center,
            decoration: BoxDecoration(color: cargo ? c.ink1 : c.primary50, borderRadius: BorderRadius.circular(MartRadius.pill)),
            child: Text(tag, style: MartText.caption.copyWith(fontWeight: FontWeight.w600, color: cargo ? c.surface : c.primaryPressed))),
          if (label != null) ...[const SizedBox(width: 8), Flexible(child: Text(label!, style: MartText.caption.copyWith(fontSize: 13, color: c.ink2)))],
        ]),
        const SizedBox(height: 4),
        Text(when, style: TextStyle(fontFamily: 'Onest', fontSize: compact ? 16 : 18, fontWeight: FontWeight.w700, letterSpacing: -0.16, height: 1.3, color: c.ink1)),
        const SizedBox(height: 4),
        Text(meta, style: TextStyle(fontFamily: 'Onest', fontSize: 13, height: 1.4, color: c.ink2)),
      ])),
      if (feeText != null) Padding(padding: const EdgeInsets.only(top: 2, left: 12),
        child: Text(feeText!, style: MartText.bodyStrong.copyWith(fontSize: 15, color: feeText == 'Бесплатно' || feeText == 'Тегін' ? c.success : c.ink1))),
    ]);
  }
}
