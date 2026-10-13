import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart' show HydratedBloc, Storage;

import '../core/api_client.dart';
import '../data/mock_data.dart';
import '../data/order_repository.dart';
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

/// Личный кабинет.
///
/// На моке — демо-данные, как раньше. С бэкендом, пока нет настоящего входа:
/// - заказы — те, что оформлены с этого устройства ([placedIds]), статусы с сервера (`GET /orders?ids=`);
/// - адреса хранятся на устройстве;
/// - сохранённых карт, промокодов и бонусов на сервере нет — списки пустые, без выдуманных чисел.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit({this.orders = const OrderRepository(), List<String> Function()? placedIds})
      : _placedIds = placedIds ?? (() => const []), super(const AccountState());
  final OrderRepository orders;
  final List<String> Function() _placedIds;
  bool _started = false;
  static const _kAddresses = 'account.addresses';

  Future<void> load() async {
    if (_started) return;
    _started = true;
    emit(state.copyWith(loading: true));
    if (OrderRepository.mocked) {
      final demo = await orders.list(const []);
      if (isClosed) return;
      emit(AccountState(loading: false, orders: demo, addresses: MockData.addresses, cards: MockData.cards,
          promos: MockData.promos, bonusBalance: MockData.bonusBalance, bonusHistory: MockData.bonusHistory));
      return;
    }
    emit(state.copyWith(addresses: _readAddresses()));
    await refreshOrders();
  }

  /// Свежие статусы заказов (вход в «Мои заказы», возврат с экрана заказа, «потянуть вниз»).
  Future<void> refreshOrders() async {
    if (OrderRepository.mocked) return;
    try {
      final fresh = await orders.list(_placedIds());
      if (!isClosed) emit(state.copyWith(loading: false, orders: fresh));
    } on ApiError {
      // Нет сети — оставляем то, что уже показано.
      if (!isClosed) emit(state.copyWith(loading: false));
    }
  }

  void saveAddress(Address a) {
    final list = [...state.addresses];
    final i = list.indexWhere((x) => x.id == a.id);
    if (i >= 0) { list[i] = a; } else { list.add(a.copyWith(isDefault: list.isEmpty)); }
    _setAddresses(list);
  }

  void deleteAddress(String id) {
    final list = state.addresses.where((x) => x.id != id).toList();
    if (list.isNotEmpty && !list.any((x) => x.isDefault)) list[0] = list[0].copyWith(isDefault: true);
    _setAddresses(list);
  }

  void setDefaultAddress(String id) => _setAddresses([for (final a in state.addresses) a.copyWith(isDefault: a.id == id)]);
  void deleteCard(String id) => emit(state.copyWith(cards: state.cards.where((c) => c.id != id).toList()));
  void reset() { _started = false; emit(const AccountState()); }

  void _setAddresses(List<Address> list) {
    emit(state.copyWith(addresses: list));
    if (!OrderRepository.mocked) {
      _store?.write(_kAddresses, [
        for (final a in list) {'id': a.id, 'title': a.title, 'street': a.street, 'city': a.city, 'entrance': a.entrance, 'floor': a.floor, 'flat': a.flat, 'isDefault': a.isDefault},
      ]);
    }
  }

  List<Address> _readAddresses() {
    final saved = _store?.read(_kAddresses);
    if (saved is! List) return const [];
    return [
      for (final j in saved.whereType<Map>())
        Address(id: '${j['id']}', title: j['title'] as String? ?? '', street: j['street'] as String? ?? '', city: j['city'] as String? ?? '',
            entrance: j['entrance'] as String? ?? '', floor: j['floor'] as String? ?? '', flat: j['flat'] as String? ?? '', isDefault: j['isDefault'] == true),
    ];
  }

  static Storage? get _store {
    try { return HydratedBloc.storage; } catch (_) { return null; }
  }
}
