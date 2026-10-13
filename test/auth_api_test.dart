import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mart8/app.dart';
import 'package:mart8/core/api_client.dart';
import 'package:mart8/data/auth_repository.dart';
import 'package:mart8/data/order_repository.dart';
import 'package:mart8/state/auth_cubit.dart';
import 'package:mart8/ui/widgets/mart_code_input.dart';
import 'package:mart8/ui/widgets/mart_image.dart';

http.Response json(int status, Object? body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

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

const _user = {'id': 'c1', 'name': 'Айгерим', 'phone': '+7 (700) 133-90-71', 'since': 'октябрь 2026'};

void main() {
  final calls = <http.Request>[];
  final store = MemorySessionStore();
  /// Что бот уже сделал: pending → ok. expired — ссылка устарела.
  var tg = 'pending';
  var startStatus = 200;
  var sessionAlive = true;
  var patchFails = false;
  var links = 0;

  void useApi() {
    ApiClient.instance = ApiClient(baseUrl: 'https://api.test/store', mocked: '', client: MockClient((r) async {
      calls.add(r);
      final authed = r.headers['Authorization'] == 'Bearer access-1';
      switch ((r.method, r.url.path)) {
        case ('POST', '/store/auth/tg'):
          if (startStatus != 200) return json(startStatus, {'error': {'code': startStatus, 'message': 'Вход через Telegram сейчас недоступен'}});
          links++;
          return json(200, {'token': 'tok-$links', 'url': 'https://t.me/mart8_bot?start=tok-$links', 'expiresIn': 600});
        case ('GET', final p) when p.startsWith('/store/auth/tg/'):
          return json(200, switch (tg) {
            'ok' => {'status': 'ok', 'phone': _user['phone'], 'tokens': {'accessToken': 'access-1'}, 'user': _user},
            'expired' => {'status': 'expired'},
            _ => {'status': 'pending'},
          });
        case ('GET', '/store/me'):
          return authed && sessionAlive ? json(200, {..._user, 'name': 'Айгерим Н.'}) : json(401, {'error': {'code': 401, 'message': 'Войдите, чтобы продолжить'}});
        case ('PATCH', '/store/me'):
          if (patchFails) throw http.ClientException('offline');
          return json(200, {..._user, 'name': jsonDecode(r.body)['name']});
        case ('POST', '/store/auth/logout'): return json(200, {'ok': true});
        case ('DELETE', '/store/me'): return authed ? json(200, {'ok': true}) : json(401, {'error': {'code': 401, 'message': 'Войдите, чтобы продолжить'}});
        case ('GET', '/store/orders'): return json(200, <Object>[]);
        default: return json(404, {'error': {'code': 404, 'message': 'Not found'}});
      }
    }));
  }

  setUp(() {
    calls.clear();
    store.value = null;
    tg = 'pending';
    startStatus = 200;
    sessionAlive = true;
    patchFails = false;
    links = 0;
    AuthSession.debugReset(store: store);
    useApi();
  });
  tearDown(() { ApiClient.instance = ApiClient(baseUrl: '', mocked: ''); AuthSession.debugReset(); });

  group('вход через Telegram-бота', () {
    test('ссылка на бота → ждём → бот подтвердил номер → сессия', () async {
      final cubit = AuthCubit();
      expect(cubit.state.authed, isFalse);

      await cubit.startTelegram();
      expect((cubit.state.step, cubit.state.tgToken, cubit.state.tgUrl), (AuthStep.telegram, 'tok-1', 'https://t.me/mart8_bot?start=tok-1'));

      // Покупатель ещё в боте.
      await cubit.checkTelegram();
      expect((cubit.state.step, cubit.state.tgOk, AuthSession.token), (AuthStep.telegram, false, null));

      tg = 'ok';
      await cubit.checkTelegram();
      expect((cubit.state.step, cubit.state.phone, cubit.state.name), (AuthStep.done, '+7 (700) 133-90-71', 'Айгерим'));
      // Сессия сохранена и уходит в каждый следующий запрос.
      expect(AuthSession.token, 'access-1');
      expect(jsonDecode(store.value!)['token'], 'access-1');
      await const OrderRepository().list(const []);
      expect((calls.last.url.path, calls.last.headers['Authorization']), ('/store/orders', 'Bearer access-1'));
      await cubit.close();
    });

    test('ссылка устарела — просим новую', () async {
      final cubit = AuthCubit();
      await cubit.startTelegram();
      tg = 'expired';
      await cubit.checkTelegram();
      expect((cubit.state.step, cubit.state.tgExpired, cubit.state.authed), (AuthStep.telegram, true, false));

      tg = 'pending';
      await cubit.startTelegram();
      expect((cubit.state.tgToken, cubit.state.tgExpired), ('tok-2', false));
      await cubit.close();
    });

    test('вход недоступен — текст сервера и «Повторить»', () async {
      startStatus = 503;
      final cubit = AuthCubit();
      await cubit.startTelegram();
      expect((cubit.state.step, cubit.state.error, cubit.state.tgUrl), (AuthStep.telegram, 'Вход через Telegram сейчас недоступен', ''));

      startStatus = 200;
      await cubit.startTelegram();
      expect((cubit.state.error, cubit.state.tgToken), (null, 'tok-1'));
      cubit.back();
      expect(cubit.state.step, AuthStep.phone);
      await cubit.close();
    });

    test('номер из ссылки возврата не принимается: вход подтверждает только сервер', () async {
      final cubit = AuthCubit();
      await cubit.startTelegram();
      await cubit.telegramConfirmed('tok-1', '+7 (700) 000-00-00');
      expect((cubit.state.authed, cubit.state.phone), (false, ''));
      await cubit.close();
    });
  });

  group('сессия', () {
    Future<void> signedIn() async {
      store.value = jsonEncode({'token': 'access-1', 'user': _user});
      await AuthSession.restore();
    }

    test('переживает перезапуск; профиль сверяется с сервером', () async {
      await signedIn();
      final cubit = AuthCubit();
      expect((cubit.state.authed, cubit.state.phone, cubit.state.name), (true, '+7 (700) 133-90-71', 'Айгерим'));

      await cubit.refreshProfile();
      expect(cubit.state.name, 'Айгерим Н.');
      expect(AuthSession.user?.name, 'Айгерим Н.');
      await cubit.close();
    });

    test('сервер закрыл сессию (401) — приложение выходит из аккаунта', () async {
      await signedIn();
      final cubit = AuthCubit();
      sessionAlive = false;

      await cubit.refreshProfile();
      await Future<void>.delayed(Duration.zero);

      expect((cubit.state.authed, AuthSession.token, store.value), (false, null, null));
      await cubit.close();
    });

    test('испорченная запись — входа нет, приложение запускается', () async {
      store.value = '{не json';
      await AuthSession.restore();
      expect(AuthSession.token, isNull);
      expect(AuthCubit().state.authed, isFalse);
    });

    test('имя: сохраняется на сервере, при сбое возвращается прежнее', () async {
      await signedIn();
      final cubit = AuthCubit();
      expect(await cubit.rename('  Айгерим С. '), isTrue);
      expect((cubit.state.name, AuthSession.user?.name), ('Айгерим С.', 'Айгерим С.'));

      patchFails = true;
      expect(await cubit.rename('Другое'), isFalse);
      expect(cubit.state.name, 'Айгерим С.');
      await cubit.close();
    });

    test('выход закрывает сессию на сервере и стирает токен; без сети — всё равно выходим', () async {
      await signedIn();
      final cubit = AuthCubit();
      await cubit.logout();
      final call = calls.lastWhere((r) => r.url.path == '/store/auth/logout');
      expect(call.headers['Authorization'], 'Bearer access-1');
      expect((cubit.state.authed, AuthSession.token, store.value), (false, null, null));
      await cubit.close();
    });

    test('удаление аккаунта: успех — выход; отказ — остаёмся в аккаунте', () async {
      await signedIn();
      final cubit = AuthCubit();
      await cubit.deleteAccount();
      expect((cubit.state.authed, AuthSession.token), (false, null));

      // Без токена сервер откажет — аккаунт на месте, ошибка доходит до экрана.
      await expectLater(cubit.deleteAccount(), throwsA(isA<ApiError>()));
      await cubit.close();
    });
  });

  test('мок-режим не изменился: телефон → код 1234', () async {
    ApiClient.instance = ApiClient(baseUrl: '', mocked: '');
    final cubit = AuthCubit();
    await cubit.sendCode('+7 (700) 133-90-71');
    await cubit.verify('0000');
    expect(cubit.state.code, CodeState.error);
    await cubit.verify('1234');
    expect((cubit.state.authed, cubit.state.phone), (true, '+7 (700) 133-90-71'));
    expect(await cubit.rename('Айгерим'), isTrue);
    await cubit.logout();
    expect(cubit.state.authed, isFalse);
    await cubit.close();
  });

  testWidgets('экран входа с бэкендом: только Telegram, без телефона и кода', (tester) async {
    HydratedBloc.storage = _MemStorage();
    MartImage.offline = true;
    addTearDown(() => MartImage.offline = false);
    Future<void> settle() async {
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    await tester.pumpWidget(const MartApp(initialLocation: '/profile'));
    await settle();
    expect(find.text('Войти через Telegram'), findsOneWidget);
    expect(find.text('Получить код в WhatsApp'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Войти через Telegram'));
    await settle();
    expect(find.text('Открыть Telegram'), findsOneWidget);
    expect(find.text('Нажмите «Поделиться номером»'), findsOneWidget);
    // Кода из WhatsApp с бэкендом нет — вернуться можно только назад.
    expect(find.text('Войти по коду в WhatsApp'), findsNothing);
    expect(find.text('Назад'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
