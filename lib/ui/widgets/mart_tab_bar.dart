import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';

enum MartTabGlyph { home, catalog, cart, profile }

class MartTabItem {
  const MartTabItem(this.label, this.glyph);
  final String label;
  final MartTabGlyph glyph;
}

/// Таб-бар как в MartTabBar.dc.html: иконки-контуры 22 (линия 2.5), подпись 11/600, активный — primary, остальные — ink3.
/// Высота 64 + safe area снизу. Счётчик корзины — розовый бейдж справа от иконки.
class MartTabBar extends StatelessWidget {
  const MartTabBar({super.key, required this.items, required this.index, required this.onTap, this.cartIndex = 2, this.cartCount = 0});
  final List<MartTabItem> items;
  final int index, cartIndex, cartCount;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.divider))),
      child: SafeArea(top: false, child: SizedBox(height: MartHeight.tabBar, child: Row(children: [
        for (var i = 0; i < items.length; i++)
          Expanded(child: Semantics(
            selected: i == index, button: true, label: items[i].label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: () => onTap(i),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Stack(clipBehavior: Clip.none, children: [
                  CustomPaint(size: const Size.square(22), painter: _GlyphPainter(items[i].glyph, i == index ? c.primary : c.ink3)),
                  if (i == cartIndex && cartCount > 0) Positioned(left: 17, top: -8, child: Container(
                    constraints: const BoxConstraints(minWidth: 18), height: 18, padding: const EdgeInsets.symmetric(horizontal: 5), alignment: Alignment.center,
                    decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(999)),
                    child: Text('$cartCount', style: const TextStyle(fontFamily: 'Onest', fontSize: 11, fontWeight: FontWeight.w700, color: MartColors.onPrimary, height: 1)))),
                ]),
                const SizedBox(height: 4),
                Text(items[i].label, style: TextStyle(fontFamily: 'Onest', fontSize: 11, fontWeight: FontWeight.w600, height: 1.2, color: i == index ? c.primary : c.ink3)),
              ]),
            ),
          )),
      ]))),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);
  final MartTabGlyph glyph;
  final Color color;
  static const w = 2.5, h = w / 2;

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = w;
    final fill = Paint()..color = color;
    RRect box(double l, double t, double wd, double ht, double tr, double br) => RRect.fromLTRBAndCorners(
        l + h, t + h, l + wd - h, t + ht - h,
        topLeft: Radius.circular(tr), topRight: Radius.circular(tr), bottomLeft: Radius.circular(br), bottomRight: Radius.circular(br));
    switch (glyph) {
      case MartTabGlyph.home:
        // Коробка 22 (линия 2.5, радиусы 7/7/4/4) + дверь 5×8 по центру у нижней линии (MartTabBar.dc.html).
        canvas.drawRRect(box(0, 0, 22, 22, 7 - h, 4 - h), stroke);
        canvas.drawRRect(RRect.fromLTRBAndCorners(8.5, 11.5, 13.5, 19.5 + h, topLeft: const Radius.circular(2), topRight: const Radius.circular(2)), fill);
      case MartTabGlyph.catalog:
        const cell = 9.5;
        for (final o in const [Offset(0, 0), Offset(12.5, 0), Offset(0, 12.5), Offset(12.5, 12.5)]) {
          canvas.drawRRect(box(o.dx, o.dy, cell, cell, 3, 3), stroke);
        }
      case MartTabGlyph.cart:
        canvas.drawRRect(box(1, 6, 20, 14, 2, 5), stroke);
        canvas.drawPath(Path()..moveTo(6 + h, 9)..lineTo(6 + h, 6)..arcToPoint(const Offset(16 - h, 6), radius: const Radius.circular(3.8))..lineTo(16 - h, 9), stroke);
      case MartTabGlyph.profile:
        // Голова: круг 10 сверху по центру. Плечи: дуга 20×9 (радиусы 9) без нижней линии.
        canvas.drawCircle(const Offset(11, 5), 5 - h, stroke);
        const r = 9 - h, top = 13 + h, l = 1 + h, rt = 21 - h;
        canvas.drawPath(Path()
          ..moveTo(l, 22)
          ..arcToPoint(Offset(l + r, top), radius: const Radius.circular(r))
          ..lineTo(rt - r, top)
          ..arcToPoint(Offset(rt, 22), radius: const Radius.circular(r)), stroke);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter o) => o.glyph != glyph || o.color != color;
}
