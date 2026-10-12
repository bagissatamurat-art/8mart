import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';

class CheckoutState extends Equatable {
  const CheckoutState({this.payment = 'kaspi', this.offer = true, this.entrance = '', this.floor = '', this.flat = '', this.comment = '',
      this.recipientPhone, this.kaspiPhone, this.leaveAtDoor = false, this.touched = false,
      this.courierSlot = 'asap', this.cargoSlot = '', this.lift = false, this.placing = false, this.useBonus = false});
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
  /// Слоты — id из lib/domain/slots.dart: 'asap' или «YYYY-MM-DD|09:00–12:00».
  final String courierSlot, cargoSlot;
  int get floorN => int.tryParse(floor) ?? 0;
  CheckoutState copyWith({String? payment, bool? offer, String? entrance, String? floor, String? flat, String? comment, String? recipientPhone, String? kaspiPhone,
          bool? leaveAtDoor, bool? touched, String? courierSlot, String? cargoSlot, bool? lift, bool? placing, bool? useBonus}) =>
      CheckoutState(payment: payment ?? this.payment, offer: offer ?? this.offer, entrance: entrance ?? this.entrance, floor: floor ?? this.floor, flat: flat ?? this.flat,
          comment: comment ?? this.comment, recipientPhone: recipientPhone ?? this.recipientPhone, kaspiPhone: kaspiPhone ?? this.kaspiPhone,
          leaveAtDoor: leaveAtDoor ?? this.leaveAtDoor, touched: touched ?? this.touched, courierSlot: courierSlot ?? this.courierSlot, cargoSlot: cargoSlot ?? this.cargoSlot,
          lift: lift ?? this.lift, placing: placing ?? this.placing, useBonus: useBonus ?? this.useBonus);
  @override
  List<Object?> get props => [payment, offer, entrance, floor, flat, comment, recipientPhone, kaspiPhone, leaveAtDoor, touched, courierSlot, cargoSlot, lift, placing, useBonus];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit() : super(const CheckoutState());

  void set(CheckoutState Function(CheckoutState s) f) => emit(f(state));
  void setPayment(String v) => emit(state.copyWith(payment: v));
  void toggleOffer() => emit(state.copyWith(offer: !state.offer));
  void toggleLift() => emit(state.copyWith(lift: !state.lift));
  void toggleLeaveAtDoor() => emit(state.copyWith(leaveAtDoor: !state.leaveAtDoor));
  void toggleBonus() => emit(state.copyWith(useBonus: !state.useBonus));
  /// Сколько бонусов можно списать с суммы товаров после промокода.
  static int spendMax(int goods) => [MockData.bonusBalance, goods * MockData.bonusMaxPart ~/ 100].reduce((a, b) => a < b ? a : b);
  void selectDefaultCardIfLoggedIn() {}

  /// Мок POST /orders → {id}. Kaspi: дальше открыть ссылку оплаты и ждать возврата по 8mart.kz/pay/return?order=…
  Future<String> place() async {
    emit(state.copyWith(placing: true));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    emit(state.copyWith(placing: false));
    return '8M-10482';
  }

  static String defaultCardId() => (MockData.cards.where((c) => c.isDefault).firstOrNull ?? MockData.cards.first).id;
}
