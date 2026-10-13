import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mart8/core/api_client.dart';
import 'package:mart8/data/cart_repository.dart';
import 'package:mart8/data/catalog.dart';
import 'package:mart8/data/order_repository.dart';
import 'package:mart8/data/remote_config.dart';
import 'package:mart8/data/slots_repository.dart';
import 'package:mart8/domain/models.dart';
import 'package:mart8/domain/shipments.dart';
import 'package:mart8/domain/slots.dart';
import 'package:mart8/state/order_cubit.dart';

http.Response json(int status, Object? body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

/// Ответы витрины в форме прода (урезано).
const _order = {
  'id': 'uuid-1', 'number': '118', 'date': '13 октября, 15:27', 'method': 'delivery', 'status': 'onway', 'address': 'Астана, ул. Сыганак, 13',
  'eta': '15 октября, 18:00–21:00', 'payment': 'kaspi',
  'items': [{'id': 'rose-s', 'qty': 1, 'name': 'Розы мандала, S', 'price': 17700, 'img': 'https://api.test/s.png'}, {'id': 'gone', 'qty': 2, 'name': 'Снятый товар', 'price': 390}],
  'shipments': [{'kind': 'courier', 'status': 'onway', 'eta': '15 октября, 18:00–21:00', 'times': ['15:27', '15:40', '16:10'], 'courier': {'name': 'Ерлан', 'phone': '+7 700 111 22 33'}}],
  'total': 21480, 'bonus': 0, 'recipient': {'name': 'Айгерим', 'phone': '+77000000001'}, 'leaveAtDoor': true, 'kaspiPhone': '+77000000002',
  'goods': 18480, 'fees': [{'label': 'Доставка', 'amount': 3000}], 'paid': false, 'payUrl': 'https://kaspi.kz/pay/abc',
};
const _bouquet = {'id': 'rose-l', 'name': 'Розы мандала', 'weight': 'S · L', 'price': 9000, 'cat': 'rozy', 'img': 'https://api.test/l.png', 'delivery': 'flowers', 'weightKg': 1,
  'variants': [{'id': 'rose-s', 'size': 'S', 'price': 9000, 'img': 'https://api.test/s.png'}, {'id': 'rose-l', 'size': 'L', 'price': 19000, 'img': 'https://api.test/l.png'}]};

void main() {
  final calls = <http.Request>[];
  var down = false;
  var conflict = false;

  setUp(() {
    calls.clear();
    down = false;
    conflict = false;
    Catalog.reset();
    RemoteConfig.debugSet(null);
    ApiClient.instance = ApiClient(baseUrl: 'https://api.test/store', mocked: '', client: MockClient((r) async {
      calls.add(r);
      if (down) throw http.ClientException('offline');
      return switch ((r.method, r.url.path)) {
        ('POST', '/store/orders') => json(200, {'id': 'uuid-1', 'number': '118', 'payUrl': 'https://kaspi.kz/pay/abc'}),
        ('GET', '/store/orders/uuid-1') => json(200, _order),
        ('GET', '/store/orders') => json(200, [_order]),
        ('POST', '/store/orders/uuid-1/cancel') => conflict
            ? json(409, {'error': {'code': 409, 'message': 'Заказ уже передан в доставку'}})
            : json(200, {'refund': {'amount': 0, 'to': 'Kaspi'}, 'bonusReturned': 0}),
        ('POST', '/store/cart/validate') => json(200, {'lines': [
          {'id': 'rose-s|Белый', 'qty': 1, 'soldOut': false, 'price': 9500}, {'id': 'gone', 'qty': 1, 'soldOut': true, 'price': null}], 'plan': {}}),
        ('GET', '/store/products') => json(200, [_bouquet]),
        ('GET', '/store/delivery/slots') => json(200, [
          {'id': '2026-10-13', 'title': 'Сегодня', 'date': '13 окт', 'slots': [{'id': 'asap', 'label': 'Ближайшее'}, {'id': '2026-10-13|18:00–21:00', 'label': '18:00–21:00'}]},
          {'id': '2026-10-15', 'title': 'Чт', 'date': '15 окт', 'slots': [{'id': '2026-10-15|09:00–12:00', 'label': '09:00–12:00'}]},
          {'id': 'мусор', 'slots': [{'id': 'x', 'label': 'x'}]}]),
        ('GET', '/store/app/config') => json(200, {'support': {'phone': '+77001339071', 'whatsapp': '77001339071'}, 'payments': ['kaspi'], 'delivery': {}}),
        _ => json(404, {'error': {'code': 404, 'message': 'Order not found'}}),
      };
    }));
  });
  tearDown(() { ApiClient.instance = ApiClient(baseUrl: '', mocked: ''); RemoteConfig.debugSet(null); });

  group('заказ', () {
    const repo = OrderRepository();

    test('черновик уходит без сумм: товары, место и оплата — сервер считает сам', () async {
      const draft = OrderDraft(cart: {'rose-s|Белый': 1, 'milk': 2}, method: ReceiveMethod.delivery, cityId: 'astana', address: 'ул. Сыганак, 13',
          entrance: '2', floor: '7', flat: '48', comment: 'Позвоните', recipientName: 'Айгерим', recipientPhone: '+7 (700) 000-00-01',
          leaveAtDoor: true, kaspiPhone: '+7 (700) 000-00-02', courierSlot: '2026-10-15|18:00–21:00', kaspi: true, lat: 51.1282, lng: 71.4307);

      final placed = await repo.create(draft);

      final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
      expect(body['cart'], {'rose-s|Белый': 1, 'milk': 2});
      expect((body['method'], body['city'], body['address'], body['payment']), ('delivery', 'astana', 'ул. Сыганак, 13', 'kaspi'));
      expect((body['lat'], body['lng'], body['pickupPointId']), (51.1282, 71.4307, null));
      expect(body['recipient'], {'name': 'Айгерим', 'phone': '+7 (700) 000-00-01'});
      expect((body['leaveAtDoor'], body['kaspiPhone'], body['courierSlot']), (true, '+7 (700) 000-00-02', '2026-10-15|18:00–21:00'));
      // Ни цен, ни стоимости доставки, ни скидок в запросе нет.
      expect(body.keys.where((k) => const {'total', 'goods', 'courierFee', 'deliveryAmount', 'discount', 'promo'}.contains(k)), isEmpty);
      expect((placed.id, placed.number, placed.payUrl), ('uuid-1', '118', 'https://kaspi.kz/pay/abc'));
    });

    test('самовывоз: точка вместо координат, «у двери» не передаётся', () {
      const draft = OrderDraft(cart: {'milk': 1}, method: ReceiveMethod.pickup, cityId: 'astana', address: 'пр. Абылай хана, 32', pickupPointId: 'b1',
          recipientPhone: '+7 (700) 000-00-01', leaveAtDoor: true, kaspi: false, lat: 1, lng: 2);
      final body = draft.toJson();
      expect((body['method'], body['pickupPointId'], body['payment'], body['leaveAtDoor']), ('pickup', 'b1', 'card', false));
      expect(body.containsKey('kaspiPhone'), isFalse);
    });

    test('заказ с сервера → экран статуса: номер, время этапов, слот, курьер, оплата', () async {
      Catalog.remember([_bouquet]);
      final o = (await repo.get('uuid-1'))!;
      final s = orderFromRemote(o);

      expect((s.id, s.title, s.date), ('uuid-1', '118', '13 октября, 15:27'));
      expect((s.method, s.cancelled, s.canCancel), (ReceiveMethod.delivery, false, false));
      expect(s.current, [2]);
      expect((s.address, s.eta), ('Астана, ул. Сыганак, 13', '15 октября, 18:00–21:00'));
      expect(s.times, ['15:27', '15:40', '16:10']);
      expect((s.courierName, s.courierPhone), ('Ерлан', '+7 700 111 22 33'));
      expect((s.total, s.goods), (21480, 18480));
      expect(s.fees, [3000]);
      expect((s.remote, s.kaspi, s.paid, s.payUrl), (true, true, false, 'https://kaspi.kz/pay/abc'));
      expect((s.recipientName, s.recipientPhone, s.leaveAtDoor), ('Айгерим', '+77000000001', true));
      // Размер букета — карточка из каталога по цене заказа; снятый товар — название и цена из самого заказа.
      expect([for (final l in s.lines) (l.product.name, l.product.price, l.qty)], [('Розы мандала, S', 17700, 1), ('Снятый товар', 390, 2)]);
    });

    test('нет заказа — null, нет сети — ApiError', () async {
      expect(await repo.get('unknown'), isNull);
      down = true;
      await expectLater(repo.get('uuid-1'), throwsA(isA<ApiError>()));
    });

    test('список — по id с устройства; карточки состава дозагружаются', () async {
      final list = await repo.list(['uuid-1']);
      expect(calls.first.url.queryParameters, {'ids': 'uuid-1'});
      expect((list.single.id, list.single.title, list.single.status), ('uuid-1', '118', OrderStatus.onway));
      expect(list.single.items, {'rose-s': 1, 'gone': 2});
      expect(Catalog.cartItem('rose-s')?.name, 'Розы мандала, S');
      calls.clear();
      expect(await repo.list(const []), isEmpty);
      expect(calls, isEmpty);
    });

    test('отмена: отказ сервера доходит текстом, статус перечитывается', () async {
      final cubit = OrderCubit();
      await cubit.open('uuid-1');
      cubit.stopPolling();
      conflict = true;
      final errors = <String?>[];
      final sub = cubit.stream.listen((s) => errors.add(s.cancelError));
      await cubit.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(errors, contains('Заказ уже передан в доставку'));
      expect((cubit.state.cancelling, cubit.state.cancelled, cubit.state.remote), (false, false, true));
      await sub.cancel();
      await cubit.close();
    });
  });

  test('корзина: раскупленное и цены своего филиала — по ключам позиций', () async {
    final check = (await const CartRepository().validate({'rose-s|Белый': 1, 'gone': 1}, method: ReceiveMethod.pickup, pickupPointId: 'b1', lat: 1, lng: 2))!;
    final body = jsonDecode(calls.single.body) as Map<String, dynamic>;
    // Самовывоз — точка; координаты относятся только к доставке.
    expect((body['method'], body['pickupPointId'], body.containsKey('lat')), ('pickup', 'b1', false));
    expect(check.soldOut, {'gone'});
    expect(check.prices, {'rose-s|Белый': 9500});
    calls.clear();
    expect(await const CartRepository().validate(const {}), isNull);
    expect(calls, isEmpty);
  });

  test('слоты с сервера: день считается от «сегодня» Казахстана, «Ближайшее» подписывает приложение', () async {
    final now = DateTime.utc(2026, 10, 13, 7, 30); // 12:30 в Казахстане
    final days = withAsap(await const SlotsRepository().courier(now, asapLabel: '', eta: ''), asapLabel: 'Ближайшее', eta: '~50 мин');
    expect([for (final d in days) (d.id, d.offset, d.weekday, d.day, d.month)], [('2026-10-13', 0, 2, 13, 10), ('2026-10-15', 2, 4, 15, 10)]);
    expect((days.first.slots.first.id, days.first.slots.first.label, days.first.slots.first.sub), ('asap', 'Ближайшее', '~50 мин'));
    expect(days.last.slots.single.id, '2026-10-15|09:00–12:00');
    // Сеть упала — оформление не встаёт: те же правила считаются на устройстве.
    down = true;
    expect(await const SlotsRepository().courier(now, asapLabel: 'Ближайшее', eta: ''), isNotEmpty);
  });

  group('настройки с сервера', () {
    test('контакты, оплата, функции и порог бесплатной доставки', () async {
      await RemoteConfig.refresh();
      expect((RemoteConfig.supportWa, RemoteConfig.supportPhone), ('77001339071', '+7 700 133 90 71'));
      expect((RemoteConfig.cardPayment, RemoteConfig.promo, RemoteConfig.bonus, RemoteConfig.telegramBot), (false, false, false, null));
      // Сервер не назвал порог — бесплатной доставки от суммы нет: платится стоимость зоны.
      expect((RemoteConfig.freeFrom, ShippingConfig.current.hasFreeDelivery), (null, false));
      final plan = planShipments([const CartLine(Product(id: 'p', name: 'Букет', pack: '', price: 50000, image: '', categoryId: 'c'), 1)],
          cfg: ShippingConfig.current.withZone(fee: 3000, eta: 50));
      expect(plan.fee, 3000);
    });

    test('порог есть — действует; до ответа сервера — значения приложения', () {
      expect(ShippingConfig.current.freeFrom, 20000);
      RemoteConfig.debugSet({'delivery': {'freeFrom': 15000}, 'features': {'promo': true}});
      expect((ShippingConfig.current.freeFrom, ShippingConfig.current.hasFreeDelivery, RemoteConfig.promo), (15000, true, true));
    });
  });
}
