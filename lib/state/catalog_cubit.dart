import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/catalog_repository.dart';
import '../domain/models.dart';

const _keep = Object();

class CatalogState extends Equatable {
  const CatalogState({this.categoryId, this.subId, this.query, this.sort = SortKind.popular, this.filter = const CatalogFilter(),
      this.items = const [], this.total = 0, this.loading = false, this.loadingMore = false, this.offline = false});
  final String? categoryId, subId, query;
  final SortKind sort;
  final CatalogFilter filter;
  final List<Product> items;
  final int total;
  final bool loading, loadingMore, offline;
  bool get hasMore => items.length < total;
  bool get empty => !loading && !offline && items.isEmpty;
  bool get end => !loading && !hasMore && items.length > CatalogRepository.pageSize;

  CatalogState copyWith({Object? subId = _keep, Object? query = _keep, SortKind? sort, CatalogFilter? filter, List<Product>? items, int? total, bool? loading, bool? loadingMore, bool? offline}) => CatalogState(
        categoryId: categoryId,
        subId: identical(subId, _keep) ? this.subId : subId as String?,
        query: identical(query, _keep) ? this.query : query as String?,
        sort: sort ?? this.sort, filter: filter ?? this.filter, items: items ?? this.items, total: total ?? this.total,
        loading: loading ?? this.loading, loadingMore: loadingMore ?? this.loadingMore, offline: offline ?? this.offline);

  @override
  List<Object?> get props => [categoryId, subId, query, sort, filter, items, total, loading, loadingMore, offline];
}

/// Список товаров: категория / подкатегория / поисковый запрос + фильтры, сортировка, бесконечная прокрутка.
class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit({this.repo = const CatalogRepository(), String? categoryId, String? subId, String? query, bool autoload = true})
      : super(CatalogState(categoryId: categoryId, subId: subId, query: query)) {
    if (autoload) load();
  }
  final CatalogRepository repo;
  int _req = 0;

  Future<void> load() async {
    final req = ++_req;
    emit(state.copyWith(loading: true, offline: false, items: const [], total: 0));
    try {
      final r = await repo.page(categoryId: state.categoryId, subId: state.subId, query: state.query, sort: state.sort, filter: state.filter);
      if (req == _req) emit(state.copyWith(loading: false, items: r.items, total: r.total));
    } on CatalogOffline {
      if (req == _req) emit(state.copyWith(loading: false, offline: true));
    }
  }

  Future<void> more() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final req = _req;
    emit(state.copyWith(loadingMore: true));
    try {
      final r = await repo.page(categoryId: state.categoryId, subId: state.subId, query: state.query, sort: state.sort, filter: state.filter,
          page: state.items.length ~/ CatalogRepository.pageSize);
      if (req == _req) emit(state.copyWith(loadingMore: false, items: [...state.items, ...r.items], total: r.total));
    } on CatalogOffline {
      if (req == _req) emit(state.copyWith(loadingMore: false));
    }
  }

  int countWith(CatalogFilter f) => repo.count(categoryId: state.categoryId, subId: state.subId, query: state.query, filter: f);
  void setSub(String? id) { emit(state.copyWith(subId: id)); load(); }
  void setSort(SortKind s) { emit(state.copyWith(sort: s)); load(); }
  void setFilter(CatalogFilter f) { emit(state.copyWith(filter: f)); load(); }
  void search(String q) { emit(state.copyWith(query: q, subId: null, filter: const CatalogFilter())); load(); }
}
