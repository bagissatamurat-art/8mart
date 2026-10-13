// Слоты доставки для оформления (03): дни и интервалы от текущего времени Казахстана (UTC+5) — порт lib/domain/slots.ts сайта.
// В проде их отдаёт бэкенд (GET /delivery/slots) — здесь мок той же формы.

/// Смещение времени Казахстана от UTC (единый пояс UTC+5 с 2024 г.).
const kzUtcOffset = Duration(hours: 5);

class Slot {
  const Slot(this.id, this.label, [this.sub]);
  /// 'asap' или «YYYY-MM-DD|09:00–12:00».
  final String id;
  /// «12:00–15:00» / «Ближайшее».
  final String label;
  /// «~30 мин» — только у ближайшего.
  final String? sub;
}

class SlotDay {
  const SlotDay(this.id, this.offset, this.weekday, this.day, this.month, this.slots);
  /// YYYY-MM-DD
  final String id;
  /// 0 — сегодня, 1 — завтра…
  final int offset;
  /// 1 — понедельник … 7 — воскресенье (DateTime.weekday).
  final int weekday, day, month;
  final List<Slot> slots;
}

/// Настройки слотов. МОК — в проде бэкенд.
class SlotConfig {
  const SlotConfig({
    this.courierDays = 3, this.leadMin = 60, this.asapUntil = '21:00',
    this.courierIntervals = const ['09:00–12:00', '12:00–15:00', '15:00–18:00', '18:00–21:00'],
    this.cargoDays = 3, this.cargoIntervals = const ['09:00–13:00', '13:00–17:00', '17:00–21:00'],
  });
  final int courierDays, leadMin, cargoDays;
  final String asapUntil;
  final List<String> courierIntervals, cargoIntervals;
}

DateTime _kz(DateTime now, [int plusDays = 0]) => now.toUtc().add(kzUtcOffset).add(Duration(days: plusDays));
String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
int _min(String hhmm) => int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));

SlotDay _day(DateTime now, int plus, List<Slot> slots) {
  final d = _kz(now, plus);
  return SlotDay(_ymd(d), plus, d.weekday, d.day, d.month, slots);
}

/// Курьер: сегодня — «Ближайшее» (пока не поздно) и интервалы, до начала которых ≥ leadMin; дальше — все интервалы.
List<SlotDay> courierSlots(DateTime now, {required String asapLabel, required String eta, SlotConfig cfg = const SlotConfig()}) {
  final k = _kz(now), nowMin = k.hour * 60 + k.minute;
  final out = <SlotDay>[];
  for (var i = 0; i < cfg.courierDays; i++) {
    final id = _ymd(_kz(now, i));
    final list = [for (final x in cfg.courierIntervals) if (i > 0 || _min(x) - nowMin >= cfg.leadMin) Slot('$id|$x', x)];
    if (i == 0 && nowMin < _min(cfg.asapUntil) && nowMin >= _min(cfg.courierIntervals.first) - cfg.leadMin) list.insert(0, Slot('asap', asapLabel, eta));
    if (list.isNotEmpty) out.add(_day(now, i, list));
  }
  return out;
}

/// Грузовой: с завтрашнего дня, все интервалы.
List<SlotDay> cargoSlots(DateTime now, {SlotConfig cfg = const SlotConfig()}) => [
  for (var k = 1; k <= cfg.cargoDays; k++) _day(now, k, [for (final x in cfg.cargoIntervals) Slot('${_ymd(_kz(now, k))}|$x', x)]),
];

/// Дни с сервера приходят без подписи «Ближайшего»: текст и время зоны адреса подставляет приложение.
List<SlotDay> withAsap(List<SlotDay> days, {required String asapLabel, required String eta}) => [
  for (final d in days) SlotDay(d.id, d.offset, d.weekday, d.day, d.month, [for (final s in d.slots) s.id == 'asap' ? Slot('asap', asapLabel, eta) : s]),
];

/// Есть ли слот среди дней (выбранный мог пройти, пока оформляли).
bool hasSlot(List<SlotDay> days, String id) => days.any((d) => d.slots.any((s) => s.id == id));
SlotDay? dayOf(List<SlotDay> days, String id) => days.where((d) => d.slots.any((s) => s.id == id)).firstOrNull;
