import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';

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
                  : (i < current || finished) && !(cancelled && i == last) ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null),
            ),
            if (i < last) Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: i < current ? c.success : c.border)),
          ])),
          const SizedBox(width: 14),
          Expanded(child: Padding(
            padding: EdgeInsets.only(top: 3, bottom: i < last ? 20 : 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(stages[i].title, style: MartText.body.copyWith(height: 1.35, fontWeight: i == current ? FontWeight.w700 : FontWeight.w500, color: i <= current ? c.ink1 : c.ink3)),
              if (i == current && !finished && stages[i].sub != null) Padding(padding: const EdgeInsets.only(top: 3), child: Text(stages[i].sub!, style: MartText.small.copyWith(color: c.ink2))),
            ]),
          )),
          if (i <= current && stages[i].time != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(stages[i].time!, style: MartText.small.copyWith(color: c.ink3))),
        ])),
    ]);
  }
}
