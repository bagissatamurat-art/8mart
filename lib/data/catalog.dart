import 'dart:async';

import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../core/api_client.dart';
import '../domain/models.dart';
import 'mock_data.dart';
import 'product_details.dart';

/// Каталог для экранов: категории, карточки товаров, счётчики разделов — с синхронным доступом.
///
/// Без `API_URL` (или с `catalog` в `API_MOCK`) всё берётся из [MockData], как раньше. С бэкендом данные приходят
/// из `GET /categories` и `GET /products…` витрины: сплэш прогревает кеш ([init]), экраны читают его синхронно и
/// перерисовываются по [changes]. Карточки, нужные корзине и избранному, лежат на диске — корзина открывается без сети.
abstract final class Catalog {
  /// Имя в `API_MOCK`.
  static const name = 'catalog';
  static bool get mocked => ApiClient.isMocked(name);

  /// Экраны подписываются, чтобы перерисоваться, когда каталог дозагрузился или обновился.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  /// Кто держит товары (корзина, избранное): их карточки сохраняются на диск первыми. Регистрируют сами кубиты.
  static final _pins = <String, Iterable<String> Function()>{};
  static void pin(String owner, Iterable<String> Function() keys) => _pins[owner] = keys;
  static Iterable<String> get pinned => [for (final keys in _pins.values) ...keys()];

  static const _kCategories = 'catalog.categories', _kProducts = 'catalog.products', _maxStored = 300;

  static List<Category> _categories = const [];
  static List<SubCategory> _subs = const [];
  /// Ответы API как пришли: по ним товар собирается заново, когда меняется дерево категорий.
  static final _raw = <String, Map<String, dynamic>>{};
  static final _products = <String, Product>{};
  static final _variantOwner = <String, String>{};
  static final _details = <String, ProductDetails>{};
  static final _detailsLoading = <String>{};
  /// Первая страница раздела: ключ «категория|подкатегория» → товары и сколько их всего.
  static final _sections = <String, ({List<String> ids, int total})>{};
  static Future<void>? _initializing;
  static bool _loading = false, _failed = false;
  static Timer? _persistTimer;

  /// Категории ещё грузятся (первый запуск без сохранённого каталога).
  static bool get loading => !mocked && _loading && _categories.isEmpty;
  /// Каталог не загрузился и показать нечего — экран предлагает повторить.
  static bool get unavailable => !mocked && _failed && _categories.isEmpty;
  /// Сеть пропала, показываем сохранённое.
  static bool get stale => !mocked && _failed && _categories.isNotEmpty;

  // ── категории ──

  static List<Category> get categories => mocked ? MockData.categories : _categories;
  static List<SubCategory> get subcategories => mocked ? MockData.subcategories : _subs;
  static List<SubCategory> subsOf(String categoryId) => subcategories.where((s) => s.parentId == categoryId).toList();
  static String subName(String id) => subcategories.where((s) => s.id == id).firstOrNull?.name ?? '';
  static Category? category(String id) => categories.where((c) => c.id == id).firstOrNull;

  /// «Часто ищут». С бэкендом списка запросов нет — берём названия разделов, по два из каждой категории:
  /// сервер находит товары и по названию раздела, так что такой запрос пустым не будет.
  static List<String> get popularQueries => mocked
      ? MockData.popularQueries
      : [for (final c in _categories) ...subsOf(c.id).take(2).map((s) => s.name)].take(6).toList();

  /// Сколько товаров в категории / подкатегории; null — ещё не знаем.
  static int? count(String categoryId, [String? subId]) => mocked
      ? MockData.products.where((p) => p.categoryId == categoryId && (subId == null || p.subId == subId)).length
      : _sections[_key(categoryId, subId)]?.total;

  /// Первые товары раздела (полки главной, обложки плиток); null — ещё грузятся.
  static List<Product>? firstOf(String categoryId, [String? subId]) => mocked
      ? MockData.products.where((p) => p.categoryId == categoryId && (subId == null || p.subId == subId)).toList()
      : _sections[_key(categoryId, subId)]?.ids.map(byId).whereType<Product>().toList();

