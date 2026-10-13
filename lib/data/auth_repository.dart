import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api_client.dart';

/// Покупатель — `User` бэкенда: телефон уже в виде «+7 (700) 133-90-71».
class AuthUser {
  const AuthUser({required this.id, required this.phone, this.name = ''});
  final String id, phone, name;

  factory AuthUser.fromJson(Map<String, dynamic> j) =>
      AuthUser(id: '${j['id'] ?? ''}', phone: j['phone'] as String? ?? '', name: j['name'] as String? ?? '');
  Map<String, dynamic> toJson() => {'id': id, 'phone': phone, 'name': name};
  AuthUser withName(String name) => AuthUser(id: id, phone: phone, name: name);
}

/// Где лежит сессия между запусками. В приложении — Keychain / Keystore; в тестах — память.
abstract interface class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  const SecureSessionStore();
  static const _key = 'auth.session';
  // first_unlock: сессия читается и при запуске из фона (push), а на другой телефон с резервной копией не переезжает.
  static const _storage = FlutterSecureStorage(iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device));
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class MemorySessionStore implements SessionStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

/// Сессия покупателя: токен и профиль. Читается один раз до `runApp` ([restore]) и дальше доступна синхронно —
/// как [Catalog] и [RemoteConfig]. Токен уходит в каждый запрос ([ApiClient.token]); ответ 401 сессию закрывает.
abstract final class AuthSession {
  /// Имя в `API_MOCK`: с ним вход остаётся на моке (код 1234).
  static const name = 'auth';
  static bool get mocked => ApiClient.isMocked(name);

  static SessionStore store = const SecureSessionStore();
  static String? _token;
  static AuthUser? _user;
  static String? get token => _token;
  static AuthUser? get user => _user;

  /// Меняется при входе, выходе и когда сервер сообщил, что сессия закончилась.
  static final changes = ValueNotifier<int>(0);

  static void _attach() {
    ApiClient.instance.token = () => _token;
    ApiClient.instance.onUnauthorized = expire;
  }

  /// До `runApp`: сохранённая сессия. Хранилище недоступно или запись испорчена — считаем, что входа нет.
  static Future<void> restore() async {
    if (mocked) return;
    _attach();
    try {
      final saved = await store.read();
      if (saved == null) return;
      final j = jsonDecode(saved) as Map<String, dynamic>;
      final token = j['token'] as String?;
      if (token == null || token.isEmpty) return;
      _token = token;
      _user = AuthUser.fromJson((j['user'] as Map).cast<String, dynamic>());
    } catch (_) {
      _token = null;
      _user = null;
    }
  }

  static Future<void> save(String token, AuthUser user) async {
    _token = token;
    _user = user;
    _attach();
    changes.value++;
    try { await store.write(jsonEncode({'token': token, 'user': user.toJson()})); } catch (_) {}
  }

  static Future<void> updateUser(AuthUser user) async {
    final token = _token;
    if (token == null) return;
    _user = user;
    try { await store.write(jsonEncode({'token': token, 'user': user.toJson()})); } catch (_) {}
  }

  static Future<void> clear() async {
    if (_token == null && _user == null) return;
    _token = null;
    _user = null;
    changes.value++;
    try { await store.clear(); } catch (_) {}
  }

  /// Сервер ответил 401 на запрос с токеном: вход закончился (вышли на другом устройстве, аккаунт удалён, истёк срок).
  static void expire() { clear(); }

  @visibleForTesting
  static void debugReset({SessionStore? store}) {
    _token = null;
    _user = null;
    AuthSession.store = store ?? MemorySessionStore();
  }
}

/// Ход входа через Telegram-бота.
sealed class TgStatus { const TgStatus(); }
class TgPending extends TgStatus { const TgPending(); }
/// Ссылка устарела или уже использована — нужна новая.
class TgExpired extends TgStatus { const TgExpired(); }
class TgOk extends TgStatus {
  const TgOk(this.accessToken, this.user);
  final String accessToken;
  final AuthUser user;
}

/// Вход и профиль покупателя (имя для API_MOCK — «auth»). Вход — только через Telegram-бота:
/// `POST /auth/tg` → ссылка на бота → покупатель делится номером → `GET /auth/tg/{token}` отдаёт сессию.
class AuthRepository {
  const AuthRepository();
  static bool get mocked => AuthSession.mocked;

  Future<({String token, String url})> startTelegram() async {
    final j = await ApiClient.instance.post<Map<String, dynamic>>('/auth/tg');
    return (token: '${j['token']}', url: '${j['url']}');
  }

  Future<TgStatus> telegramStatus(String token) async {
    final j = await ApiClient.instance.get<Map<String, dynamic>>('/auth/tg/${Uri.encodeComponent(token)}');
    switch (j['status']) {
      case 'pending': return const TgPending();
      case 'ok':
        final access = (j['tokens'] as Map?)?['accessToken'] as String?;
        final user = j['user'] as Map?;
        if (access == null || access.isEmpty || user == null) return const TgExpired();
        return TgOk(access, AuthUser.fromJson(user.cast<String, dynamic>()));
      default: return const TgExpired();
    }
  }

  Future<AuthUser> me() async => AuthUser.fromJson(await ApiClient.instance.get<Map<String, dynamic>>('/me'));

  Future<AuthUser> rename(String name) async =>
      AuthUser.fromJson(await ApiClient.instance.patch<Map<String, dynamic>>('/me', body: {'name': name}));

  Future<void> logout() => ApiClient.instance.post<Object?>('/auth/logout');

  Future<void> deleteAccount() => ApiClient.instance.delete<Object?>('/me');
}
