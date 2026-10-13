import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mart8/core/api_client.dart';
import 'package:mart8/data/catalog.dart';
import 'package:mart8/data/catalog_repository.dart';
import 'package:mart8/data/places.dart';
import 'package:mart8/domain/models.dart';

http.Response json(int status, Object? body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

/// Ответы витрины в форме прода (урезано).
const _categories = [
  {'slug': 'produkty', 'name': 'Продукты', 'img': 'https://api.test/cat.png', 'sub': [{'slug': 'molochnoe', 'name': 'Молочное'}]},
  {'slug': 'tovary', 'name': 'Товары', 'img': 'https://api.test/goods.png', 'sub': []},
  {'slug': 'tsvety', 'name': 'Цветы', 'sub': [{'slug': 'rozy', 'name': 'Розы'}]},
];
const _milk = {'id': 'milk', 'name': 'Молоко 2,5%, 1 л', 'weight': '1 л', 'pack': '1 л', 'price': 590, 'oldPrice': 690, 'badge': 'Товар дня',
  'cat': 'molochnoe', 'img': 'https://api.test/milk.png', 'delivery': 'express', 'weightKg': 1.0};
const _napkins = {'id': 'napkins', 'name': 'Салфетки', 'weight': '', 'price': null, 'cat': 'tovary', 'delivery': 'express', 'weightKg': 1};
const _bouquet = {'id': 'rose-l', 'name': 'Розы мандала', 'weight': 'S · L', 'price': 9000, 'cat': 'rozy', 'img': 'https://api.test/l.png', 'delivery': 'flowers', 'weightKg': 1,
  'variants': [{'id': 'rose-s', 'size': 'S', 'price': 9000, 'img': 'https://api.test/s.png'}, {'id': 'rose-l', 'size': 'L', 'price': 19000, 'img': 'https://api.test/l.png'}],
  'sizes': ['S', 'L']};

void main() {
  final calls = <Uri>[];
  var down = false;

  setUp(() {
    calls.clear();
    down = false;
    Catalog.reset();
    Places.reset();
    ApiClient.instance = ApiClient(baseUrl: 'https://api.test/store', mocked: '', client: MockClient((r) async {
      calls.add(r.url);
      if (down) throw http.ClientException('offline');
      final q = r.url.queryParameters;
      return switch (r.url.path) {
        '/store/categories' => json(200, _categories),
        '/store/products' when q.containsKey('ids') => json(200, [for (final id in q['ids']!.split(',')) if (id == 'rose-s' || id == 'rose-l') _bouquet else if (id == 'milk') _milk]),
        '/store/products' when q['category'] == 'tsvety' => json(200, {'items': [_bouquet], 'total': 9}),
        '/store/products' when q['category'] == 'produkty' => json(200, {'items': [_milk], 'total': q['sale'] == 'true' ? 1 : 66}),
        '/store/products' => json(200, {'items': [_napkins], 'total': 8}),
        '/store/products/rose-s' || '/store/products/rose-l' => json(200, {..._bouquet, 'description': '', 'specs': [['Размер S', '7 роз'], ['Размер L', '15 роз']], 'images': ['https://api.test/l.png', 'https://api.test/s.png']}),
        '/store/products/milk' => json(200, {..._milk, 'description': 'Пастеризованное.\n\nХранить в холоде.', 'specs': [['Бренд', 'Зенченко']], 'images': ['https://api.test/milk.png']}),
        '/store/search/suggest' => json(200, {'categories': [{'slug': 'molochnoe', 'name': 'Молочное', 'parent': 'Продукты', 'count': 9}, {'slug': 'net', 'name': 'Нет в дереве', 'parent': '?', 'count': 1}], 'products': [_milk], 'total': 8}),
        '/store/cities' => json(200, [{'id': 'astana', 'name': 'Астана', 'lat': 51.1282, 'lng': 71.4307}]),
        '/store/pickup-points' => json(200, [{'id': 'b1', 'city': 'astana', 'name': 'пр. Мангилик Ел, 45кG', 'lat': 51.09, 'lng': 71.42, 'isOpen': true, 'acceptingOrders': false, 'brand': 'ROMANTIC', 'kaspiIntegrated': false}]),
        _ => json(404, {'error': {'code': 404, 'message': 'Товар не найден'}}),
      };
    }));
  });
  tearDown(() => ApiClient.instance = ApiClient(baseUrl: '', mocked: ''));

  group('fromJson', () {
    test('товар: pack из weight, цена null, категория — от вызывающего', () {
      final p = Product.fromJson(Map<String, dynamic>.from(_napkins), categoryId: 'tovary');
      expect((p.id, p.pack, p.price, p.oldPrice, p.image, p.categoryId, p.subId, p.delivery, p.weightKg, p.hasVariants), ('napkins', '', null, null, '', 'tovary', '', DeliveryKind.express, 1.0, false));
      final m = Product.fromJson(Map<String, dynamic>.from(_milk), categoryId: 'produkty', subId: 'molochnoe');
      expect((m.pack, m.price, m.oldPrice, m.badge, m.image), ('1 л', 590, 690, 'Товар дня', 'https://api.test/milk.png'));
    });
    test('букет: варианты со своими id, ценой и фото', () {
      final p = Product.fromJson(Map<String, dynamic>.from(_bouquet));
      expect(p.delivery, DeliveryKind.flowers);
      expect([for (final v in p.variants!) (v.id, v.size, v.price, v.image)], [('rose-s', 'S', 9000, 'https://api.test/s.png'), ('rose-l', 'L', 19000, 'https://api.test/l.png')]);
    });
    test('точка самовывоза: без графика, со статусом и вывеской', () {
      final p = PickupPoint.fromJson({'id': 'b1', 'city': 'astana', 'name': 'ул. Сыганак, 13', 'lat': 51, 'lng': 71.4, 'isOpen': false, 'acceptingOrders': true, 'kaspiIntegrated': true});
      expect((p.id, p.city, p.name, p.hours, p.lat, p.isOpen, p.acceptingOrders, p.kaspiIntegrated, p.brand), ('b1', 'astana', 'ул. Сыганак, 13', '', 51.0, false, true, true, null));
    });
  });

  group('Catalog с бэкендом', () {
    test('init: категории, счётчики и первые товары разделов', () async {
      await Catalog.init();
      expect(Catalog.categories.map((c) => c.id), ['produkty', 'tovary', 'tsvety']);
      expect(Catalog.categories.first.image, 'https://api.test/cat.png');
      expect(Catalog.subsOf('tsvety').single.name, 'Розы');
      expect(Catalog.subName('molochnoe'), 'Молочное');
      expect((Catalog.count('produkty'), Catalog.count('tsvety', 'rozy'), Catalog.count('net')), (66, 9, null));
      expect(Catalog.firstOf('tsvety', 'rozy')!.single.id, 'rose-l');
      expect(Catalog.unavailable, isFalse);
      expect(Catalog.popularQueries, ['Молочное', 'Розы']);
    });
    test('товар раскладывается по корню и подкатегории дерева; в корне подкатегории нет', () async {
      await Catalog.init();
      expect((Catalog.byId('milk')!.categoryId, Catalog.byId('milk')!.subId), ('produkty', 'molochnoe'));
      final r = await const CatalogRepository().page();
      expect((r.items.single.categoryId, r.items.single.subId, r.total), ('tovary', '', 8));
    });
    test('позиция корзины: размер букета находит букет; id размера открывает его же', () async {
      await Catalog.init();
      final s = Catalog.cartItem('rose-s')!;
      expect((s.id, s.name, s.price, s.image, s.variant), ('rose-s', 'Розы мандала, S', 9000, 'https://api.test/s.png', 'S'));
      expect(Catalog.cartItem('rose-l|Белый')!.color, 'Белый');
      expect(Catalog.byId('rose-s')!.id, 'rose-l');
      expect(Catalog.cartItem('milk')!.price, 590);
      expect(Catalog.cartItem('нет'), isNull);
    });
    test('ensure дозагружает недостающее одним запросом ?ids=', () async {
      await Catalog.ensure(['rose-s|Белый', 'milk', 'rose-s']);
      expect(calls.single.queryParameters['ids'], 'rose-s,milk');
      expect(Catalog.cartItem('rose-s|Белый'), isNotNull);
      await Catalog.ensure(['milk', 'rose-s']);
      expect(calls, hasLength(1));
    });
    test('карточка: описание абзацами, характеристики парами; у букета описание — общий текст', () async {
      await Catalog.init();
      final milk = Catalog.byId('milk')!;
      expect(Catalog.detailsReady(milk), isFalse);
      expect(Catalog.details(milk).desc, isEmpty);
      await Catalog.loadDetails(milk);
      final d = Catalog.details(milk);
      expect(d.desc, ['Пастеризованное.', 'Хранить в холоде.']);
      expect(d.specs, [('Бренд', 'Зенченко')]);
      expect(d.images, ['https://api.test/milk.png']);
      final bouquet = await Catalog.fetch('rose-s');
      expect(bouquet!.id, 'rose-l');
      expect(Catalog.details(bouquet).specs, [('Размер S', '7 роз'), ('Размер L', '15 роз')]);
      expect(Catalog.details(bouquet).desc, isNotEmpty);
      expect(await Catalog.fetch('net'), isNull);
    });
    test('нет сети на первом запуске — unavailable, без исключений', () async {
      down = true;
      await Catalog.init();
      expect(Catalog.unavailable, isTrue);
      expect(Catalog.categories, isEmpty);
      down = false;
      await Catalog.init();
      expect((Catalog.unavailable, Catalog.categories.length), (false, 3));
    });
  });

  group('CatalogRepository с бэкендом', () {
    const repo = CatalogRepository();
    test('страница: page с единицы, фильтры и сортировка в запросе', () async {
      await repo.page(categoryId: 'produkty', subId: 'molochnoe', query: ' мол ', sort: SortKind.cheap, filter: const CatalogFilter(min: 100, max: 900, sale: true), page: 2);
      expect(calls.single.queryParameters, {'category': 'produkty', 'sub': 'molochnoe', 'q': 'мол', 'sort': 'cheap', 'page': '3', 'min': '100', 'max': '900', 'sale': 'true'});
      calls.clear();
      await repo.page();
      expect(calls.single.queryParameters, {'page': '1'});
    });
    test('«Показать N» — total первой страницы с теми же фильтрами', () async {
      expect(await repo.count(categoryId: 'produkty', filter: const CatalogFilter(sale: true)), 1);
      expect(calls.single.queryParameters, {'category': 'produkty', 'page': '1', 'sale': 'true'});
    });
    test('подсказки: подкатегория из дерева с названием родителя и счётчиком', () async {
      await Catalog.init();
      final r = await repo.suggest('мол');
      expect([for (final c in r.categories) (c.sub.id, c.sub.parentId, c.parent, c.count)], [('molochnoe', 'produkty', 'Продукты', 9)]);
      expect((r.products.single.id, r.total), ('milk', 8));
    });
    test('запрос уходит на сервер как есть: товары по названию раздела находит он («Часто ищут»)', () async {
      await Catalog.init();
      calls.clear();
      await repo.page(query: ' розы ');
      expect(calls.single.queryParameters, {'q': 'розы', 'page': '1'});
    });
    test('сбой сети — CatalogOffline', () async {
      down = true;
      await expectLater(repo.page(), throwsA(isA<CatalogOffline>()));
      await expectLater(repo.suggest('мол'), throwsA(isA<CatalogOffline>()));
    });
  });

  group('Places', () {
    test('с бэкендом — города и точки из ответа; до ответа и без сети — снимок', () async {
      expect(Places.cities.first.id, 'astana');
      expect(Places.pickupPoints.length, greaterThan(1));
      await Places.refresh();
      expect(Places.cities.single.name, 'Астана');
      expect((Places.pickupPoints.single.brand, Places.pickupPoints.single.acceptingOrders), ('ROMANTIC', false));
      down = true;
      await Places.refresh();
      expect(Places.pickupPoints.single.id, 'b1');
    });
  });

  group('на моке', () {
    setUp(() => ApiClient.instance = ApiClient(baseUrl: '', mocked: ''));
    test('каталог и места — из MockData, без запросов', () async {
      await Catalog.init();
      await Places.refresh();
      expect(calls, isEmpty);
      expect(Catalog.categories.first.id, 'tsvety');
      expect(Catalog.byId('b1')!.name, contains('Цемент'));
      expect(Catalog.count('instrumenty'), 7);
      expect(Catalog.detailsReady(Catalog.byId('b1')!), isTrue);
      expect(Places.cities.length, greaterThan(1));
      expect((await const CatalogRepository().suggest('краск')).total, 2);
    });
    test('API_MOCK=catalog оставляет каталог на моке при заданном адресе', () {
      ApiClient.instance = ApiClient(baseUrl: 'https://api.test/store', mocked: 'catalog');
      expect((Catalog.mocked, Places.mocked), (true, false));
    });
  });
}
