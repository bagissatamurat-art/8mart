import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/models.dart';

/// Ответ зоны доставки: доставляем (quote) / адрес вне зон / сервис недоступен (показываем общие условия).
sealed class QuoteResult {
  const QuoteResult();
}

class QuoteOk extends QuoteResult {
  const QuoteOk(this.quote);
  final DeliveryQuote quote;
}

class QuoteOutside extends QuoteResult {
  const QuoteOutside();
}

class QuoteUnavailable extends QuoteResult {
  const QuoteUnavailable();
}

/// Зоны доставки 8mart.kz: GET /public/branches/resolve-delivery?lat&lng → филиал, зона, стоимость и время курьера.
/// ⚠ Временный адаптер к публичному API 8mart.kz (как GeoRepository к DaData). В проде — эндпоинт бэкенда (GET /delivery/quote?lat&lng), формы те же.
class DeliveryRepository {
  const DeliveryRepository();
  static const _api = 'https://dukenfy-api.8mart.kz/api/v1/public/branches/resolve-delivery';

  /// Ответы за сессию по округлённым координатам (~10 м): двигать пин туда-сюда — без повторных запросов.
  static final _cache = <String, QuoteResult>{};

  Future<QuoteResult> quote(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final r = await http.get(Uri.parse('$_api?lat=${lat.toStringAsFixed(4)}&lng=${lng.toStringAsFixed(4)}')).timeout(const Duration(seconds: 6));
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode == 400 && body is Map && '${(body['error'] as Map?)?['message']}'.toLowerCase().contains('outside')) {
        return _cache[key] = const QuoteOutside();
      }
      if (r.statusCode != 200 || body is! Map) return const QuoteUnavailable();
      return _cache[key] = QuoteOk(DeliveryQuote(
        fee: (body['deliveryCost'] as num).round(), eta: (body['deliveryTimeMinutes'] as num).round(),
        branchName: '${body['branchName'] ?? ''}'.replaceFirst(RegExp(r'\s+-\s+'), ', '), zone: '${body['zoneName'] ?? ''}',
        kaspiIntegrated: body['kaspiIntegrated'] == true,
      ));
    } catch (_) {
      return const QuoteUnavailable();
    }
  }
}