  // ── товары ──

  static Product? byId(String id) {
    if (mocked) return MockData.byId(id);
    return _products[id] ?? _products[_variantOwner[id]];
  }

  /// Позиция корзины: '<id>' или для букета '<id размера>|<цвет>' (как cartItem() в data.js).
  static Product? cartItem(String key) {
    if (mocked) return MockData.cartItem(key);
    final parts = key.split('|');
    final id = parts.first, color = parts.length > 1 ? parts[1] : null;
    final plain = _products[id];
    if (plain != null && !plain.hasVariants) return plain;
    final owner = _products[_variantOwner[id]];
    final v = owner?.variants?.where((x) => x.id == id).firstOrNull;
    return v == null ? null : owner!.asVariant(key, v, color);
  }

  static String cartKey(ProductVariant v, String? color) => color == null ? v.id : '${v.id}|$color';

  /// Описание, характеристики и галерея. С бэкендом до ответа `GET /products/{id}` — фото из списка, без текста.
  static ProductDetails details(Product p) => mocked ? ProductDetailsMock.of(p) : _details[p.id] ?? ProductDetailsMock.pending(p);
  static bool detailsReady(Product p) => mocked || _details.containsKey(p.id);
  /// Подписи заглушек фото — они есть только в моке.
  static List<String> placeholders(Product p) => mocked ? ProductDetailsMock.placeholders(p) : List.filled(details(p).images.length, '');

  /// Запомнить товары из ответа API и вернуть их в форме приложения.
  static List<Product> remember(Iterable<dynamic> json) {
    final out = <Product>[];
    for (final j in json.whereType<Map>()) {
      final m = Map<String, dynamic>.from(j);
      final id = '${m['id']}';
      // В списке нет описания и характеристик — не затираем ими полную карточку.
      _raw[id] = {...?_raw[id], ...m};
      out.add(_map(id));
    }
    _schedulePersist();
    return out;
  }

  static Product _map(String id) {
    final j = _raw[id]!;
    final cat = j['cat'] as String? ?? '';
    final sub = _subs.where((s) => s.id == cat).firstOrNull;
    final p = Product.fromJson(j, categoryId: sub?.parentId ?? cat, subId: sub?.id ?? '');
    _products[id] = p;
    for (final v in p.variants ?? const <ProductVariant>[]) { _variantOwner[v.id] = id; }
    if (j.containsKey('description') || j.containsKey('specs')) _details[id] = ProductDetailsMock.fromJson(p, j);
    return p;
  }

  // ── загрузка ──

  /// До `runApp`: сохранённые категории и карточки — корзина и избранное видны сразу и без сети.
  static void restore() {
    if (mocked) return;
    final store = _store;
    final cats = store?.read(_kCategories);
    if (cats is List) _setCategories(cats);
    final saved = store?.read(_kProducts);
    if (saved is Map) {
      for (final e in saved.entries) { if (e.value is Map) _raw['${e.key}'] = Map<String, dynamic>.from(e.value as Map); }
      _raw.keys.toList().forEach(_map);
    }
  }

  /// Запуск и «потянуть вниз»: дерево категорий, первые страницы разделов (счётчики, полки, обложки), товары корзины и избранного.
  /// Ошибки не бросает: без сети остаётся сохранённое, [unavailable] / [stale] скажут экрану, что показать.
  /// Повторный вызов, пока идёт загрузка, ждёт её же.
  static Future<void> init() {
    if (mocked) return Future.value();
    return _initializing ??= _init().whenComplete(() => _initializing = null);
  }

  static Future<void> _init() async {
    _loading = true;
    changes.value++;
    try {
      final cats = await ApiClient.instance.get<List<dynamic>>('/categories');
      _setCategories(cats);
      unawaited(Future(() => _store?.write(_kCategories, cats)));
      await Future.wait([
        for (final c in _categories) _loadSection(c.id, null),
        for (final s in _subs) _loadSection(s.parentId, s.id),
        ensure(pinned),
      ]);
      _failed = false;
    } catch (_) {
      // Нет сети или ответ не той формы — остаёмся на сохранённом.
      _failed = true;
    } finally {
      _loading = false;
      changes.value++;
    }
  }

