import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mart8/core/api_client.dart';
import 'package:mart8/data/catalog.dart';
import 'package:mart8/data/places.dart';
import 'package:mart8/data/remote_config.dart';

http.Response json(int status, Object? body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

const _categories = [{'slug': 'tsvety', 'name': 'Цветы', 'sub': [{'slug': 'rozy', 'name': 'Розы'}]}];
const _bouquet = {'id': 'rose-l', 'name': 'Розы мандала', 'weight': 'S · L', 'price': 9000, 'cat': 'rozy', 'img': 'https://api.test/l.png', 'delivery': 'flowers', 'weightKg': 1,
  'variants': [{'id': 'rose-s', 'size': 'S', 'price': 9000, 'img': 'https://api.test/s.png'}, {'id': 'rose-l', 'size': 'L', 'price': 19000, 'img': 'https://api.test/l.png'}],
  'sizes': ['S', 'L']};

/// Второй запуск: всё, что приложение сохранило на диск в первый, читается до первого кадра (main.dart).
/// Hive отдаёт вложенные объекты как Map<dynamic, dynamic> — разбор не должен на этом падать, иначе runApp не вызовется
/// и приложение покажет белый экран.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('mart8-restore');
    Catalog.reset();
    Places.reset();
    RemoteConfig.debugSet(null);
    ApiClient.instance = ApiClient(baseUrl: 'https://api.test/store', mocked: '', client: MockClient((r) async => switch (r.url.path) {
      '/store/categories' => json(200, _categories),
      '/store/products' => json(200, {'items': [_bouquet], 'total': 1}),
      '/store/cities' => json(200, [{'id': 'astana', 'name': 'Астана', 'lat': 51.1282, 'lng': 71.4307}]),
      '/store/pickup-points' => json(200, [{'id': 'b1', 'city': 'astana', 'name': 'Сыганак 13', 'lat': 51.09, 'lng': 71.42}]),
      '/store/app/config' => json(200, {'auth': ['code'], 'support': {'phone': '+77001339071'}, 'delivery': {}}),
      _ => json(404, {'error': {'code': 404, 'message': 'Not found'}}),
    }));
  });
  tearDown(() async {
    ApiClient.instance = ApiClient(baseUrl: '', mocked: '');
    await HydratedBloc.storage.close();
    await dir.delete(recursive: true);
  });

  test('букеты с размерами, филиалы и настройки с прошлого запуска читаются без ошибок', () async {
    // Первый запуск: каталог, филиалы и настройки с сервера, сохранение на диск.
    HydratedBloc.storage = await HydratedStorage.build(storageDirectory: dir);
    await Catalog.init();
    await Places.refresh();
    await RemoteConfig.refresh();
    expect(Catalog.byId('rose-l')?.variants?.length, 2);
    await Future<void>.delayed(const Duration(milliseconds: 700)); // карточки уходят на диск с задержкой
    await HydratedBloc.storage.close();

    // Второй запуск: та же папка, память пустая.
    Catalog.reset();
    Places.reset();
    RemoteConfig.debugSet(null);
    HydratedBloc.storage = await HydratedStorage.build(storageDirectory: dir);
    Catalog.restore();
    Places.restore();
    RemoteConfig.restore();

    expect(Catalog.byId('rose-l')?.variants?.map((v) => v.size), ['S', 'L']);
    expect(Places.cities.map((c) => c.name), ['Астана']);
    expect(RemoteConfig.codeLogin, isTrue);
  });
}
