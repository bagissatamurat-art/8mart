import '../core/api_client.dart';
import '../domain/models.dart';
import 'catalog.dart';
import 'mock_data.dart';

/// Тело `POST /orders` — OrderDraft контракта (BACKEND_HANDOFF.md сайта). Суммы не передаём: товары, доставку и итог
/// считает сервер. lat/lng — координаты адреса доставки: по ним сервер определяет филиал и стоимость зоны.
class OrderDraft {
  const OrderDraft({required this.cart, required this.method, required this.cityId, required this.address, this.pickupPointId,
      this.entrance = '', this.floor = '', this.flat = '', this.comment = '', this.recipientName = '', required this.recipientPhone,
      this.leaveAtDoor = false, this.kaspiPhone, this.together = false, this.courierSlot = 'asap', this.cargoSlot = '', this.lift = false,
      required this.kaspi, this.lat, this.lng});
  final Map<String, int> cart;
  final ReceiveMethod method;
  final String cityId, address, entrance, floor, flat, comment, recipientName, recipientPhone, courierSlot, cargoSlot;
  final String? pickupPointId, kaspiPhone;
  final bool leaveAtDoor, together, lift, kaspi;
  final double? lat, lng;

  Map<String, dynamic> toJson() => {
        'cart': cart,
        'method': method.name,
        'city': cityId,
        'address': address,
        'pickupPointId': pickupPointId,
        'entrance': entrance, 'floor': floor, 'flat': flat, 'comment': comment,
        'recipient': {'name': recipientName, 'phone': recipientPhone},
        'leaveAtDoor': method == ReceiveMethod.delivery && leaveAtDoor,
        if (kaspiPhone != null) 'kaspiPhone': kaspiPhone,
        'together': together, 'courierSlot': courierSlot, 'cargoSlot': cargoSlot, 'lift': lift,
        'useBonus': false,
        'payment': kaspi ? 'kaspi' : 'card',
        'cardId': null,
        if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
      };
}

/// Заказ создан. payUrl — ссылка Kaspi или страница платёжного шлюза; её нет, когда счёт Kaspi оператор выставит на номер.
class PlacedOrder {
  const PlacedOrder({required this.id, this.number = '', this.payUrl});
  final String id, number;
  final String? payUrl;
}

class RemoteOrderItem {
  const RemoteOrderItem({required this.id, required this.qty, this.name = '', this.price, this.image = ''});
  final String id, name, image;
  final int qty;
  final int? price;
}

/// Заказ с сервера — `GET /orders/{id}`.
class RemoteOrder {
  const RemoteOrder({required this.id, required this.number, required this.date, required this.method, required this.status, required this.address,
      required this.kaspi, required this.items, required this.total, required this.goods, required this.deliveryFee, required this.times,
      this.eta, this.recipientName = '', this.recipientPhone = '', this.leaveAtDoor = false, this.kaspiPhone, this.courierName, this.courierPhone,
      this.paid = false, this.payUrl});
  final String id, number, date, address, recipientName, recipientPhone;
  final ReceiveMethod method;
  final OrderStatus status;
  final bool kaspi, leaveAtDoor, paid;
  final List<RemoteOrderItem> items;
  final int total, goods, deliveryFee;
  /// Время пройденных этапов шкалы, «ЧЧ:ММ».
  final List<String> times;
  final String? eta, kaspiPhone, courierName, courierPhone, payUrl;

  static OrderStatus _status(Object? v) => OrderStatus.values.where((s) => s.name == v).firstOrNull ?? OrderStatus.accepted;

