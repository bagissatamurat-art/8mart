/// Каталог push-уведомлений. Источник правды — docs/APP_SPEC.md §1.
/// Payload от бэкенда (FCM data): {type, orderId?, shipment?, status?, promo?, link?}.
enum PushChannel { orders, promo, bonus, cart }

enum PushType {
  orderAccepted(PushChannel.orders), orderAssembling(PushChannel.orders), courierOnWay(PushChannel.orders), cargoOnWay(PushChannel.orders),
  readyForPickup(PushChannel.orders), delivered(PushChannel.orders), orderCancelled(PushChannel.orders), refundDone(PushChannel.orders),
  paymentFailed(PushChannel.orders), itemSoldOut(PushChannel.orders),
  bonusAccrued(PushChannel.bonus), // бонусы не сгорают — пуша о сгорании нет
  promo(PushChannel.promo), abandonedCart(PushChannel.cart);
  const PushType(this.channel);
  final PushChannel channel;
}

/// Куда ведёт тап по уведомлению (go_router location).
String pushRoute(Map<String, dynamic> data) {
  final type = PushType.values.where((t) => t.name == data['type']).firstOrNull;
  final order = data['orderId'] as String?;
  return switch (type) {
    null => '/',
    PushType.bonusAccrued => '/profile/bonus',
    PushType.promo => (data['link'] as String?) ?? '/profile/promos',
    PushType.abandonedCart || PushType.itemSoldOut => '/cart',
    PushType.paymentFailed => '/checkout',
    _ => order == null ? '/profile/orders' : '/order/$order',
  };
}

/// Android notification channels (создать при старте). orders — важный, со звуком; остальные — по умолчанию.
const androidChannels = {
  PushChannel.orders: ('orders', 'Статус заказа', 'high'),
  PushChannel.bonus: ('bonus', 'Бонусы', 'default'),
  PushChannel.promo: ('promo', 'Акции и скидки', 'default'),
  PushChannel.cart: ('cart', 'Забытая корзина', 'low'),
};
