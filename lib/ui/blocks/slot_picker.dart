import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import '../widgets/mart_select.dart';

/// День для SlotPicker: id, подпись («Сегодня» / «Завтра» / «Чт») и дата («16 окт»).
class SlotPickerDay {
  const SlotPickerDay({required this.id, required this.title, required this.date, required this.options});
  final String id, title, date;
  final List<MartSelectOption> options;
}

/// Выбор времени доставки (оформление, как на сайте): дни — карточки в ряд (выбранный — розовым), время дня — выпадающим списком.
/// Смена дня выбирает первое время этого дня.
class SlotPicker extends StatelessWidget {
  const SlotPicker({super.key, required this.days, required this.value, required this.onChanged, required this.timeLabel});
  final List<SlotPickerDay> days;
  final String value;
  final ValueChanged<String> onChanged;
  /// Подпись поля времени: «Время».
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final c = context.mc;
    final day = days.firstWhere((d) => d.options.any((o) => o.id == value), orElse: () => days.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (days.length > 1) ...[
        Row(children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) const SizedBox(width: MartSpace.s8),
            Expanded(child: Semantics(
              button: true, selected: days[i] == day, label: '${days[i].title}, ${days[i].date}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: days[i] == day ? null : () => onChanged(days[i].options.first.id),
                child: AnimatedContainer(
                  duration: MartMotion.press, height: MartHeight.field,
                  decoration: BoxDecoration(
                    color: days[i] == day ? c.primary50 : c.surface, borderRadius: BorderRadius.circular(MartRadius.field),
                    border: Border.all(color: days[i] == day ? c.primary : c.border, width: days[i] == day ? 2 : 1),
                  ),
                  child: ExcludeSemantics(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(days[i].title, style: MartText.bodyStrong.copyWith(height: 1.2, color: days[i] == day ? c.primaryPressed : c.ink1)),
                    const SizedBox(height: 2),
                    Text(days[i].date, style: MartText.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: days[i] == day ? c.primary : c.ink2)),
                  ])),
                ),
              ),
            )),
          ],
        ]),
        const SizedBox(height: MartSpace.s12),
      ],
      MartSelect(label: timeLabel, options: day.options, value: day.options.any((o) => o.id == value) ? value : day.options.first.id, onChanged: onChanged,
          sheetTitle: '$timeLabel · ${day.title.toLowerCase()}, ${day.date}'),
    ]);
  }
}
