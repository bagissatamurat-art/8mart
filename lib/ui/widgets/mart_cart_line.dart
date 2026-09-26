import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';
import '../../core/format.dart';
import '../../domain/models.dart';
import 'mart_icons.dart';
import 'mart_image.dart';
import 'mart_stepper.dart';

/// Строка корзины (MartCartLine.dc.html). compact — фото 64, отступ 8, зазор 12; полная — 80 / 12 / 16.
/// Название 15/1.3 (2 строки) · «фасовка · цена за шт» 13 · бонусы текстом с монеткой · справа сумма 16/700 (+старая) и серый степпер 36.
/// Раскупленный: серый фон, «Раскупили» на фото, «Удалить из корзины», справа «не учитывается» и ×.
class MartCartLine extends StatelessWidget {
  const MartCartLine({super.key, required this.line, required this.onQty, required this.soldOutLabel, required this.notCountedLabel, required this.notInStockLabel,
      required this.removeLabel, required this.perPieceLabel, required this.bonusText, this.compact = true});
  final CartLine line;
  final ValueChanged<int> onQty;
  final String soldOutLabel, notCountedLabel, notInStockLabel, removeLabel, perPieceLabel;
  final String Function(int n) bonusText;
  final bool compact;

  static const _f = 'Onest';

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final p = line.product;
    final so = line.soldOut;
    final img = compact ? 64.0 : 80.0;
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(color: so ? c.surface2 : c.surface, borderRadius: BorderRadius.circular(MartRadius.field)),
      child: Row(children: [
        SizedBox.square(dimension: img, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Stack(children: [
          Positioned.fill(child: Opacity(opacity: so ? .45 : 1, child: MartImage(p.image, radius: 0, fit: BoxFit.cover))),
          if (so) Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFF17151A), borderRadius: BorderRadius.circular(999)),
            child: Text(soldOutLabel, style: const TextStyle(fontFamily: _f, fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)))),
        ]))),
        SizedBox(width: compact ? 12 : 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: _f, fontSize: 15, height: 1.3, color: so ? c.ink3 : c.ink1)),
          const SizedBox(height: 4),
          Text(so ? notInStockLabel : '${p.pack} · ${money(p.price ?? 0)} $perPieceLabel', style: TextStyle(fontFamily: _f, fontSize: 13, color: c.ink3)),
          if (!so && p.bonus > 0) ...[
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, alignment: Alignment.center, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                child: const Text('Б', style: TextStyle(fontFamily: _f, fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, height: 1))),
              const SizedBox(width: 5),
              Text(bonusText(p.bonus * line.qty), style: TextStyle(fontFamily: _f, fontSize: 12, fontWeight: FontWeight.w600, color: c.successText)),
            ]),
          ],
          if (so) ...[
            const SizedBox(height: 4),
            GestureDetector(onTap: () => onQty(0), child: Text(removeLabel, style: TextStyle(fontFamily: _f, fontSize: 14, fontWeight: FontWeight.w600, color: c.primary))),
          ],
        ])),
        SizedBox(width: compact ? 12 : 16),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: so
            ? [
                Text(notCountedLabel, style: TextStyle(fontFamily: _f, fontSize: 13, color: c.ink3)),
                Semantics(button: true, label: 'Удалить', child: GestureDetector(
                  behavior: HitTestBehavior.opaque, onTap: () => onQty(0),
                  child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle), child: Center(child: MartCross(size: 11, color: c.ink2))))),
                )),
              ]
            : [
                Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text(money(line.sum), style: TextStyle(fontFamily: _f, fontSize: 16, fontWeight: FontWeight.w700, color: c.ink1)),
                  if (p.oldPrice != null) ...[const SizedBox(width: 6), Text(money(p.oldPrice! * line.qty),
                      style: TextStyle(fontFamily: _f, fontSize: 13, color: c.ink3, decoration: TextDecoration.lineThrough, decorationColor: c.ink3))],
                ]),
                const SizedBox(height: 4),
                MartStepper(qty: line.qty, onChanged: onQty, width: 104, size: 36),
              ]),
      ]),
    );
  }
}
