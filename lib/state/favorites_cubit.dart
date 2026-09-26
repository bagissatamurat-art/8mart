import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Избранное — общий стор на все экраны (в проде синхронизировать с GET/PUT /favorites).
class FavoritesCubit extends HydratedCubit<Set<String>> {
  FavoritesCubit() : super(const {'b4', 'b1'});
  void toggle(String id) => emit(state.contains(id) ? ({...state}..remove(id)) : {id, ...state});
  @override
  Set<String>? fromJson(Map<String, dynamic> j) => Set<String>.from(j['ids'] as List? ?? []);
  @override
  Map<String, dynamic>? toJson(Set<String> s) => {'ids': s.toList()};
}
