import 'package:flutter_test/flutter_test.dart';
import 'package:mart8/domain/slots.dart';

// Время Казахстана = UTC+5: 07:30Z = 12:30 KZ.
void main() {
  group('слоты доставки', () {
    test('сегодня: «Ближайшее» и интервалы, до которых ≥ часа', () {
      final days = courierSlots(DateTime.utc(2026, 10, 13, 7, 30), asapLabel: 'Ближайшее', eta: '~30 мин');
      expect(days.map((d) => d.offset), [0, 1, 2]);
      expect(days.first.slots.map((s) => s.label), ['Ближайшее', '15:00–18:00', '18:00–21:00']);
      expect(days.first.slots.first.id, 'asap');
      expect(days[1].slots, hasLength(4));
    });
    test('поздно вечером сегодня нет', () {
      final days = courierSlots(DateTime.utc(2026, 10, 13, 16, 30), asapLabel: 'Ближайшее', eta: '');
      expect(days.first.offset, 1);
      expect(days, hasLength(2));
    });
    test('день — по времени Казахстана', () {
      final days = courierSlots(DateTime.utc(2026, 10, 13, 19, 30), asapLabel: 'Ближайшее', eta: ''); // в KZ уже 14-е 00:30
      expect(days.first.id, '2026-10-14');
      expect(days.first.slots.first.id, isNot('asap'));
    });
    test('грузовой — с завтра', () {
      final days = cargoSlots(DateTime.utc(2026, 10, 13, 7, 30));
      expect(days.first.id, '2026-10-14');
      expect(days.first.slots.first.id, '2026-10-14|09:00–13:00');
      expect(hasSlot(days, '2026-10-16|13:00–17:00'), true);
    });
  });
}
