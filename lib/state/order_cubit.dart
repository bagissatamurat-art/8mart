import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/api_client.dart';
import '../data/order_repository.dart';
import '../domain/models.dart';
import '../domain/shipments.dart';

/// Статус заказа: своя шкала на каждое отправление. 0 принят · 1 собираем · 2 в пути/готов · 3 доставлен/выдан.
class OrderState extends Equatable {
  const OrderState({this.id = '', this.number = '', this.method = ReceiveMethod.delivery, this.kinds = const [], this.current = const [], this.qty = const [], this.total = 0, this.bonus = 0, this.cancelled = false, this.cancelling = false,
      this.lines = const [], this.address = '', this.paidWith = '', this.date = '', this.goods = 0, this.discount = 0, this.spent = 0, this.fees = const [], this.recipientPhone = '', this.leaveAtDoor = false,
      this.remote = false, this.loading = false, this.missing = false, this.offline = false, this.kaspi = true, this.paid = true, this.payUrl, this.recipientName = '',
      this.eta, this.times = const [], this.courierName, this.courierPhone, this.cancelError});
  final String id, address, paidWith, date;
  /// Номер для людей («1042»). С бэкендом [id] — длинный ключ заказа; показываем номер.
  final String number;
  String get title => number.isEmpty ? id : number;
  /// Телефон получателя (из оформления) и «оставить у двери».
  final String recipientPhone;
  final bool leaveAtDoor;
  /// Состав заказа и суммы для блока «N товаров» на экране статуса.
  final List<CartLine> lines;
  final int goods, discount, spent;
  final List<int> fees;
  final ReceiveMethod method;
  final List<ShipmentKind> kinds;
  final List<int> current, qty;
  final int total, bonus;
  final bool cancelled, cancelling;

  // ── с бэкендом ──
  /// Заказ пришёл с сервера: время этапов, срок и курьер — настоящие (на моке экран показывает демо-значения).
  final bool remote;
  /// Первый ответ ещё не пришёл / такого заказа нет / нет сети и показать нечего.
  final bool loading, missing, offline;
  /// Оплата: Kaspi или карта; оплачен ли; ссылка, по которой можно оплатить неоплаченный.
  final bool kaspi, paid;
  final String? payUrl;
  final String recipientName;
  /// Выбранный слот: «14 октября, 09:00–12:00»; null — «как можно скорее».
  final String? eta;
  /// Время пройденных этапов, «ЧЧ:ММ».
  final List<String> times;
  final String? courierName, courierPhone;
  /// Текст отказа в отмене (заказ уже в доставке) — экран покажет его один раз.
  final String? cancelError;

  /// Отмена — всего заказа, пока ни одно отправление не передано в доставку / не готово к выдаче.
  bool get canCancel => !cancelled && current.every((c) => c < 2);
  bool get allDone => current.isNotEmpty && current.every((c) => c >= 3);
  OrderState copyWith({List<int>? current, bool? cancelled, bool? cancelling, bool? loading, bool? offline, Object? cancelError = _keep}) => OrderState(
      id: id, number: number, method: method, kinds: kinds, qty: qty, total: total, bonus: bonus, lines: lines, address: address, paidWith: paidWith, date: date, goods: goods, discount: discount, spent: spent, fees: fees,
      recipientPhone: recipientPhone, leaveAtDoor: leaveAtDoor, current: current ?? this.current, cancelled: cancelled ?? this.cancelled, cancelling: cancelling ?? this.cancelling,
      remote: remote, loading: loading ?? this.loading, missing: missing, offline: offline ?? this.offline, kaspi: kaspi, paid: paid, payUrl: payUrl, recipientName: recipientName,
      eta: eta, times: times, courierName: courierName, courierPhone: courierPhone,
      cancelError: identical(cancelError, _keep) ? this.cancelError : cancelError as String?);
  static const _keep = Object();
  @override
  List<Object?> get props => [id, number, method, kinds, current, qty, total, bonus, cancelled, cancelling, remote, loading, missing, offline, paid, payUrl, eta, times, courierName, lines.length, cancelError];
}

/// Заказ из истории (кабинет → «Подробнее»), если он не тот, что только что оформлен.
OrderState orderFromSummary(OrderSummary o, List<CartLine> lines) => OrderState(
      id: o.id, number: o.number, method: o.method, total: o.total, bonus: o.bonus, address: o.address, date: o.date, lines: lines, goods: o.total,
      kinds: const [ShipmentKind.courier], qty: [lines.fold(0, (s, l) => s + l.qty)], cancelled: o.status == OrderStatus.cancelled,
      current: [stageOf(o.status)],
    );