  static Future<void> _loadSection(String categoryId, String? subId) async {
    try {
      final r = await ApiClient.instance.get<Map<String, dynamic>>('/products', query: {'category': categoryId, 'sub': subId});
      final items = remember(r['items'] as List? ?? const []);
      _sections[_key(categoryId, subId)] = (ids: [for (final p in items) p.id], total: (r['total'] as num?)?.round() ?? items.length);
    } on ApiError {/* раздел без счётчика и полки — не повод ронять весь каталог */}
  }

  /// Дозагрузить карточки, которых нет в кеше (корзина и избранное после перезапуска, «Повторить заказ»).
  static Future<void> ensure(Iterable<String> keys) async {
    if (mocked) return;
    final ids = {for (final k in keys) k.split('|').first}.where((id) => byId(id) == null).toList();
    if (ids.isEmpty) return;
    try {
      remember(await ApiClient.instance.get<List<dynamic>>('/products', query: {'ids': ids.join(',')}));
      changes.value++;
    } on ApiError {/* покажем то, что есть */}
  }

  /// Карточка по ссылке `/p/:id`: из кеша или с сервера. null — такого товара нет; ApiError — сеть.
  static Future<Product?> fetch(String id) async {
    if (mocked) return MockData.byId(id);
    try {
      final j = await ApiClient.instance.get<Map<String, dynamic>>('/products/${Uri.encodeComponent(id)}');
      final p = remember([j]).first;
      changes.value++;
      return p;
    } on ApiError catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  /// Описание и характеристики для открытой карточки. Повторные вызовы и ошибки сети — без последствий: останется то, что есть.
  static Future<void> loadDetails(Product p) async {
    if (mocked || _details.containsKey(p.id) || !_detailsLoading.add(p.id)) return;
    try {
      await fetch(p.id);
    } on ApiError {/* карточка останется без описания */} finally {
      _detailsLoading.remove(p.id);
    }
  }

  static void _setCategories(List<dynamic> json) {
    final cats = <Category>[], subs = <SubCategory>[];
    for (final c in json.whereType<Map>()) {
      final slug = '${c['slug']}';
      cats.add(Category(id: slug, name: c['name'] as String? ?? '', image: c['img'] as String? ?? ''));
      for (final s in (c['sub'] as List? ?? const []).whereType<Map>()) {
        subs.add(SubCategory('${s['slug']}', s['name'] as String? ?? '', slug));
      }
    }
    _categories = cats;
    _subs = subs;
    // Корень и подкатегория товара зависят от дерева — пересобираем карточки.
    _raw.keys.toList().forEach(_map);
  }

  static String _key(String categoryId, String? subId) => '$categoryId|${subId ?? ''}';

  static Storage? get _store {
    try { return HydratedBloc.storage; } catch (_) { return null; }
  }

  static void _schedulePersist() {
    if (_store == null) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 600), _persist);
  }

  /// На диск: сначала карточки корзины и избранного, затем последние просмотренные — не больше [_maxStored].
  static void _persist() {
    final first = {for (final k in pinned) k.split('|').first}.map((id) => _variantOwner[id] ?? id).where(_raw.containsKey);
    final ids = {...first, ..._raw.keys.toList().reversed}.take(_maxStored);
    _store?.write(_kProducts, {for (final id in ids) id: _raw[id]});
  }

  /// Для тестов: забыть всё загруженное.
  @visibleForTesting
  static void reset() {
    _persistTimer?.cancel();
    _categories = const []; _subs = const [];
    _raw.clear(); _products.clear(); _variantOwner.clear(); _details.clear(); _detailsLoading.clear(); _sections.clear();
    _loading = false; _failed = false; _initializing = null;
    _pins.clear();
  }
}
