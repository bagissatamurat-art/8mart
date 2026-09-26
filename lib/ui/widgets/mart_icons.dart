import 'package:flutter/material.dart';

/// Крестики, плюс/минус, шевроны — геометрией, не символами шрифта.
class MartCross extends StatelessWidget {
  const MartCross({super.key, this.size = 14, required this.color, this.stroke = 2});
  final double size, stroke;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _CrossPainter(color, stroke));
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color, this.stroke);
  final Color color;
  final double stroke;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = stroke..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(s.width, s.height), p);
    canvas.drawLine(Offset(s.width, 0), Offset(0, s.height), p);
  }
  @override
  bool shouldRepaint(_CrossPainter o) => o.color != color || o.stroke != stroke;
}

class MartPlusMinus extends StatelessWidget {
  const MartPlusMinus({super.key, required this.plus, required this.color, this.size = 12});
  final bool plus;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Stack(alignment: Alignment.center, children: [
          Container(width: size, height: 2, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
          if (plus) Container(width: 2, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(1))),
        ]),
      );
}

enum ChevronDir { left, right, down, up }

class MartChevron extends StatelessWidget {
  const MartChevron({super.key, this.dir = ChevronDir.right, required this.color, this.size = 8});
  final ChevronDir dir;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    final turns = {ChevronDir.right: 0.0, ChevronDir.down: 0.25, ChevronDir.left: 0.5, ChevronDir.up: 0.75}[dir]!;
    return RotationTransition(
      turns: AlwaysStoppedAnimation(turns),
      child: CustomPaint(size: Size.square(size * 1.6), painter: _ChevronPainter(color)),
    );
  }
}

class _ChevronPainter extends CustomPainter {
  _ChevronPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(s.width * .35, s.height * .2)..lineTo(s.width * .7, s.height * .5)..lineTo(s.width * .35, s.height * .8);
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(_ChevronPainter o) => o.color != color;
}

/// Лупа геометрией: кольцо 12 (линия 2) + ручка 7 под 45°.
class MartSearchIcon extends StatelessWidget {
  const MartSearchIcon({super.key, required this.color, this.size = 18});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _SearchPainter(color));
}

class _SearchPainter extends CustomPainter {
  _SearchPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 18;
    final p = Paint()..color = color..strokeWidth = 2 * k..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(6 * k, 6 * k), 5 * k, p);
    canvas.drawLine(Offset(10.5 * k, 10.5 * k), Offset(16 * k, 16 * k), p);
  }
  @override
  bool shouldRepaint(_SearchPainter o) => o.color != color;
}
