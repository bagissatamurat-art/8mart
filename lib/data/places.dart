import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../core/api_client.dart';
import '../domain/models.dart';
import 'mock_data.dart';

/// Города и точки самовывоза для выбора способа получения — с синхронным доступом.
///
/// Без `API_URL` (или с `places` в `API_MOCK`) — снимок филиалов из [MockData] (lib/data/branches.g.dart).
/// С бэкендом — `GET /cities` и `GET /pickup-points` (живой статус «открыто / принимает заказы»); последний ответ
/// хранится на диске, а пока ответа нет вовсе — тот же снимок, чтобы экран выбора не был пустым.
abstract final class Places {
  /// Имя в `API_MOCK`.
  static const name = 'places';
  static bool get mocked => ApiClient.isMocked(name);

  /// Экран выбора подписывается, чтобы обновить список и пины, когда пришёл свежий статус.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static const _kCities = 'places.cities', _kPoints = 'places.points';
  static List<City>? _cities;
  static List<PickupPoint>? _points;
  static bool _loading = false;

  static List<City> get cities => mocked ? MockData.cities : _cities ?? MockData.cities;
  static List<PickupPoint> get pickupPoints => mocked ? MockData.pickupPoints : _points ?? MockData.pickupPoints;

  /// До `runApp`: последний сохранённый ответ.
  static void restore() {
    if (mocked) return;
    final store = _store;
    _set(store?.read(_kCities), store?.read(_kPoints));
  }

  /// Сплэш и открытие экрана выбора: свежие города и статусы филиалов. Без сети остаётся прежнее.
  static Future<void> refresh() async {
    if (mocked || _loading) return;
    _loading = true;
    try {
      final r = await Future.wait([
        ApiClient.instance.get<List<dynamic>>('/cities'),
        ApiClient.instance.get<List<dynamic>>('/pickup-points'),
      ]);
      if (_set(r[0], r[1])) {
        final store = _store;
        store?.write(_kCities, r[0]);
        store?.write(_kPoints, r[1]);
        changes.value++;
      }
    } catch (_) {
      // Нет сети или ответ не той формы — показываем прежнее.
    } finally {
      _loading = false;
    }
  }

  /// false — данные не той формы или городов нет: оставляем то, что было.
  static bool _set(Object? cities, Object? points) {
    if (cities is! List || points is! List) return false;
    try {
      final cs = [for (final c in cities.whereType<Map>()) City.fromJson(Map<String, dynamic>.from(c))];
      final ps = [for (final p in points.whereType<Map>()) PickupPoint.fromJson(Map<String, dynamic>.from(p))];
      if (cs.isEmpty) return false;
      _cities = cs;
      _points = ps;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Storage? get _store {
    try { return HydratedBloc.storage; } catch (_) { return null; }
  }

  /// Для тестов: забыть загруженное.
  @visibleForTesting
  static void reset() { _cities = null; _points = null; _loading = false; }
}
