import '../domain/models.dart';
import 'mock_data.dart';

/// МОК GET /products. В проде — HTTP + кеш ответов (офлайн).
class CatalogRepository {
  const CatalogRepository();
  static const pageSize = 8;
  /// Переключатель для демо состояния «нет сети».
  static bool offline = false;

  static bool matches(Product p, String q) {
    final s = q.toLowerCase().trim();
    return s.isEmpty || p.name.toLowerCase().contains(s) || MockData.subName(p.subId).toLowerCase().contains(s);
  }

  List<Product> _all({String? categoryId, String? subId, String? query, SortKind sort = SortKind.popular, CatalogFilter filter = const CatalogFilter()}) {
    final list = MockData.products.where((p) =>
        (categoryId == null || p.categoryId == categoryId) && (subId == null || p.subId == subId) && (query == null || matches(p, query)) && filter.accepts(p)).toList();
    switch (sort) {
      case SortKind.popular: break; // порядок из API
      case SortKind.cheap: list.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
      case SortKind.expensive: list.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
      case SortKind.sale: list.sort((a, b) => (b.oldPrice != null ? 1 : 0).compareTo(a.oldPrice != null ? 1 : 0));
      case SortKind.bonus: list.sort((a, b) => b.bonus.compareTo(a.bonus));
    }
    return list;
  }

  /// Сколько товаров покажем с этими фильтрами — для кнопки «Показать N» (в проде — GET /products/count).
  int count({String? categoryId, String? subId, String? query, CatalogFilter filter = const CatalogFilter()}) =>
      _all(categoryId: categoryId, subId: subId, query: query, filter: filter).length;

  Future<({List<Product> items, int total})> page({String? categoryId, String? subId, String? query, SortKind sort = SortKind.popular, CatalogFilter filter = const CatalogFilter(), int page = 0}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (offline) throw const CatalogOffline();
    final all = _all(categoryId: categoryId, subId: subId, query: query, sort: sort, filter: filter);
    return (items: all.skip(page * pageSize).take(pageSize).toList(), total: all.length);
  }
}

class CatalogOffline implements Exception {
  const CatalogOffline();
}
