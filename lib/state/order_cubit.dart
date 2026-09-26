import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/models.dart';
import '../domain/shipments.dart';

/// Статус заказа: своя шкала на каждое отправление. 0 принят · 1 собираем · 2 в пути/готов · 3 доставлен/выдан.
class OrderState extends Equatable {
  const OrderState({this.id = '', this.method = ReceiveMethod.delivery, this.kinds = const [], this.current = const [], this.qty = const [], this.total = 0, this.bonus = 0, this.cancelled = false, this.cancelling = false});
  final String id;
  final ReceiveMethod method;
  final List<ShipmentKind> kinds;
  final List<int> current, qty;
  final int total, bonus;
  final bool cancelled, cancelling;
  /// Отмена — всего заказа, пока ни одно отправление не передано в доставку / не готово к выдаче.
  bool get canCancel => !cancelled && current.every((c) => c < 2);
  bool get allDone => current.isNotEmpty && current.every((c) => c >= 3);
  OrderState copyWith({List<int>? current, bool? cancelled, bool? cancelling}) => OrderState(
      id: id, method: method, kinds: kinds, qty: qty, total: total, bonus: bonus,
      current: current ?? this.current, cancelled: cancelled ?? this.cancelled, cancelling: cancelling ?? this.cancelling);
  @override
  List<Object?> get props => [id, method, kinds, current, qty, total, bonus, cancelled, cancelling];
}

class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(const OrderState());

  void create({required String id, required ShipmentPlan plan, required ReceiveMethod method, required int total, required int bonus}) => emit(OrderState(
      id: id, method: method, total: total, bonus: bonus,
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
