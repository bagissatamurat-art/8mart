import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../core/api_client.dart';
import '../domain/shipments.dart';
import 'mock_data.dart';

/// Настройки с сервера — `GET /app/config`: контакты поддержки, способы оплаты, порог бесплатной доставки,
/// включённые функции. Синхронный доступ; последний ответ хранится на диске.
///
/// Без `API_URL` (или с `config` в `API_MOCK`) — значения мока, как раньше. С бэкендом функции, которых на
/// сервере нет (бонусы, промокоды), выключены, пока сервер не скажет обратное: показывать их с выдуманными
/// числами нельзя.
abstract final class RemoteConfig {
  /// Имя в `API_MOCK`.
  static const name = 'config';
  static bool get mocked => ApiClient.isMocked(name);

  /// Экраны с контактами и тарифами перерисовываются, когда пришёл свежий ответ.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static const _kConfig = 'remote.config';
  /// Контакты до первого ответа сервера — те же, что в футере 8mart.kz.
  static const _fallbackWa = '77001339071', _fallbackPhone = '+77001339071';
  static Map<String, dynamic> _j = const {};
  static bool _loading = false;

  static Map<String, dynamic> _map(String key) => (_j[key] as Map?)?.cast<String, dynamic>() ?? const {};
  static String? _text(Map<String, dynamic> m, String key) {
    final v = m[key];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  /// WhatsApp поддержки — цифры для wa.me.
  static String get supportWa => mocked ? MockData.supportWa : _text(_map('support'), 'whatsapp') ?? _fallbackWa;
  /// Телефон поддержки для показа: «+7 700 133 90 71».
  static String get supportPhone => mocked ? MockData.supportPhone : prettyPhone(_text(_map('support'), 'phone') ?? _fallbackPhone);
  /// Telegram-бот входа; null — входа через Telegram нет.
  static String? get telegramBot => mocked ? MockData.tgBot : _text(_map('support'), 'telegramBot');
  static String? tgLink(String token) => switch (telegramBot) { final bot? => 'https://t.me/$bot?start=$token', _ => null };

  /// Оплата картой доступна (платёжный шлюз включён на сервере).
  static bool get cardPayment => mocked || ((_j['payments'] as List?)?.contains('card') ?? true);
  /// Промокоды и бонусы: на моке — как в макетах; с бэкендом — только если сервер их включил.
  static bool get promo => mocked || _map('features')['promo'] == true;
  static bool get bonus => mocked || _map('features')['bonus'] == true;

  /// Сумма товаров, от которой доставка курьером бесплатна; null — такого правила нет, платится стоимость зоны.
  static int? get freeFrom => mocked ? const ShippingConfig().freeFrom : (_map('delivery')['freeFrom'] as num?)?.round();

  static String? get appStoreUrl => mocked ? null : _text(_map('stores'), 'appStore');
  static String? get googlePlayUrl => mocked ? null : _text(_map('stores'), 'googlePlay');
  static String? get minVersion => mocked ? null : _text(_j, 'minVersion');

  /// «+77001339071» → «+7 700 133 90 71»; номер другого вида — как есть.
  static String prettyPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11 || !d.startsWith('7')) return raw;
    return '+7 ${d.substring(1, 4)} ${d.substring(4, 7)} ${d.substring(7, 9)} ${d.substring(9)}';
  }

  /// До `runApp`: последний сохранённый ответ.
  static void restore() {
    if (mocked) return;
    final saved = _store?.read(_kConfig);
    if (saved is Map) _apply(Map<String, dynamic>.from(saved));
  }

  /// Запуск приложения: свежие настройки. Без сети остаются прежние.
  static Future<void> refresh() async {
    if (mocked || _loading) return;
    _loading = true;
    try {
      final j = await ApiClient.instance.get<Map<String, dynamic>>('/app/config');
      _apply(j);
      _store?.write(_kConfig, j);
      changes.value++;
    } catch (_) {
      // Нет сети или ответ не той формы — работаем с прежними настройками.
    } finally {
      _loading = false;
    }
  }

  static void _apply(Map<String, dynamic> j) {
    _j = j;
    // Тарифы — в одном месте: порог бесплатной доставки доезжает до ShippingConfig.
    ShippingConfig.remoteFreeFrom = (freeFrom, known: true);
  }

  static Storage? get _store {
    try { return HydratedBloc.storage; } catch (_) { return null; }
  }

  /// Для тестов: подставить ответ сервера / забыть его.
  @visibleForTesting
  static void debugSet(Map<String, dynamic>? j) {
    if (j == null) { _j = const {}; ShippingConfig.remoteFreeFrom = (null, known: false); } else { _apply(j); }
  }
}
