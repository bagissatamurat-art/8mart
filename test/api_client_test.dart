import 'dart:convert';

import 'package:mart8/core/api_client.dart';
import 'package:mart8/data/story_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(int status, Object? body) =>
    http.Response.bytes(body == null ? const [] : utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

void main() {
  group('переключатель мок / API', () {
    test('без API_URL — всё на моке', () {
      final c = ApiClient(baseUrl: '', mocked: '');
      expect(c.mocked('stories'), isTrue);
    });
    test('с адресом — API, кроме перечисленных в API_MOCK; «*» — все', () {
      final c = ApiClient(baseUrl: 'https://api.test/v1/', mocked: 'stories, geo');
      expect(c.baseUrl, 'https://api.test/v1');
      expect(c.mocked('deliveryQuote'), isFalse);
      expect(c.mocked('stories'), isTrue);
      expect(c.mocked('geo'), isTrue);
      expect(ApiClient(baseUrl: 'https://api.test', mocked: '*').mocked('deliveryQuote'), isTrue);
    });
  });

  group('send', () {
    test('query, JSON-тело и Bearer-токен', () async {
      late http.Request seen;
      final c = ApiClient(baseUrl: 'https://api.test', mocked: '', client: MockClient((r) async { seen = r; return json(200, {'id': '8M-1'}); }))
        ..token = () => 'tok';
      final r = await c.send<Map<String, dynamic>>('POST', '/orders', query: {'colors': ['Белый', 'Розовый'], 'page': 2, 'sale': false, 'q': ''}, body: {'a': 1});
      expect(r['id'], '8M-1');
      expect(seen.url.toString(), 'https://api.test/orders?colors=%D0%91%D0%B5%D0%BB%D1%8B%D0%B9&colors=%D0%A0%D0%BE%D0%B7%D0%BE%D0%B2%D1%8B%D0%B9&page=2');
      expect(seen.method, 'POST');
      expect(seen.body, '{"a":1}');
      expect(seen.headers['Authorization'], 'Bearer tok');
    });
    test('ошибка — ApiError со статусом и сообщением сервера', () async {
      final c = ApiClient(baseUrl: 'https://api.test', mocked: '', client: MockClient((_) async => json(409, {'error': {'message': 'Корзина изменилась'}})));
      expect(() => c.post('/orders', body: {}), throwsA(isA<ApiError>().having((e) => e.status, 'status', 409).having((e) => e.message, 'message', 'Корзина изменилась')));
    });
    test('нет сети — ApiError(0); 204 — null', () async {
      final down = ApiClient(baseUrl: 'https://api.test', mocked: '', client: MockClient((_) async => throw http.ClientException('offline')));
      expect(() => down.get('/me'), throwsA(isA<ApiError>().having((e) => e.status, 'status', 0)));
      final ok = ApiClient(baseUrl: 'https://api.test', mocked: '', client: MockClient((_) async => http.Response('', 204)));
      expect(await ok.delete<Object?>('/me'), isNull);
    });
  });

  test('сторис в форме сайта → модель приложения', () {
    final s = StoryRepository.storyFromJson({
      'id': 's1', 'title': 'Розы', 'cover': 'https://x/c.jpg',
      'slides': [{'img': 'https://x/1.jpg', 'title': 'Букет', 'text': 'от 9 900 тг', 'cta': {'label': 'Выбрать', 'href': '/p/f1'}}, {'img': 'https://x/v.jpg', 'video': 'https://x/v.mp4', 'duration': 12.4}],
    });
    expect(s.slides.length, 2);
    expect(s.slides.first.ctaPath, '/p/f1');
    expect(s.slides.last.duration, 12);
  });
}
