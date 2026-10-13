import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'env.dart';

/// Ошибка API: status (0 — нет сети) и сообщение сервера из {error:{message}} | {message}.
class ApiError implements Exception {
  const ApiError(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => 'ApiError($status, $message)';
}

/// HTTP-клиент к бэкенду 8mart и переключатель «мок / настоящий API» — как lib/http.ts сайта.
///
///   API_URL  — адрес API. Пусто — все репозитории на моке.
///   API_MOCK — имена, которые пока остаются на моке («stories,geo»; «*» — все). Так бэкенд подключается по одному эндпоинту.
///
/// Репозиторий: `if (ApiClient.isMocked('stories')) return мок; return ApiClient.instance.get('/stories')`.
/// Токен: AuthCubit после входа вызывает ApiClient.instance.token = () => accessToken.
class ApiClient {
  ApiClient({String? baseUrl, String? mocked, http.Client? client})
      : baseUrl = (baseUrl ?? Env.apiUrl).replaceFirst(RegExp(r'/$'), ''),
        _mocked = (mocked ?? Env.apiMock).split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet(),
        _http = client ?? http.Client();

  static ApiClient instance = ApiClient();

  /// Имя отвечает моком: API не задан, оно в API_MOCK или там «*».
  static bool isMocked(String name) => instance.mocked(name);

  final String baseUrl;
  final Set<String> _mocked;
  final http.Client _http;
  /// Источник accessToken (Bearer). null — запрос без авторизации.
  String? Function() token = () => null;
  Duration timeout = const Duration(seconds: 15);

  bool mocked(String name) => baseUrl.isEmpty || _mocked.contains('*') || _mocked.contains(name);

  /// Параметры: списки — повтором ключа (?colors=a&colors=b), null / '' / false — не пишем.
  Uri uri(String path, [Map<String, Object?> query = const {}]) {
    final pairs = <String>[];
    query.forEach((k, v) {
      if (v == null || v == '' || v == false) return;
      for (final x in v is Iterable ? v : [v]) {
        pairs.add('${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent('$x')}');
      }
    });
    return Uri.parse('$baseUrl$path${pairs.isEmpty ? '' : '?${pairs.join('&')}'}');
  }

  Future<T> get<T>(String path, {Map<String, Object?> query = const {}}) => send<T>('GET', path, query: query);
  Future<T> post<T>(String path, {Object? body}) => send<T>('POST', path, body: body);
  Future<T> put<T>(String path, {Object? body}) => send<T>('PUT', path, body: body);
  Future<T> patch<T>(String path, {Object? body}) => send<T>('PATCH', path, body: body);
  Future<T> delete<T>(String path) => send<T>('DELETE', path);

  /// JSON туда и обратно. Ответ — декодированный JSON (Map / List), 204 — null. Ошибка — ApiError.
  Future<T> send<T>(String method, String path, {Map<String, Object?> query = const {}, Object? body}) async {
    final req = http.Request(method, uri(path, query))..headers['Accept'] = 'application/json';
    final t = token();
    if (t != null && t.isNotEmpty) req.headers['Authorization'] = 'Bearer $t';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }
    final http.Response r;
    try {
      r = await http.Response.fromStream(await _http.send(req).timeout(timeout));
    } on TimeoutException {
      throw const ApiError(0, 'Сервер не отвечает');
    } catch (_) {
      throw const ApiError(0, 'Нет связи с сервером');
    }
    if (r.statusCode == 204 || r.bodyBytes.isEmpty) {
      if (r.statusCode >= 400) throw ApiError(r.statusCode, r.reasonPhrase ?? 'Ошибка сервера');
      return null as T;
    }
    Object? data;
    try { data = jsonDecode(utf8.decode(r.bodyBytes)); } catch (_) {}
    if (r.statusCode >= 400) {
      final m = data is Map ? ((data['error'] is Map ? (data['error'] as Map)['message'] : null) ?? data['message']) : null;
      throw ApiError(r.statusCode, '${m ?? r.reasonPhrase ?? 'Ошибка сервера'}');
    }
    return data as T;
  }
}
