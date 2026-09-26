import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';

class SplitOption {
  const SplitOption({required this.together, required this.title, required this.sub, required this.feeText});
  final bool together;
  final String title, sub, feeText;
}

/// Выбор «Двумя доставками» / «Всё вместе завтра». Показывается, только если в корзине есть курьерские и тяжёлые товары.
class SplitChoice extends StatelessWidget {
  const SplitChoice({super.key, required this.title, required this.sub, required this.options, required this.together, required this.onChanged});
  final String title, sub;
  final List<SplitOption> options;
  final bool together;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontFamily: 'Onest', fontSize: 16, fontWeight: FontWeight.w700, color: c.ink1)),
      const SizedBox(height: 4),
      Text(sub, style: TextStyle(fontFamily: 'Onest', fontSize: 13, height: 1.4, color: c.ink2)),
      const SizedBox(height: 12),
      for (var i = 0; i < options.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        MartRadioTile(selected: options[i].together == together, onTap: () => onChanged(options[i].together), title: options[i].title, sub: options[i].sub, trailing: options[i].feeText),
      ],
    ]);
  }
}

/// Плитка-радио (оплата, отправления, сохранённые карты). dashed — «Новой картой».
class MartRadioTile extends StatelessWidget {
  const MartRadioTile({super.key, required this.selected, required this.onTap, required this.title, this.sub, this.trailing, this.leading, this.dashed = false});
  final bool selected, dashed;
  final VoidCallback onTap;
  final String title;
  final String? sub, trailing;
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final bc = selected ? c.primary : c.border;
    return Semantics(
      button: true, selected: selected, label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap,
        child: CustomPaint(
          foregroundPainter: dashed && !selected ? _DashedRRect(c.ink3) : null,
          child: AnimatedContainer(
            duration: MartMotion.press,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? c.primary50 : (dashed ? Colors.transparent : c.surface),
              borderRadius: BorderRadius.circular(MartRadius.field),
              border: dashed && !selected ? null : Border.all(color: bc, width: 1.5),
            ),
            // Как в MartSplitChoice.dc.html: радио слева (20, рамка 2), затем иконка, текст; стоимость справа в строке заголовка.
            child: Row(crossAxisAlignment: sub == null ? CrossAxisAlignment.center : CrossAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.only(top: sub == null ? 0 : 1), child: Container(width: 20, height: 20,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? c.primary : const Color(0xFFC9C7CF), width: 2)),
                child: Center(child: AnimatedContainer(duration: MartMotion.press, width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? c.primary : Colors.transparent))))),
              const SizedBox(width: 12),
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Expanded(child: Text(title, style: TextStyle(fontFamily: 'Onest', fontSize: 15, fontWeight: FontWeight.w600, color: c.ink1))),
                  if (trailing != null) ...[const SizedBox(width: 8), Text(trailing!, style: TextStyle(fontFamily: 'Onest', fontSize: 14, fontWeight: FontWeight.w600, color: trailing == 'Бесплатно' || trailing == 'Тегін' ? c.success : c.ink1))],
                ]),
                if (sub != null) ...[const SizedBox(height: 3), Text(sub!, style: TextStyle(fontFamily: 'Onest', fontSize: 13, height: 1.4, color: c.ink2))],
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  _DashedRRect(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(MartRadius.field)).deflate(.75);
    final path = Path()..addRRect(rr);
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) { canvas.drawPath(m.extractPath(d, d + 5), p); }
    }
  }
  @override
  bool shouldRepaint(_DashedRRect o) => o.color != color;
}
