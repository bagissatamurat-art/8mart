import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../data/story_repository.dart';
import '../domain/models.dart';

/// Сторис главной: список (живые 8mart.kz + свои) и просмотренные id (хранятся на устройстве — кружок становится серым).
class StoriesState {
  const StoriesState({this.items = const [], this.loading = true, this.seen = const {}});
  final List<Story> items;
  final bool loading;
  final Set<String> seen;
  StoriesState copyWith({List<Story>? items, bool? loading, Set<String>? seen}) =>
      StoriesState(items: items ?? this.items, loading: loading ?? this.loading, seen: seen ?? this.seen);
}

class StoriesCubit extends HydratedCubit<StoriesState> {
  StoriesCubit({StoryRepository repo = const StoryRepository()}) : _repo = repo, super(const StoriesState());
  final StoryRepository _repo;
  bool _requested = false;

  /// Один раз за запуск; повторные вызовы игнорируются.
  Future<void> load() async {
    if (_requested) return;
    _requested = true;
    final items = await _repo.stories();
    if (!isClosed) emit(state.copyWith(items: items, loading: false));
  }

  void markSeen(String id) { if (!state.seen.contains(id)) emit(state.copyWith(seen: {...state.seen, id})); }

  @override
  StoriesState? fromJson(Map<String, dynamic> j) => StoriesState(seen: Set<String>.from(j['seen'] as List? ?? []));
  @override
  Map<String, dynamic>? toJson(StoriesState s) => {'seen': s.seen.toList()};
}
