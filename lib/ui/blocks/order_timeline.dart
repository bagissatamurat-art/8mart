import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';

class TimelineStage {
  const TimelineStage(this.title, {this.sub, this.time});
  final String title;
  final String? sub, time;
}

/// Шкала статуса одного отправления. current == stages.length-1 → всё зелёное. cancelled → последний этап красный.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.stages, required this.current, this.cancelled = false});
  final List<TimelineStage> stages;
  final int current;
  final bool cancelled;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final last = stages.length - 1;
    final finished = current >= last;
    return Column(children: [
      for (var i = 0; i < stages.length; i++)
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(width: 28, child: Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cancelled && i == last ? c.error : (i < current || (finished && i == last)) ? c.success : c.surface,
                border: Border.all(width: 2, color: cancelled && i == last ? c.error : i < current || finished ? c.success : i == current ? c.primary : c.border),
                boxShadow: i == current && !finished && !cancelled ? [BoxShadow(color: c.focusRing, spreadRadius: 4)] : null,
              ),
              child: Center(child: i == current && !finished && !cancelled
                  ? Container(width: 9, height: 9, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle))
                  : (i < current || finished) && !(cancelled && i == last) ? const CustomPaint(size: Size(12, 9), painter: _Tick()) : null),
            ),
            if (i < last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: i < current ? c.success : c.border)),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: EdgeInsets.only(top: 3, bottom: i < last ? 20 : 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stages[i].title, style: TextStyle(fontFamily: 'Onest', fontSize: 16, height: 22 / 16, fontWeight: i == current ? FontWeight.w700 : FontWeight.w500, color: i <= current ? c.ink1 : c.ink3)),
              if (i == current && !finished && stages[i].sub != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(stages[i].sub!, style: TextStyle(fontFamily: 'Onest', fontSize: 14, height: 1.4, color: c.ink2))),
            ]),
          )),
          if (i <= current && stages[i].time != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(stages[i].time!, style: TextStyle(fontFamily: 'Onest', fontSize: 14, color: c.ink3))),
        ])),
    ]);
  }
}

/// Галочка геометрией (белая).
class _Tick extends CustomPainter {
  const _Tick();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = Colors.white..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..moveTo(1, s.height * .5)..lineTo(s.width * .38, s.height - 1)..lineTo(s.width - 1, 1), p);
  }
  @override
  bool shouldRepaint(_Tick o) => false;
}
