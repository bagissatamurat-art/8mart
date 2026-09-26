import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mock_data.dart';
import '../domain/models.dart';

class AccountState extends Equatable {
  const AccountState({this.loading = true, this.orders = const [], this.addresses = const [], this.cards = const [], this.promos = const [], this.bonusBalance = 0, this.bonusHistory = const []});
  final bool loading;
  final List<OrderSummary> orders;
  final List<Address> addresses;
  final List<SavedCard> cards;
  final List<UserPromo> promos;
  final int bonusBalance;
  final List<BonusOp> bonusHistory;
  OrderSummary? get active => orders.where((o) => o.isActive).firstOrNull;
  AccountState copyWith({bool? loading, List<OrderSummary>? orders, List<Address>? addresses, List<SavedCard>? cards, List<UserPromo>? promos, int? bonusBalance, List<BonusOp>? bonusHistory}) => AccountState(
      loading: loading ?? this.loading, orders: orders ?? this.orders, addresses: addresses ?? this.addresses, cards: cards ?? this.cards,
      promos: promos ?? this.promos, bonusBalance: bonusBalance ?? this.bonusBalance, bonusHistory: bonusHistory ?? this.bonusHistory);
  @override
  List<Object?> get props => [loading, orders, addresses, cards, promos, bonusBalance];
}

/// Личный кабинет. МОК: GET /me/orders, /me/addresses, /me/cards, /me/promos, /me/bonus.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit() : super(const AccountState());
  bool _started = false;

  Future<void> load() async {
    if (_started) return;
    _started = true;
    emit(state.copyWith(loading: true));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    emit(const AccountState(loading: false, orders: MockData.orders, addresses: MockData.addresses, cards: MockData.cards,
        promos: MockData.promos, bonusBalance: MockData.bonusBalance, bonusHistory: MockData.bonusHistory));
  }

  void saveAddress(Address a) {
    final list = [...state.addresses];
    final i = list.indexWhere((x) => x.id == a.id);
    if (i >= 0) { list[i] = a; } else { list.add(a.copyWith(isDefault: list.isEmpty)); }
    emit(state.copyWith(addresses: list));
  }

  void deleteAddress(String id) {
    final list = state.addresses.where((x) => x.id != id).toList();
    if (list.isNotEmpty && !list.any((x) => x.isDefault)) list[0] = list[0].copyWith(isDefault: true);
    emit(state.copyWith(addresses: list));
  }

  void setDefaultAddress(String id) => emit(state.copyWith(addresses: [for (final a in state.addresses) a.copyWith(isDefault: a.id == id)]));
  void deleteCard(String id) => emit(state.copyWith(cards: state.cards.where((c) => c.id != id).toList()));
  void reset() { _started = false; emit(const AccountState()); }
}
