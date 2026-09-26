import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../data/mock_data.dart';
import '../domain/models.dart';
import '../domain/shipments.dart';

/// Промокод (мок = PROMO в data.js): MART10 −10% от 15 000 тг; SPRING — истёк. В проде — POST /cart/promo.
enum PromoResult { ok, notFound, expired, minSum }
abstract final class PromoRules {
  static const code = 'MART10', pct = 10, minSum = 15000, expired = {'SPRING'};
}

class CartState extends Equatable {
  const CartState({this.items = const {}, this.soldOut = const {}, this.method, this.address = '', this.together = false, this.promo});
  final Map<String, int> items;
  final Set<String> soldOut;
  final ReceiveMethod? method;
  final String address;
  final bool together;
  /// Применённый промокод (null — нет).
  final String? promo;
  int get discount => promo == PromoRules.code && goods >= PromoRules.minSum ? (goods * PromoRules.pct / 100).round() : 0;
  int get afterDiscount => goods - discount;

  List<CartLine> get lines => [
        for (final e in items.entries)
          if (MockData.cartItem(e.key) case final p?) CartLine(p, e.value, soldOut: soldOut.contains(e.key)),
      ];
  Iterable<CartLine> get active => lines.where((l) => !l.soldOut);
  int get count => active.fold(0, (s, l) => s + l.qty);
  int get goods => active.fold(0, (s, l) => s + l.sum);
  int get bonus => active.fold(0, (s, l) => s + l.product.bonus * l.qty);
  bool get hasSoldOut => lines.any((l) => l.soldOut);
  int qtyOf(String id) => items[id] ?? 0;

  ShipmentPlan plan({int floor = 0, bool lift = false, int? goodsTotal}) =>
      planShipments(lines, method: method ?? ReceiveMethod.delivery, together: together, goodsTotal: goodsTotal ?? goods, floor: floor, lift: lift);

  CartState copyWith({Map<String, int>? items, Set<String>? soldOut, ReceiveMethod? method, String? address, bool? together, Object? promo = _keep}) => CartState(
      items: items ?? this.items, soldOut: soldOut ?? this.soldOut, method: method ?? this.method, address: address ?? this.address, together: together ?? this.together,
      promo: identical(promo, _keep) ? this.promo : promo as String?);
  static const _keep = Object();

  @override
  List<Object?> get props => [items, soldOut, method, address, together, promo];
}

/// Корзина и способ получения переживают перезапуск (hydrated) — это и офлайн-кеш корзины.
class CartCubit extends HydratedCubit<CartState> {
  CartCubit() : super(const CartState(items: {'b1': 2, 'b6': 1, 'b4': 1}, method: ReceiveMethod.delivery, address: 'Астана, Кабанбай батыра, 11'));

  /// false — способ получения не выбран: UI открывает шторку выбора, товар не добавляется.
  bool setQty(String id, int qty) {
    if (state.method == null && qty > 0) return false;
    final items = Map<String, int>.from(state.items);
    final soldOut = Set<String>.from(state.soldOut);
    if (qty <= 0) { items.remove(id); soldOut.remove(id); } else { items[id] = qty; }
    emit(state.copyWith(items: items, soldOut: soldOut));
    return true;
  }

  void clearCart() => emit(state.copyWith(items: {}, soldOut: {}, promo: null));
  PromoResult applyPromo(String raw) {
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
  void setMethod(ReceiveMethod m, String address) => emit(state.copyWith(method: m, address: address));
  void setTogether(bool v) => emit(state.copyWith(together: v));
  /// Сервер сообщил, что товара нет в наличии.
  void markSoldOut(String id) => emit(state.copyWith(soldOut: {...state.soldOut, id}));
  void addAll(Map<String, int> add) {
    final items = Map<String, int>.from(state.items);
    add.forEach((k, v) => items[k] = (items[k] ?? 0) + v);
    emit(state.copyWith(items: items));
  }

  @override
  CartState? fromJson(Map<String, dynamic> j) => CartState(
        items: Map<String, int>.from(j['items'] as Map? ?? {}),
        soldOut: Set<String>.from(j['soldOut'] as List? ?? []),
        method: switch (j['method']) { 'delivery' => ReceiveMethod.delivery, 'pickup' => ReceiveMethod.pickup, _ => null },
        address: j['address'] as String? ?? '',
        together: j['together'] as bool? ?? false,
        promo: j['promo'] as String?,
      );

  @override
  Map<String, dynamic>? toJson(CartState s) => {'items': s.items, 'soldOut': s.soldOut.toList(), 'method': s.method?.name, 'address': s.address, 'together': s.together, 'promo': s.promo};
}
