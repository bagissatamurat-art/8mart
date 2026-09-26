import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';

class CheckoutState extends Equatable {
  const CheckoutState({this.payment = 'kaspi', this.offer = false, this.entrance = '2', this.floor = '7', this.flat = '48', this.comment = '',
      this.slot = 0, this.cargoDay = 0, this.cargoInterval = 0, this.lift = false, this.placing = false, this.useBonus = false});
  /// Списать бонусы (до MockData.bonusMaxPart% суммы товаров).
  final bool useBonus;
  /// 'kaspi' | id сохранённой карты | 'new'
  final String payment;
  final bool offer, lift, placing;
  final String entrance, floor, flat, comment;
  final int slot, cargoDay, cargoInterval;
  int get floorN => int.tryParse(floor) ?? 0;
  CheckoutState copyWith({String? payment, bool? offer, String? entrance, String? floor, String? flat, String? comment, int? slot, int? cargoDay, int? cargoInterval, bool? lift, bool? placing, bool? useBonus}) =>
      CheckoutState(payment: payment ?? this.payment, offer: offer ?? this.offer, entrance: entrance ?? this.entrance, floor: floor ?? this.floor, flat: flat ?? this.flat,
          comment: comment ?? this.comment, slot: slot ?? this.slot, cargoDay: cargoDay ?? this.cargoDay, cargoInterval: cargoInterval ?? this.cargoInterval, lift: lift ?? this.lift, placing: placing ?? this.placing, useBonus: useBonus ?? this.useBonus);
  @override
  List<Object?> get props => [payment, offer, entrance, floor, flat, comment, slot, cargoDay, cargoInterval, lift, placing, useBonus];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit() : super(const CheckoutState());
  static const slots = ['Ближайшее, 60–90 мин', 'Сегодня 12:00–15:00', 'Сегодня 15:00–18:00'];
  static const cargoDays = ['Завтра, 27 сентября', 'Пн, 28 сентября', 'Вт, 29 сентября'];
  static const cargoIntervals = ['9:00–13:00', '13:00–17:00', '17:00–21:00'];

  void set(CheckoutState Function(CheckoutState s) f) => emit(f(state));
  void setPayment(String v) => emit(state.copyWith(payment: v));
  void toggleOffer() => emit(state.copyWith(offer: !state.offer));
  void toggleLift() => emit(state.copyWith(lift: !state.lift));
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
