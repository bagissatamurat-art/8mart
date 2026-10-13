import '../core/api_client.dart';
import '../domain/models.dart';
import 'catalog.dart';
import 'mock_data.dart';

/// Подсказки поиска: подкатегории по названию (с названием родителя и числом товаров) и первые товары.
typedef SearchSuggest = ({List<({SubCategory sub, String parent, int count})> categories, List<Product> products, int total});

/// Списки товаров. С бэкендом — `GET /products?category&sub&q&sort&page&min&max&sale` и `GET /search/suggest?q` витрины
/// (имя для API_MOCK — «catalog», общее с [Catalog]); без него — выборка из [MockData].
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

  /// page — с нуля (в API — с единицы).
  Future<Map<String, dynamic>> _fetch({String? categoryId, String? subId, String? query, SortKind sort = SortKind.popular, CatalogFilter filter = const CatalogFilter(), int page = 0}) async {
    try {
      return await ApiClient.instance.get<Map<String, dynamic>>('/products', query: {
        'category': categoryId, 'sub': subId, 'q': query?.trim(), 'sort': sort == SortKind.popular ? null : sort.name,
        'page': page + 1, 'min': filter.min, 'max': filter.max, 'sale': filter.sale,
      });
    } on ApiError {
      // Экран списка знает одно состояние сбоя — «нет сети» с кнопкой «Повторить».
      throw const CatalogOffline();
    }
  }

  /// Сколько товаров покажем с этими фильтрами — для кнопки «Показать N»: total первой страницы.
  Future<int> count({String? categoryId, String? subId, String? query, CatalogFilter filter = const CatalogFilter()}) async {
    if (Catalog.mocked) return _all(categoryId: categoryId, subId: subId, query: query, filter: filter).length;
    final r = await _fetch(categoryId: categoryId, subId: subId, query: query, filter: filter);
    Catalog.remember(r['items'] as List? ?? const []);
    return (r['total'] as num?)?.round() ?? 0;
  }

  Future<({List<Product> items, int total})> page({String? categoryId, String? subId, String? query, SortKind sort = SortKind.popular, CatalogFilter filter = const CatalogFilter(), int page = 0}) async {
    if (!Catalog.mocked) {
      final r = await _fetch(categoryId: categoryId, subId: subId, query: query, sort: sort, filter: filter, page: page);
      final items = Catalog.remember(r['items'] as List? ?? const []);
      return (items: items, total: (r['total'] as num?)?.round() ?? items.length);
    }
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (offline) throw const CatalogOffline();
    final all = _all(categoryId: categoryId, subId: subId, query: query, sort: sort, filter: filter);
    return (items: all.skip(page * pageSize).take(pageSize).toList(), total: all.length);
  }

  /// Подсказки по мере ввода. Мок считает сразу; с бэкендом — `GET /search/suggest?q` (ошибка сети — CatalogOffline).
  SearchSuggest suggestMock(String query) {
    final s = query.toLowerCase().trim();
    final hits = MockData.products.where((p) => matches(p, query)).toList();
    return (
      categories: [
        for (final sc in MockData.subcategories.where((x) => x.name.toLowerCase().contains(s)).take(2))
          (sub: sc, parent: MockData.category(sc.parentId)?.name ?? '', count: MockData.products.where((p) => p.subId == sc.id).length),
      ],
      products: hits.take(5).toList(),
      total: hits.length,
    );
  }

  Future<SearchSuggest> suggest(String query) async {
    if (Catalog.mocked) return suggestMock(query);
    final Map<String, dynamic> r;
    try {
      r = await ApiClient.instance.get<Map<String, dynamic>>('/search/suggest', query: {'q': query.trim()});
    } on ApiError {
      throw const CatalogOffline();
    }
    return (
      categories: [
        for (final c in (r['categories'] as List? ?? const []).whereType<Map>().take(2))
          // Переход ведёт в /catalog/<корень>?sub=<подкатегория> — корень берём из дерева; раздела нет в дереве — не показываем.
          if (Catalog.subcategories.where((s) => s.id == c['slug']).firstOrNull case final sub?)
            (sub: sub, parent: c['parent'] as String? ?? '', count: (c['count'] as num?)?.round() ?? 0),
      ],
      products: Catalog.remember(r['products'] as List? ?? const []).take(5).toList(),
      total: (r['total'] as num?)?.round() ?? 0,
    );
  }
}

class CatalogOffline implements Exception {
  const CatalogOffline();
}