/// Статус заказа → шаг шкалы.
int stageOf(OrderStatus s) => switch (s) { OrderStatus.accepted => 0, OrderStatus.assembling => 1, OrderStatus.onway || OrderStatus.ready => 2, _ => 3 };

/// Заказ с сервера → состояние экрана. Отправление одно: тяжёлых товаров в каталоге нет, всё везёт курьер.
OrderState orderFromRemote(RemoteOrder o) {
  final lines = o.lines;
  return OrderState(
    id: o.id, number: o.number, method: o.method, total: o.total, address: o.address, date: o.date, lines: lines, goods: o.goods,
    fees: o.method == ReceiveMethod.pickup ? const [] : [o.deliveryFee],
    kinds: const [ShipmentKind.courier], qty: [lines.fold(0, (s, l) => s + l.qty)], current: [stageOf(o.status)], cancelled: o.status == OrderStatus.cancelled,
    recipientPhone: o.recipientPhone, recipientName: o.recipientName, leaveAtDoor: o.leaveAtDoor,
    remote: true, kaspi: o.kaspi, paid: o.paid, payUrl: o.payUrl, eta: o.eta, times: o.times, courierName: o.courierName, courierPhone: o.courierPhone,
  );
}

/// Текущий заказ. С бэкендом — `GET /orders/{id}`: пока экран статуса открыт и заказ не завершён, статус
/// опрашивается раз в 15 с (push и сокетов для покупателя пока нет). На моке — состояние из оформления, как раньше.
class OrderCubit extends Cubit<OrderState> {
  OrderCubit({this.repo = const OrderRepository()}) : super(const OrderState());
  final OrderRepository repo;
  static const _every = Duration(seconds: 15);
  Timer? _poll;

  void create({required String id, String number = '', required ShipmentPlan plan, required ReceiveMethod method, required int total, required int bonus,
      List<CartLine> lines = const [], String address = '', String paidWith = '', int goods = 0, int discount = 0, int spent = 0,
      String recipientPhone = '', bool leaveAtDoor = false}) => emit(OrderState(
      recipientPhone: recipientPhone, leaveAtDoor: leaveAtDoor, id: id, number: number, method: method, total: total, bonus: bonus, lines: lines, address: address, paidWith: paidWith, date: 'сегодня', goods: goods, discount: discount, spent: spent,
      fees: [for (final s in plan.shipments) s.fee + s.lift],
      kinds: [for (final s in plan.shipments) s.kind], qty: [for (final s in plan.shipments) s.qty], current: [for (final _ in plan.shipments) 0],
      // С бэкендом это черновик до первого ответа сервера: оплаты ещё не было.
      loading: !OrderRepository.mocked, paid: OrderRepository.mocked));

  /// Экран статуса открыт: заказ с сервера и опрос статуса. На моке ничего не делает.
  Future<void> open(String id) async {
    if (OrderRepository.mocked || id.isEmpty) return;
    if (state.id != id) emit(OrderState(id: id, loading: true));
    _poll?.cancel();
    await refresh();
    if (!isClosed && !state.missing) _poll = Timer.periodic(_every, (_) => refresh());
  }

  /// Экран статуса закрыт — опрос не нужен.
  void stopPolling() => _poll?.cancel();

  Future<void> refresh() async {
    final id = state.id;
    if (OrderRepository.mocked || id.isEmpty) return;
    try {
      final o = await repo.get(id);
      if (isClosed || state.id != id) return;
      if (o == null) { _poll?.cancel(); emit(OrderState(id: id, missing: true)); return; }
      emit(orderFromRemote(o));
      if (o.status == OrderStatus.cancelled || o.status == OrderStatus.done) _poll?.cancel();
    } on ApiError {
      if (!isClosed && state.id == id) emit(state.copyWith(loading: false, offline: true));
    }
  }

  /// Приходит из push / WebSocket: {orderId, shipment, status}.
  void setStatus(int shipment, int status) {
    final c = List<int>.from(state.current);
    if (shipment < c.length) c[shipment] = status;
    emit(state.copyWith(current: c));
  }

  /// Отмена. С бэкендом сервер может отказать (заказ уже собран) — тогда [OrderState.cancelError] и свежий статус.
  Future<void> cancel() async {
    emit(state.copyWith(cancelling: true, cancelError: null));
    try {
      await repo.cancel(state.id);
      if (isClosed) return;
      if (OrderRepository.mocked) { emit(state.copyWith(cancelling: false, cancelled: true)); return; }
      await refresh();
    } on ApiError catch (e) {
      if (isClosed) return;
      emit(state.copyWith(cancelling: false, cancelError: e.message));
      if (e.status == 409) await refresh();
    }
  }

  void clearCancelError() => emit(state.copyWith(cancelError: null));

  @override
  Future<void> close() { _poll?.cancel(); return super.close(); }
}
