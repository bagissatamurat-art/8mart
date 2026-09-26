import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';
import '../../domain/models.dart';
import '../widgets/mart_icons.dart';

/// Оплата (03 Оформление.dc.html, блок «Оплата»): Kaspi Pay / Картой онлайн — плитки 14, иконка 28 слева, радио справа.
/// Карта выбрана → серый блок «Сохранённые карты» (плитки 52, радиус 12) + под разделителем «Новой картой» с пунктиром и «+».
/// value: 'kaspi' | id сохранённой карты | 'new'.
class PaymentPicker extends StatelessWidget {
  const PaymentPicker({super.key, required this.value, required this.cards, required this.onChanged, required this.labels});
  final String value;
  final List<SavedCard> cards;
  final ValueChanged<String> onChanged;
  final PaymentLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final isCard = value != 'kaspi';
    final defId = cards.isEmpty ? 'new' : (cards.where((x) => x.isDefault).firstOrNull ?? cards.first).id;
    Widget cardIcon() => Container(width: 28, height: 20, decoration: BoxDecoration(border: Border.all(color: c.ink1, width: 2), borderRadius: BorderRadius.circular(4)),
        child: Align(alignment: const Alignment(0, -.35), child: Container(height: 3, color: c.ink1)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _PayTile(selected: value == 'kaspi', onTap: () => onChanged('kaspi'), title: 'Kaspi Pay', sub: labels.kaspiSub,
          icon: ClipRRect(borderRadius: BorderRadius.circular(6), child: SvgPicture.asset('assets/images/kaspi-logo.svg', package: MartAssets.package, width: 24, height: 24))),
      const SizedBox(height: 6),
      _PayTile(selected: isCard, onTap: () { if (!isCard) onChanged(defId); }, title: labels.cardOnline, sub: 'Visa, Mastercard', icon: cardIcon()),
      if (isCard && cards.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(padding: const EdgeInsets.fromLTRB(2, 0, 2, 2), child: Text(labels.savedCards, style: TextStyle(fontFamily: 'Onest', fontSize: 12, fontWeight: FontWeight.w600, color: c.ink2))),
            for (final k in cards) ...[
              const SizedBox(height: 6),
              _PayTile(small: true, selected: value == k.id, onTap: () => onChanged(k.id), title: k.title, sub: 'до ${k.exp}', icon: cardIcon()),
            ],
            Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 10), color: c.border),
            _PayTile(small: true, dashed: true, selected: value == 'new', onTap: () => onChanged('new'), title: labels.newCard, sub: labels.newCardSub,
                icon: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: c.border, width: 1.5)),
                    child: Center(child: MartPlusMinus(plus: true, color: const Color(0xFF17151A))))),
          ]),
        ),
      ],
    ]);
  }
}

class _PayTile extends StatelessWidget {
  const _PayTile({required this.selected, required this.onTap, required this.title, required this.sub, required this.icon, this.small = false, this.dashed = false});
  final bool selected, small, dashed;
  final VoidCallback onTap;
  final String title, sub;
  final Widget icon;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final r = small ? 12.0 : 14.0;
    final bc = selected ? c.primary : (dashed ? const Color(0xFFC9C7CF) : c.border);
    final tile = AnimatedContainer(
      duration: MartMotion.press,
      constraints: BoxConstraints(minHeight: small ? 52 : 0),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: small ? 8 : 10),
      decoration: BoxDecoration(
        color: selected ? c.primary50 : (dashed ? Colors.transparent : c.surface),
        borderRadius: BorderRadius.circular(r),
        border: dashed && !selected ? null : Border.all(color: bc, width: 1.5),
      ),
      child: Row(children: [
        SizedBox(width: 28, height: small && dashed ? 28 : 24, child: Center(child: icon)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: TextStyle(fontFamily: 'Onest', fontSize: 15, fontWeight: FontWeight.w600, color: c.ink1)),
          const SizedBox(height: 1),
          Text(sub, style: TextStyle(fontFamily: 'Onest', fontSize: 12, color: c.ink2)),
        ])),
        const SizedBox(width: 12),
        Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? c.primary : (dashed ? c.border : bc), width: 2)),
            child: Center(child: AnimatedContainer(duration: MartMotion.press, width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? c.primary : Colors.transparent)))),
      ]),
    );
    return Semantics(button: true, selected: selected, label: title, child: GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: onTap,
      child: dashed && !selected ? CustomPaint(foregroundPainter: _Dashed(bc, r), child: tile) : tile,
    ));
  }
}

class _Dashed extends CustomPainter {
  _Dashed(this.color, this.r);
  final Color color;
  final double r;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r)).deflate(.75));
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) { canvas.drawPath(m.extractPath(d, d + 5), p); }
    }
  }
  @override
  bool shouldRepaint(_Dashed o) => o.color != color;
}

class PaymentLabels {
  const PaymentLabels({required this.kaspiSub, required this.cardOnline, required this.savedCards, required this.newCard, required this.newCardSub});
  final String kaspiSub, cardOnline, savedCards, newCard, newCardSub;
}
