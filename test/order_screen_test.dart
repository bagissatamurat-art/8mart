import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mart8/app.dart';
import 'package:mart8/core/api_client.dart';
import 'package:mart8/ui/widgets/mart_image.dart';

class _MemStorage implements Storage {
  final _m = <String, dynamic>{};
  @override
  dynamic read(String key) => _m[key];
  @override
  Future<void> write(String key, dynamic value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
  @override
  Future<void> clear() async => _m.clear();
  @override
  Future<void> close() async {}
}

http.Response _json(int status, Object? body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

/// Заказ в форме витрины (урезано).
Map<String, Object?> _order(String id, String number) => {
  'id': id, 'number': number, 'date': '13 октября, 15:27', 'method': 'pickup', 'status': 'accepted', 'address': 'пр. Абылай хана, 32', 'payment': 'kaspi',
  'items': [{'id': 'milk', 'qty': 1, 'name': 'Молоко', 'price': 590}],
  'shipments': [{'kind': 'courier', 'status': 'accepted', 'times': ['15:27']}],
  'total': 590, 'goods': 590, 'fees': <Object>[], 'recipient': {'name': 'Айгерим', 'phone': '+77001339071'}, 'paid': true,
};

void main() {
  setUp(() {
    HydratedBloc.storage = _MemStorage();
    MartImage.offline = true;
    ApiClient.instance = ApiClient(baseUrl: 'https://api.test/store', mocked: '', client: MockClient((r) async => switch (r.url.path) {
      '/store/orders/uuid-1' => _json(200, _order('uuid-1', '118')),
      '/store/orders/uuid-2' => _json(200, _order('uuid-2', '119')),
      '/store/products' => _json(200, <Object>[]),
      _ => _json(404, {'error': {'code': 404, 'message': 'Not found'}}),
    }));
  });
  tearDown(() { ApiClient.instance = ApiClient(baseUrl: '', mocked: ''); MartImage.offline = false; });

  testWidgets('экран статуса: тот же экран, другой заказ — показывает новый, а не прежний', (tester) async {
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }
    // Ссылка из push или возврат из оплаты, когда статус другого заказа уже открыт: маршрут тот же, меняется только id.
    Future<void> open(String id) async {
      GoRouter.of(tester.element(find.byType(Scaffold).last)).go('/order/$id');
      await settle();
    }

    await tester.pumpWidget(const MartApp(initialLocation: '/order/uuid-1'));
    await settle();
    expect(find.textContaining('№118'), findsOneWidget);
    expect(find.textContaining('+7 700 133 90 71'), findsOneWidget);

    await open('uuid-2');
    expect(find.textContaining('№119'), findsOneWidget);
    expect(find.textContaining('№118'), findsNothing);

    await open('unknown');
    expect(find.text('Заказ не найден'), findsOneWidget);

    // Экран закрыт — опрос статуса остановлен, таймеров не осталось.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 16));
  });
}
