import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import '../data/order_repository.dart';
import '../data/remote_config.dart';
import '../data/slots_repository.dart';
import '../domain/slots.dart';

class CheckoutState extends Equatable {
  const CheckoutState({this.payment = 'kaspi', this.offer = true, this.entrance = '', this.floor = '', this.flat = '', this.comment = '',
      this.recipientPhone, this.kaspiPhone, this.leaveAtDoor = false, this.touched = false,
      this.courierSlot = 'asap', this.cargoSlot = '', this.lift = false, this.placing = false, this.useBonus = false,
      this.courierDays, this.cargoDays});
  /// Списать бонусы (до MockData.bonusMaxPart% суммы товаров).
  final bool useBonus;
  /// 'kaspi' | id сохранённой карты | 'new'
  final String payment;
  /// Согласие с офертой включено по умолчанию (как на сайте).
  final bool offer, lift, placing;
  final String entrance, floor, flat, comment;
  /// Телефон получателя и номер для счёта Kaspi; null — из профиля (можно поменять).
  final String? recipientPhone, kaspiPhone;
  /// Доставка: курьер оставит у двери.
  final bool leaveAtDoor;
  /// Пользователь трогал поля телефонов — показываем ошибки.
  final bool touched;
  /// Слоты — id из GET /delivery/slots: 'asap' или «YYYY-MM-DD|09:00–12:00».
  final String courierSlot, cargoSlot;
  /// Дни и интервалы с сервера; null — ещё не пришли (экран считает их сам по тем же правилам).
  final List<SlotDay>? courierDays, cargoDays;
  int get floorN => int.tryParse(floor) ?? 0;
  CheckoutState copyWith({String? payment, bool? offer, String? entrance, String? floor, String? flat, String? comment, String? recipientPhone, String? kaspiPhone,
          bool? leaveAtDoor, bool? touched, String? courierSlot, String? cargoSlot, bool? lift, bool? placing, bool? useBonus,
          List<SlotDay>? courierDays, List<SlotDay>? cargoDays}) =>
      CheckoutState(payment: payment ?? this.payment, offer: offer ?? this.offer, entrance: entrance ?? this.entrance, floor: floor ?? this.floor, flat: flat ?? this.flat,
          comment: comment ?? this.comment, recipientPhone: recipientPhone ?? this.recipientPhone, kaspiPhone: kaspiPhone ?? this.kaspiPhone,
          leaveAtDoor: leaveAtDoor ?? this.leaveAtDoor, touched: touched ?? this.touched, courierSlot: courierSlot ?? this.courierSlot, cargoSlot: cargoSlot ?? this.cargoSlot,
          lift: lift ?? this.lift, placing: placing ?? this.placing, useBonus: useBonus ?? this.useBonus,
          courierDays: courierDays ?? this.courierDays, cargoDays: cargoDays ?? this.cargoDays);
  @override
  List<Object?> get props => [payment, offer, entrance, floor, flat, comment, recipientPhone, kaspiPhone, leaveAtDoor, touched, courierSlot, cargoSlot, lift, placing, useBonus, courierDays, cargoDays];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({this.orders = const OrderRepository(), this.slots = const SlotsRepository()}) : super(const CheckoutState());
  final OrderRepository orders;
  final SlotsRepository slots;

  void set(CheckoutState Function(CheckoutState s) f) => emit(f(state));
  void setPayment(String v) => emit(state.copyWith(payment: v));
  void toggleOffer() => emit(state.copyWith(offer: !state.offer));
  void toggleLift() => emit(state.copyWith(lift: !state.lift));
  void toggleLeaveAtDoor() => emit(state.copyWith(leaveAtDoor: !state.leaveAtDoor));
  void toggleBonus() => emit(state.copyWith(useBonus: !state.useBonus));
  /// Сколько бонусов можно списать с суммы товаров после промокода. Бонусов на сервере нет — без них списывать нечего.
  static int spendMax(int goods) => !RemoteConfig.bonus ? 0 : [MockData.bonusBalance, goods * MockData.bonusMaxPart ~/ 100].reduce((a, b) => a < b ? a : b);
  void selectDefaultCardIfLoggedIn() {}

  /// Оформление открыто: дни и интервалы доставки с сервера (на моке — расчёт на устройстве, как раньше).
  Future<void> loadSlots() async {
    if (SlotsRepository.mocked) return;
    final now = DateTime.now();
    final r = await Future.wait([slots.courier(now, asapLabel: '', eta: ''), slots.cargo(now)]);
    if (!isClosed) emit(state.copyWith(courierDays: r[0], cargoDays: r[1]));
  }

  /// POST /orders → {id, payUrl?}. Ошибку (ApiError) пробрасываем: экран покажет её текст.
  Future<PlacedOrder> place(OrderDraft draft) async {
    emit(state.copyWith(placing: true));
    try {
      return await orders.create(draft);
    } finally {
      if (!isClosed) emit(state.copyWith(placing: false));
    }
  }

  /// После оформления: поля адреса и комментарий следующему заказу не нужны.
  void reset() => emit(CheckoutState(payment: state.payment, offer: state.offer, courierDays: state.courierDays, cargoDays: state.cargoDays));
}
