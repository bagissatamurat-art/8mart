import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';
import '../../core/format.dart';
import '../../domain/models.dart';
import 'bonus_badge.dart';
import 'mart_image.dart';
import 'mart_stepper.dart';

/// Карточка товара как в MartProductCard.dc.html:
/// фото 1:1 (скидка слева сверху, метка слева снизу, сердце справа) → цена + старая → название 2 строки → фасовка · бонусы → CTA 36.
class MartProductCard extends StatelessWidget {
  /// Высота карточки в сетке при ширине колонки w: фото (w−16) + текст и CTA — 136.
  static double extentFor(double w) => w + 146;
  const MartProductCard({super.key, required this.product, this.qty = 0, required this.onQty, this.favorite = false, this.onFavorite, this.onTap, required this.addLabel, this.soldOut = false});
  final Product product;
  final int qty;
  final ValueChanged<int> onQty;
  final bool favorite, soldOut;
  final VoidCallback? onFavorite, onTap;
  final String addLabel;

  static const _f = 'Onest';

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final p = product;
    final hasDiscount = !soldOut && p.oldPrice != null && p.price != null;
    final ink = soldOut ? c.ink3 : c.ink1;
    Widget pill(String text, Color bg, Color fg, FontWeight fw) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
          child: Text(text, style: TextStyle(fontFamily: _f, fontSize: 12, height: 1.2, fontWeight: fw, color: fg)));
    Widget flat(String text, {Color? fg, VoidCallback? onTap}) => GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: onTap,
          child: Container(
            height: MartHeight.buttonS, alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
            child: Text(text, style: TextStyle(fontFamily: _f, fontSize: 14, fontWeight: FontWeight.w600, color: fg ?? c.ink1))));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Stack(children: [
            Positioned.fill(child: Opacity(opacity: soldOut ? .45 : 1, child: MartImage(p.image))),
            if (hasDiscount) Positioned(left: 8, top: 8, child: pill('−${((1 - p.price! / p.oldPrice!) * 100).round()}%', c.primary, MartColors.onPrimary, FontWeight.w600)),
            if (p.badge != null && !soldOut) Positioned(left: 8, bottom: 8, child: pill(p.badge!, Colors.white, const Color(0xFF17151A), FontWeight.w500)),
            if (soldOut) Center(child: pill('Раскупили', const Color(0xFF17151A), Colors.white, FontWeight.w600)),
            Positioned(right: 0, top: 0, child: Semantics(
              button: true, label: favorite ? 'Убрать из избранного' : 'В избранное',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque, onTap: onFavorite,
                child: SizedBox.square(dimension: 48, child: Center(child: Container(
                  width: 36, height: 36, decoration: const BoxDecoration(color: Color(0xEBFFFFFF), shape: BoxShape.circle),
                  child: Icon(favorite ? Icons.favorite : Icons.favorite_border, size: 20, color: favorite ? MartColors.favorite : MartColors.favoriteOutline)))),
              ),
            )),
          ]))),
          const SizedBox(height: 10),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(p.price == null ? 'Цена уточняется' : '${p.hasVariants ? 'от ' : ''}${money(p.price!)}', style: TextStyle(fontFamily: _f, fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
              if (hasDiscount) ...[const SizedBox(width: 6), Flexible(child: Text(money(p.oldPrice!), overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _f, fontSize: 13, color: c.ink3, decoration: TextDecoration.lineThrough, decorationColor: c.ink3)))],
            ]),
            const SizedBox(height: 2),
            SizedBox(height: 38, child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _f, fontSize: 14, height: 1.3, color: ink))),
            const SizedBox(height: 2),
            SizedBox(height: 20, child: Row(children: [
              Expanded(child: Text(p.pack, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _f, fontSize: 12, color: c.ink3))),
              if (p.bonus > 0 && !soldOut) BonusBadge(amount: p.bonus, compact: true),
            ])),
          ])),
          const Spacer(),
          const SizedBox(height: 10),
          if (soldOut)
            flat('Нет в наличии', fg: c.ink3)
          else if (p.price == null)
            flat('Цена не задана', fg: c.ink3)
          else if (p.hasVariants)
            flat('Выбрать размер', onTap: onTap)
          else if (qty == 0)
            flat(addLabel, onTap: () => onQty(1))
          else
            SizedBox(height: 36, child: OverflowBox(maxHeight: MartHeight.hit, child: MartStepper(qty: qty, onChanged: onQty, width: double.infinity, size: 36, tone: MartStepperTone.primary))),
        ]),
      ),
    );
  }
}
