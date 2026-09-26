import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/env.dart';
import '../domain/models.dart';

class AddressSuggestion {
  const AddressSuggestion({required this.title, required this.sub, this.lat, this.lng, this.needHouse = false});
  final String title, sub;
  final double? lat, lng;
  /// Улица без дома → в поле «Улица, » и курсор остаётся для номера.
  final bool needHouse;
}

class GeoUnavailable implements Exception {}

/// Порт geo.js: DaData suggest/geolocate + запасной Mapbox Geocoding v6.
/// ⚠ Прототип зовёт DaData из клиента. В проде заменить на GET /geo/suggest?q&city и GET /geo/reverse?lat&lng (формы ответа те же).
class GeoRepository {
  const GeoRepository();
  static const _dd = 'https://suggestions.dadata.ru/suggestions/api/4_1/rs';

  Future<List<Map<String, dynamic>>> _dadata(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$_dd/$path'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Token ${Env.dadataKey}'}, body: jsonEncode(body));
    if (r.statusCode != 200) throw GeoUnavailable();
    return ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['suggestions'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<(double, double)?> _mapboxForward(String q, City c) async {
    final r = await http.get(Uri.parse('https://api.mapbox.com/search/geocode/v6/forward?q=${Uri.encodeComponent(q)}&country=kz&language=ru&limit=1&proximity=${c.lng},${c.lat}&access_token=${Env.mapboxToken}'));
    final f = ((jsonDecode(r.body) as Map)['features'] as List? ?? []).firstOrNull as Map?;
    if (f == null) return null;
    final xy = (f['geometry'] as Map)['coordinates'] as List;
    return ((xy[1] as num).toDouble(), (xy[0] as num).toDouble());
  }

  /// Подсказки «Улица, дом» в пределах города, до 6.
  Future<List<AddressSuggestion>> suggest(String q, City city) async {
    final list = await _dadata('suggest/address', {'query': q, 'count': 10, 'locations': [{'country_iso_code': 'KZ', 'city': city.name}], 'restrict_value': true, 'language': 'ru'});
    final out = <AddressSuggestion>[];
    final seen = <String>{};
    for (final s in list) {
      final d = (s['data'] as Map?) ?? {};
      final street = (d['street_with_type'] ?? d['street'] ?? '') as String;
      final house = [d['house'], if (d['block'] != null) '${d['block_type'] ?? 'корп.'} ${d['block']}'].whereType<String>().join(' ');
      final title = street.isNotEmpty ? street + (house.isNotEmpty ? ', $house' : '') : ((d['settlement_with_type'] ?? s['value'] ?? '') as String);
      final sub = [d['city_district_with_type'] ?? d['city_district'], d['city'] ?? city.name].whereType<String>().join(' · ');
      if (title.isEmpty || !seen.add('$title|$sub')) continue;
      var lat = double.tryParse('${d['geo_lat'] ?? ''}'), lng = double.tryParse('${d['geo_lon'] ?? ''}');
      if (lat == null) {
        final g = await _mapboxForward('${city.name}, $title', city).catchError((_) => null);
        if (g != null) { lat = g.$1; lng = g.$2; }
      }
      out.add(AddressSuggestion(title: title, sub: sub, lat: lat, lng: lng, needHouse: street.isNotEmpty && d['house'] == null));
      if (out.length == 6) break;
    }
    return out;
  }

  /// Адрес по пину → «улица, дом». DaData geolocate, если пусто — Mapbox reverse.
  Future<String> reverse(double lat, double lng) async {
    try {
      final s = (await _dadata('geolocate/address', {'lat': lat, 'lon': lng, 'count': 1, 'radius_meters': 100, 'language': 'ru'})).firstOrNull;
      final d = s?['data'] as Map?;
      if (d != null && (d['street'] != null || d['house'] != null)) return [d['street_with_type'] ?? d['street'], d['house']].whereType<String>().join(', ');
    } catch (_) {/* падаем на Mapbox */}
    final r = await http.get(Uri.parse('https://api.mapbox.com/search/geocode/v6/reverse?longitude=$lng&latitude=$lat&language=ru&types=address,street&limit=1&access_token=${Env.mapboxToken}'));
    final f = ((jsonDecode(utf8.decode(r.bodyBytes)) as Map)['features'] as List? ?? []).firstOrNull as Map?;
    if (f == null) return '';
    final p = (f['properties'] as Map?) ?? {};
    final ctx = (p['context'] as Map?) ?? {};
    if (p['feature_type'] == 'address') {
      final v = [(ctx['street'] as Map?)?['name'], (ctx['address'] as Map?)?['address_number']].whereType<String>().join(', ');
      if (v.isNotEmpty) return v;
    }
    return (p['name'] as String?) ?? '';
  }
}