  static RemoteOrder fromJson(Map<String, dynamic> j) {
    final shipment = ((j['shipments'] as List?)?.firstOrNull as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final courier = (shipment['courier'] as Map?)?.cast<String, dynamic>();
    final recipient = (j['recipient'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final fees = (j['fees'] as List? ?? const []).whereType<Map>();
    final items = [
      for (final i in (j['items'] as List? ?? const []).whereType<Map>())
        RemoteOrderItem(id: '${i['id']}', qty: (i['qty'] as num?)?.round() ?? 1, name: i['name'] as String? ?? '',
            price: (i['price'] as num?)?.round(), image: i['img'] as String? ?? ''),
    ];
    return RemoteOrder(
      id: '${j['id']}',
      number: '${j['number'] ?? ''}',
      date: j['date'] as String? ?? '',
      method: j['method'] == 'pickup' ? ReceiveMethod.pickup : ReceiveMethod.delivery,
      status: _status(j['status']),
      address: j['address'] as String? ?? '',
      kaspi: j['payment'] != 'card',
      items: items,
      total: (j['total'] as num?)?.round() ?? 0,
      goods: (j['goods'] as num?)?.round() ?? items.fold<int>(0, (s, i) => s + (i.price ?? 0) * i.qty),
      deliveryFee: fees.fold<int>(0, (s, f) => s + ((f['amount'] as num?)?.round() ?? 0)),
      times: [for (final t in (shipment['times'] as List? ?? const [])) '$t'],
      eta: (shipment['eta'] ?? j['eta']) as String?,
      recipientName: recipient['name'] as String? ?? '',
      recipientPhone: recipient['phone'] as String? ?? '',
      leaveAtDoor: j['leaveAtDoor'] == true,
      kaspiPhone: j['kaspiPhone'] as String?,
      courierName: courier?['name'] as String?,
      courierPhone: courier?['phone'] as String?,
      paid: j['paid'] == true,
      payUrl: j['payUrl'] as String?,
    );
  }

  /// Позиции заказа как строки корзины: карточка из каталога, а если товар с витрины сняли — название и цена из заказа.
  List<CartLine> get lines => [
        for (final i in items)
          CartLine(
            switch (Catalog.cartItem(i.id)) {
              final p? => i.price != null && i.price != p.price ? p.withPrice(i.price!) : p,
              null => Product(id: i.id, name: i.name, pack: '', price: i.price, image: i.image, categoryId: ''),
            },
            i.qty,
          ),
      ];

  OrderSummary get summary => OrderSummary(id: id, number: number, date: date, method: method, status: status, eta: eta,
      items: {for (final i in items) i.id: i.qty}, total: total, address: address);
}

/// Заказы: создание, страница заказа, отмена. С бэкендом — `/orders…` витрины (имя для API_MOCK — «orders»);
/// без него — мок, как раньше. Входа пока нет, поэтому список — по id заказов, оформленных с этого устройства.
class OrderRepository {
  const OrderRepository();
  /// Имя в `API_MOCK`.
  static const name = 'orders';
  static bool get mocked => ApiClient.isMocked(name);

  Future<PlacedOrder> create(OrderDraft draft) async {
    if (mocked) {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      return const PlacedOrder(id: '8M-10482');
    }
    final j = await ApiClient.instance.post<Map<String, dynamic>>('/orders', body: draft.toJson());
    return PlacedOrder(id: '${j['id']}', number: '${j['number'] ?? ''}', payUrl: j['payUrl'] as String?);
  }

  /// null — заказа нет (удалён или ссылка неверна); ApiError — сеть.
  Future<RemoteOrder?> get(String id) async {
    try {
      return RemoteOrder.fromJson(await ApiClient.instance.get<Map<String, dynamic>>('/orders/${Uri.encodeComponent(id)}'));
    } on ApiError catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  /// Заказы по id, в порядке списка. На моке — демо-заказы кабинета.
  Future<List<OrderSummary>> list(List<String> ids) async {
    if (mocked) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return MockData.orders;
    }
    if (ids.isEmpty) return const [];
    final j = await ApiClient.instance.get<List<dynamic>>('/orders', query: {'ids': ids.join(',')});
    final orders = [for (final o in j.whereType<Map>()) RemoteOrder.fromJson(o.cast<String, dynamic>())];
    // «Повторить» и превью состава читают карточки из каталога.
    await Catalog.ensure([for (final o in orders) ...o.items.map((i) => i.id)]);
    return [for (final o in orders) o.summary];
  }

  /// Отмена, пока заказ не собран. ApiError(409) — уже передан в доставку или отменён.
  Future<void> cancel(String id) async {
    if (mocked) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return;
    }
    await ApiClient.instance.post<Map<String, dynamic>>('/orders/${Uri.encodeComponent(id)}/cancel');
  }
}
