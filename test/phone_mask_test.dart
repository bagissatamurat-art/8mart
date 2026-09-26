import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart8/core/format.dart';
import 'package:mart8/core/phone_mask.dart';
import 'package:mart8/domain/models.dart';
import 'package:mart8/domain/shipments.dart';
import 'package:mart8/data/catalog_repository.dart';
import 'package:mart8/data/mock_data.dart';

TextEditingValue _type(String old, String next, {int? cursor}) =>
    PhoneMaskFormatter().formatEditUpdate(TextEditingValue(text: old), TextEditingValue(text: next, selection: TextSelection.collapsed(offset: cursor ?? next.length)));

void main() {
  group('PhoneMaskFormatter', () {
    test('8 → +7', () => expect(_type('', '8').text, '+7'));
    test('маска', () => expect(_type('', '87001339071').text, '+7 (700) 133-90-71'));
    test('международный', () => expect(_type('+', '+99').text, '+99'));
    test('пустое — пустое', () => expect(_type('+7 (7', '+7 (').text, ''));
    // Backspace на пробеле после «)» (курсор встаёт на место пробела) стирает цифру слева от маски — «0».
    test('Backspace на символе маски стирает цифру', () => expect(_type('+7 (700) 1', '+7 (700)1', cursor: 8).text, '+7 (701'));
    test('complete', () { expect(PhoneMaskFormatter.isComplete('+7 (700) 133-90-71'), isTrue); expect(PhoneMaskFormatter.isComplete('+7 (700) 1'), isFalse); });
  });

  test('money', () => expect(money(4090), '4\u00A0090\u00A0тг.'));

  group('planShipments', () {
    final cement = MockData.byId('b1')!, glue = MockData.byId('b6')!;
    test('только лёгкие — одна курьерская', () {
      final p = planShipments([CartLine(glue, 2)]);
      expect(p.shipments.single.kind, ShipmentKind.courier);
      expect(p.canSplit, isFalse);
    });
    test('смешанная — два отправления', () {
      final p = planShipments([CartLine(glue, 1), CartLine(cement, 2)]);
      expect(p.shipments.map((s) => s.kind), [ShipmentKind.courier, ShipmentKind.cargo]);
      expect(p.shipments.last.fee, 3000);
    });
    test('together — одна Газель', () => expect(planShipments([CartLine(glue, 1), CartLine(cement, 2)], together: true).shipments.single.kind, ShipmentKind.cargo));
    test('самовывоз бесплатно', () => expect(planShipments([CartLine(cement, 2)], method: ReceiveMethod.pickup).fee, 0));
    test('подъём на этаж', () => expect(planShipments([CartLine(cement, 2)], floor: 7, lift: true).lift, 200 * 2 * 6));
  });

  group('CatalogRepository', () {
    const repo = CatalogRepository();
    test('подкатегория', () async => expect((await repo.page(categoryId: 'stroymaterialy', subId: 'kraski')).items.map((p) => p.id), ['b4', 'b12']));
    test('сортировка дешевле', () async { final r = await repo.page(categoryId: 'instrumenty', sort: SortKind.cheap); expect(r.items.first.id, 't6'); });
    test('фильтр скидка', () => expect(repo.count(categoryId: 'instrumenty', filter: const CatalogFilter(sale: true)), 2));
    test('поиск по подкатегории', () => expect(repo.count(query: 'краски'), 2));
    test('пагинация', () async { final r = await repo.page(categoryId: 'stroymaterialy', page: 1); expect(r.items.length, 2); expect(r.total, 10); });
  });
}
