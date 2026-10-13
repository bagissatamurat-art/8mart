import '../core/api_client.dart';
import '../domain/models.dart';

/// Ответ проверки корзины: что раскупили и точные цены своего филиала (ключ — ключ позиции корзины).
class CartCheck {
  const CartCheck({this.soldOut = const {}, this.prices = const {}});
  final Set<String> soldOut;
  final Map<String, int> prices;
}

/// `POST /cart/validate` — цены и наличие считает сервер по филиалу: точке самовывоза или зоне адреса.
/// Имя для API_MOCK — «cart». На моке проверки нет (распроданное помечается вручную, как раньше).
class CartRepository {
  const CartRepository();
  static const name = 'cart';
  static bool get mocked => ApiClient.isMocked(name);

  /// null — проверка не проводилась (мок); ApiError — сеть.
  Future<CartCheck?> validate(Map<String, int> items, {ReceiveMethod? method, String? pickupPointId, double? lat, double? lng}) async {
    if (mocked || items.isEmpty) return null;
    final j = await ApiClient.instance.post<Map<String, dynamic>>('/cart/validate', body: {
      'cart': items,
      if (method != null) 'method': method.name,
      if (method == ReceiveMethod.pickup && pickupPointId != null) 'pickupPointId': pickupPointId,
      if (method == ReceiveMethod.delivery && lat != null && lng != null) ...{'lat': lat, 'lng': lng},
    });
    final soldOut = <String>{};
    final prices = <String, int>{};
    for (final l in (j['lines'] as List? ?? const []).whereType<Map>()) {
      final id = '${l['id']}';
      if (l['soldOut'] == true) soldOut.add(id);
      if (l['price'] case final num p) prices[id] = p.round();
    }
    return CartCheck(soldOut: soldOut, prices: prices);
  }
}
