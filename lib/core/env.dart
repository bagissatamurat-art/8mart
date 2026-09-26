/// Ключи передаются при сборке: flutter run --dart-define-from-file=env.json (env.json в .gitignore, образец — env.example.json).
/// DADATA_SECRET_KEY в приложение не кладём никогда.
abstract final class Env {
  static const mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  /// Только прототип: DaData из клиента. В проде — GET /geo/suggest и /geo/reverse на бэкенде, этот ключ убрать.
  static const dadataKey = String.fromEnvironment('DADATA_API_KEY');
}
