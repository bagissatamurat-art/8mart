import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../core/api_client.dart';
import '../data/cart_repository.dart';
import '../data/catalog.dart';
import '../data/remote_config.dart';
import '../domain/models.dart';
import '../domain/shipments.dart';

/// Промокод (мок = PROMO в data.js): MART10 −10% от 15 000 тг; SPRING — истёк. Работает, только когда промокоды включены
/// (RemoteConfig.promo): на сервере их пока нет, и скидку, посчитанную в приложении, заказ не получил бы.
enum PromoResult { ok, notFound, expired, minSum }
abstract final class PromoRules {
  static const code = 'MART10', pct = 10, minSum = 15000, expired = {'SPRING'};
}

class CartState extends Equatable {
  const CartState({this.items = const {}, this.soldOut = const {}, this.method, this.address = '', this.together = false, this.promo, this.quote, this.pickupKaspi = false, this.catalogRev = 0,
      this.cityId = '', this.pointId, this.lat, this.lng, this.prices = const {}});
  /// Куда везём / откуда забираем — для сервера: id города, точка самовывоза (= филиал) или координаты адреса доставки.
  final String cityId;
  final String? pointId;
  final double? lat, lng;
  /// Цены своего филиала из последней проверки корзины (ключ позиции → тг). На диск не пишутся: при запуске проверяем заново.
  final Map<String, int> prices;
  /// Версия каталога (Catalog.changes): карточки товаров догрузились — корзина перерисовывается. На диск не пишется.
  final int catalogRev;
  final Map<String, int> items;
  final Set<String> soldOut;
  final ReceiveMethod? method;
  final String address;
  final bool together;
  /// Доставка: зона адреса (стоимость и время курьера); null — общие условия ShippingConfig.
  final DeliveryQuote? quote;
  /// Самовывоз: филиал принимает Kaspi Pay автоматически.
  final bool pickupKaspi;
  /// Счёт в Kaspi на номер не нужен: филиал (зоны доставки или точка самовывоза) принимает Kaspi Pay автоматически.
  bool get kaspiIntegrated => method == ReceiveMethod.pickup ? pickupKaspi : quote?.kaspiIntegrated ?? false;
  /// Применённый промокод (null — нет).
  final String? promo;
  int get discount => RemoteConfig.promo && promo == PromoRules.code && goods >= PromoRules.minSum ? (goods * PromoRules.pct / 100).round() : 0;
  int get afterDiscount => goods - discount;

  List<CartLine> get lines => [
        for (final e in items.entries)
          if (Catalog.cartItem(e.key) case final p?)
            CartLine(switch (prices[e.key]) { final price? when price != p.price => p.withPrice(price), _ => p }, e.value, soldOut: soldOut.contains(e.key)),
      ];
  Iterable<CartLine> get active => lines.where((l) => !l.soldOut);
  int get count => active.fold(0, (s, l) => s + l.qty);
  int get goods => active.fold(0, (s, l) => s + l.sum);
  int get bonus => active.fold(0, (s, l) => s + l.product.bonus * l.qty);
  bool get hasSoldOut => lines.any((l) => l.soldOut);
  int qtyOf(String id) => items[id] ?? 0;

  ShipmentPlan plan({int floor = 0, bool lift = false, int? goodsTotal}) =>
      planShipments(lines, method: method ?? ReceiveMethod.delivery, together: together, goodsTotal: goodsTotal ?? goods, floor: floor, lift: lift,
          cfg: method != ReceiveMethod.pickup && quote != null ? ShippingConfig.current.withZone(fee: quote!.fee, eta: quote!.eta) : ShippingConfig.current);

  CartState copyWith({Map<String, int>? items, Set<String>? soldOut, ReceiveMethod? method, String? address, bool? together, Object? promo = _keep, Object? quote = _keep, bool? pickupKaspi, int? catalogRev,
          String? cityId, Object? pointId = _keep, Object? lat = _keep, Object? lng = _keep, Map<String, int>? prices}) => CartState(
      items: items ?? this.items, soldOut: soldOut ?? this.soldOut, method: method ?? this.method, address: address ?? this.address, together: together ?? this.together,
      promo: identical(promo, _keep) ? this.promo : promo as String?, quote: identical(quote, _keep) ? this.quote : quote as DeliveryQuote?, pickupKaspi: pickupKaspi ?? this.pickupKaspi,
      catalogRev: catalogRev ?? this.catalogRev, cityId: cityId ?? this.cityId,
      pointId: identical(pointId, _keep) ? this.pointId : pointId as String?,
      lat: identical(lat, _keep) ? this.lat : lat as double?, lng: identical(lng, _keep) ? this.lng : lng as double?,
      prices: prices ?? this.prices);
  static const _keep = Object();

  @override
  List<Object?> get props => [items, soldOut, method, address, together, promo, quote, pickupKaspi, catalogRev, cityId, pointId, lat, lng, prices];
}

/// Корзина и способ получения переживают перезапуск (hydrated) — это и офлайн-кеш корзины.
class CartCubit extends HydratedCubit<CartState> {
  /// Демо-корзина с адресом — только на моке; с бэкендом первый запуск начинается с пустой корзины и выбора способа получения.
  CartCubit() : super(Catalog.mocked
      ? const CartState(items: {'b1': 2, 'b6': 1, 'b4': 1}, method: ReceiveMethod.delivery, address: 'Астана, Кабанбай батыра, 11')
      : const CartState()) {
    // С бэкендом: карточки корзины хранятся на диске и дозагружаются после перезапуска; пришли — перерисовываемся.
    Catalog.pin('cart', () => state.items.keys);
    Catalog.changes.addListener(_onCatalog);
    Catalog.ensure(state.items.keys);
    validate();
  }

