import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/models.dart';
import '../domain/shipments.dart';

/// Статус заказа: своя шкала на каждое отправление. 0 принят · 1 собираем · 2 в пути/готов · 3 доставлен/выдан.
class OrderState extends Equatable {
  const OrderState({this.id = '', this.method = ReceiveMethod.delivery, this.kinds = const [], this.current = const [], this.qty = const [], this.total = 0, this.bonus = 0, this.cancelled = false, this.cancelling = false,
      this.lines = const [], this.address = '', this.paidWith = '', this.date = '', this.goods = 0, this.discount = 0, this.spent = 0, this.fees = const []});
  final String id, address, paidWith, date;
  /// Состав заказа и суммы для блока «N товаров» на экране статуса.
  final List<CartLine> lines;
  final int goods, discount, spent;
  final List<int> fees;
  final ReceiveMethod method;
  final List<ShipmentKind> kinds;
  final List<int> current, qty;
  final int total, bonus;
  final bool cancelled, cancelling;
  /// Отмена — всего заказа, пока ни одно отправление не передано в доставку / не готово к выдаче.
  bool get canCancel => !cancelled && current.every((c) => c < 2);
  bool get allDone => current.isNotEmpty && current.every((c) => c >= 3);
  OrderState copyWith({List<int>? current, bool? cancelled, bool? cancelling}) => OrderState(
      id: id, method: method, kinds: kinds, qty: qty, total: total, bonus: bonus, lines: lines, address: address, paidWith: paidWith, date: date, goods: goods, discount: discount, spent: spent, fees: fees,
      current: current ?? this.current, cancelled: cancelled ?? this.cancelled, cancelling: cancelling ?? this.cancelling);
  @override
  List<Object?> get props => [id, method, kinds, current, qty, total, bonus, cancelled, cancelling];
}

/// Заказ из истории (кабинет → «Подробнее»), если он не тот, что только что оформлен.
OrderState orderFromSummary(OrderSummary o, List<CartLine> lines) => OrderState(
      id: o.id, method: o.method, total: o.total, bonus: o.bonus, address: o.address, date: o.date, lines: lines, goods: o.total,
      kinds: const [ShipmentKind.courier], qty: [lines.fold(0, (s, l) => s + l.qty)], cancelled: o.status == OrderStatus.cancelled,
      current: [switch (o.status) { OrderStatus.accepted => 0, OrderStatus.assembling => 1, OrderStatus.onway || OrderStatus.ready => 2, _ => 3 }],
    );

class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(const OrderState());

  void create({required String id, required ShipmentPlan plan, required ReceiveMethod method, required int total, required int bonus,
      List<CartLine> lines = const [], String address = '', String paidWith = '', int goods = 0, int discount = 0, int spent = 0}) => emit(OrderState(
      id: id, method: method, total: total, bonus: bonus, lines: lines, address: address, paidWith: paidWith, date: 'сегодня', goods: goods, discount: discount, spent: spent,
      fees: [for (final s in plan.shipments) s.fee + s.lift],
      kinds: [for (final s in plan.shipments) s.kind], qty: [for (final s in plan.shipments) s.qty], current: [for (final _ in plan.shipments) 0]));

  /// Приходит из push / WebSocket: {orderId, shipment, status}.
  void setStatus(int shipment, int status) {
    final c = List<int>.from(state.current);
    if (shipment < c.length) c[shipment] = status;
    emit(state.copyWith(current: c));
  }

  Future<void> cancel() async {
    emit(state.copyWith(cancelling: true));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    emit(state.copyWith(cancelling: false, cancelled: true));
  }
}
