import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Недавние запросы (до 6), хранятся на устройстве.
class SearchHistoryCubit extends HydratedCubit<List<String>> {
  SearchHistoryCubit() : super(const ['цемент м500', 'краска']);
  void add(String q) {
    final s = q.trim();
    if (s.isEmpty) return;
    emit([s, ...state.where((x) => x != s)].take(6).toList());
  }
  void remove(String q) => emit(state.where((x) => x != q).toList());
  void clearHistory() => emit(const []);
  @override
  List<String>? fromJson(Map<String, dynamic> j) => List<String>.from(j['q'] as List? ?? []);
  @override
  Map<String, dynamic>? toJson(List<String> s) => {'q': s};
}