  final _repo = const CartRepository();
  Timer? _validateSoon;
  int _validateReq = 0;

  void _onCatalog() { if (!isClosed) emit(state.copyWith(catalogRev: Catalog.changes.value)); }

  @override
  Future<void> close() { _validateSoon?.cancel(); Catalog.changes.removeListener(_onCatalog); return super.close(); }

  /// Проверка корзины на сервере: что раскупили и цены своего филиала (точка самовывоза или зона адреса).
  /// true — проверка прошла (или её нет на моке); false — нет сети: остаётся прежнее состояние.
  Future<bool> validate() async {
    _validateSoon?.cancel();
    final req = ++_validateReq;
    final items = state.items;
    try {
      final check = await _repo.validate(items, method: state.method, pickupPointId: state.pointId, lat: state.lat, lng: state.lng);
      if (check == null || isClosed || req != _validateReq) return true;
      emit(state.copyWith(soldOut: check.soldOut.where(state.items.containsKey).toSet(), prices: check.prices));
      return true;
    } on ApiError {
      return false;
    }
  }

  /// После изменения состава — чуть погодя, чтобы серия нажатий «+» дала один запрос.
  void _validateLater() {
    _validateSoon?.cancel();
    _validateSoon = Timer(const Duration(milliseconds: 500), validate);
  }

  /// false — способ получения не выбран: UI открывает шторку выбора, товар не добавляется.
  bool setQty(String id, int qty) {
    if (state.method == null && qty > 0) return false;
    final items = Map<String, int>.from(state.items);
    final soldOut = Set<String>.from(state.soldOut);
    if (qty <= 0) { items.remove(id); soldOut.remove(id); } else { items[id] = qty; }
    emit(state.copyWith(items: items, soldOut: soldOut));
    if (qty > 0) _validateLater();
    return true;
  }

  void clearCart() => emit(state.copyWith(items: {}, soldOut: {}, promo: null));
  PromoResult applyPromo(String raw) {
    if (!RemoteConfig.promo) return PromoResult.notFound;
    final code = raw.trim().toUpperCase();
    if (PromoRules.expired.contains(code)) return PromoResult.expired;
    if (code != PromoRules.code) return PromoResult.notFound;
    if (state.goods < PromoRules.minSum) return PromoResult.minSum;
    emit(state.copyWith(promo: code));
    return PromoResult.ok;
  }
  void removePromo() => emit(state.copyWith(promo: null));
  void removeSoldOut() {
    final items = Map<String, int>.from(state.items)..removeWhere((k, _) => state.soldOut.contains(k));
    emit(state.copyWith(items: items, soldOut: {}));
  }
  /// quote — зона доставки адреса; pickupKaspi — Kaspi подключён в выбранном филиале.
  /// cityId, pointId (самовывоз) и lat/lng (доставка) нужны серверу: по ним он проверяет корзину и создаёт заказ.
  void setMethod(ReceiveMethod m, String address, {DeliveryQuote? quote, bool pickupKaspi = false, String cityId = '', String? pointId, double? lat, double? lng}) {
    final delivery = m == ReceiveMethod.delivery;
    emit(state.copyWith(method: m, address: address, quote: delivery ? quote : null, pickupKaspi: pickupKaspi, cityId: cityId,
        pointId: delivery ? null : pointId, lat: delivery ? lat : null, lng: delivery ? lng : null, prices: const {}));
    validate();
  }
  void setTogether(bool v) => emit(state.copyWith(together: v));
  /// Сервер сообщил, что товара нет в наличии.
  void markSoldOut(String id) => emit(state.copyWith(soldOut: {...state.soldOut, id}));
  void addAll(Map<String, int> add) {
    final items = Map<String, int>.from(state.items);
    add.forEach((k, v) => items[k] = (items[k] ?? 0) + v);
    emit(state.copyWith(items: items));
    Catalog.ensure(add.keys);
    _validateLater();
  }

  @override
  CartState? fromJson(Map<String, dynamic> j) => CartState(
        items: Map<String, int>.from(j['items'] as Map? ?? {}),
        soldOut: Set<String>.from(j['soldOut'] as List? ?? []),
        method: switch (j['method']) { 'delivery' => ReceiveMethod.delivery, 'pickup' => ReceiveMethod.pickup, _ => null },
        address: j['address'] as String? ?? '',
        together: j['together'] as bool? ?? false,
        promo: j['promo'] as String?,
        quote: DeliveryQuote.fromJson(j['quote']),
        pickupKaspi: j['pickupKaspi'] as bool? ?? false,
        cityId: j['cityId'] as String? ?? '',
        pointId: j['pointId'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  @override
  Map<String, dynamic>? toJson(CartState s) => {'items': s.items, 'soldOut': s.soldOut.toList(), 'method': s.method?.name, 'address': s.address, 'together': s.together, 'promo': s.promo, 'quote': s.quote?.toJson(), 'pickupKaspi': s.pickupKaspi,
        'cityId': s.cityId, 'pointId': s.pointId, 'lat': s.lat, 'lng': s.lng};
}
