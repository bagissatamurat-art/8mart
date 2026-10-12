import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/slots.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';

/// Подписи дня: «Сегодня» / «Завтра» / «Чт» и дата «16 окт» — на языке приложения.
String dayTitle(BuildContext context, SlotDay d) {
  final t = L10n.of(context);
  if (d.offset == 0) return t.today;
  if (d.offset == 1) return t.tomorrow;
  final w = DateFormat.E(Localizations.localeOf(context).toString()).format(DateTime(2024, 1, d.weekday)); // 1 янв. 2024 — понедельник
  return w.isEmpty ? w : w[0].toUpperCase() + w.substring(1);
}

String dayDate(BuildContext context, SlotDay d) =>
    DateFormat('d MMM', Localizations.localeOf(context).toString()).format(DateTime(2024, d.month, d.day)).replaceAll('.', '');

List<SlotPickerDay> pickerDays(BuildContext context, List<SlotDay> days) => [
  for (final d in days) SlotPickerDay(id: d.id, title: dayTitle(context, d), date: dayDate(context, d), options: [for (final s in d.slots) MartSelectOption(s.id, s.label, s.sub)]),
];

/// Выбранный слот, если он ещё есть; иначе — первый доступный.
String effectiveSlot(List<SlotDay> days, String id) => hasSlot(days, id) || days.isEmpty ? id : days.first.slots.first.id;

/// Подпись выбранного слота для шапки отправления: «Сегодня, 15:00–18:00», «Чт, 16 окт, 09:00–13:00»; «Ближайшее» — null (текст планировщика).
String? slotTitle(BuildContext context, List<SlotDay> days, String id) {
  final d = dayOf(days, id);
  if (d == null || id == 'asap') return null;
  final s = d.slots.firstWhere((x) => x.id == id);
  return '${dayTitle(context, d)}${d.offset > 1 ? ', ${dayDate(context, d)}' : ''}, ${s.label}';
}
