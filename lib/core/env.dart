/// Ключи и адреса передаются при сборке: flutter run --dart-define-from-file=env.json
/// (env.json в .gitignore, образец — env.example.json). Секретные ключи (DADATA_SECRET, Mapbox sk.*, ключи шлюза) в приложение не кладём никогда.
abstract final class Env {
  /// Адрес бэкенда (https://dukenfy-api.8mart.kz/api/v1/store). Пусто — приложение на моке (lib/data/mock_data.dart) и временных адаптерах.
  static const apiUrl = String.fromEnvironment('API_URL');
  /// Что пока остаётся на моке при заданном API_URL, через запятую: «stories,geo». «*» — всё.
  /// Имена: stories, deliveryQuote, geo, catalog (категории, товары, поиск), places (города, точки самовывоза),
  /// config (настройки приложения), cart (проверка корзины), slots (окна доставки), orders (заказы),
  /// auth (вход через Telegram-бота; с этим именем — вход из макета, код 1234) — см. AGENTS.md.
  static const apiMock = String.fromEnvironment('API_MOCK');
  /// Публичный pk.* Mapbox — карта и запасной геокодинг.
  static const mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  /// TEMP-ADAPTER: DaData из клиента, пока нет GET /geo/suggest и /geo/reverse бэкенда. С бэкендом — убрать.
  static const dadataKey = String.fromEnvironment('DADATA_API_KEY');
}
