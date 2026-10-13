import '../core/api_client.dart';
import '../domain/slots.dart';

/// Дни и интервалы доставки. С бэкендом — `GET /delivery/slots?kind=courier|cargo` (имя для API_MOCK — «slots»):
/// правила окон живут на сервере. Без него и при сбое сети — расчёт на устройстве по тем же правилам
/// (lib/domain/slots.dart): оформление не должно вставать из-за одного запроса.
class SlotsRepository {
  const SlotsRepository();
  static const name = 'slots';
  static bool get mocked => ApiClient.isMocked(name);

  /// asapLabel / eta — подписи «Ближайшего»: сервер знает только id 'asap', текст и время зоны — у приложения.
  Future<List<SlotDay>> courier(DateTime now, {required String asapLabel, required String eta}) async {
    if (!mocked) {
      try {
        return daysFromJson(await ApiClient.instance.get<List<dynamic>>('/delivery/slots', query: {'kind': 'courier'}), now, asapLabel: asapLabel, eta: eta);
      } on ApiError {/* расчёт на устройстве */}
    }
    return courierSlots(now, asapLabel: asapLabel, eta: eta);
  }

  Future<List<SlotDay>> cargo(DateTime now) async {
    if (!mocked) {
      try {
        return daysFromJson(await ApiClient.instance.get<List<dynamic>>('/delivery/slots', query: {'kind': 'cargo'}), now);
      } on ApiError {/* расчёт на устройстве */}
    }
    return cargoSlots(now);
  }

  /// Ответ сервера → дни приложения. Подписи дня («Сегодня», «Чт, 16 окт») приложение строит само на своём языке,
  /// поэтому из ответа берутся только id дня (YYYY-MM-DD) и слоты.
  static List<SlotDay> daysFromJson(List<dynamic> json, DateTime now, {String asapLabel = '', String eta = ''}) {
    final today = now.toUtc().add(kzUtcOffset);
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    final out = <SlotDay>[];
    for (final d in json.whereType<Map>()) {
      final id = '${d['id']}';
      final date = DateTime.tryParse('${id}T00:00:00Z');
      if (date == null) continue;
      final slots = [
        for (final s in (d['slots'] as List? ?? const []).whereType<Map>())
          '${s['id']}' == 'asap' ? Slot('asap', asapLabel, eta) : Slot('${s['id']}', s['label'] as String? ?? ''),
      ];
      if (slots.isEmpty) continue;
      out.add(SlotDay(id, date.difference(todayDate).inDays, date.weekday, date.day, date.month, slots));
    }
    return out;
  }
}
