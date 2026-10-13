import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Заказы, оформленные с этого устройства (id, новые первыми). Пока нет входа, это и есть «Мои заказы»:
/// сервер отдаёт заказ по его id. С настоящим входом список переедет на сервер.
class PlacedOrdersCubit extends HydratedCubit<List<String>> {
  PlacedOrdersCubit() : super(const []);
  static const _max = 50;

  void add(String id) {
    if (id.isEmpty) return;
    emit([id, ...state.where((x) => x != id)].take(_max).toList());
  }

  @override
  List<String>? fromJson(Map<String, dynamic> j) => List<String>.from(j['ids'] as List? ?? const []);
  @override
  Map<String, dynamic>? toJson(List<String> s) => {'ids': s};
}
