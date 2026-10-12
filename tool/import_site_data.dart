// Импорт настоящих данных 8mart.kz → lib/data/flowers.g.dart и lib/data/branches.g.dart (мок в форме API-контракта).
// Тот же источник и та же логика, что у сайта (8mart-site: scripts/import-flowers.mjs, lib/branches.ts):
//  · букеты — со всех филиалов; размеры S/M/L — варианты одного букета, у каждого своя цена и фото;
//    цена размера — самая частая по филиалам (опечатки вроде 27 398 не попадут); состав — из описания товара;
//  · филиалы — города, точки самовывоза (адрес, координаты, вывеска, открыт/принимает заказы, Kaspi).
// Запуск: dart run tool/import_site_data.dart   (перезаписывает *.g.dart; руками их не править).
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const api = 'https://dukenfy-api.8mart.kz/api/v1';
const files = 'https://dukenfy-api.8mart.kz';
const flowersCategory = 'c0a7e0e0-0000-4000-8000-000000000003'; // «Цветы»
const subs = {'b4170724-6f6d-428d-89c9-b03e2679ea16': 'gortenzii', '50997070-0f27-49a7-93f5-8a4d3cb1478c': 'rozy', 'b7c0b473-c64e-4cd9-ae15-e9179d98379c': 'hrizantemy'};
const sizes = ['S', 'M', 'L'];

/// Стабильные id букетов и вариантов — те же, что на сайте (корзина, избранное, ссылки /p/:id).
const known = {
  'РОЗЫ МАНДАЛА': ('f1', 'Розы Мандала', {'S': 'f1-s', 'M': 'f2', 'L': 'f1'}),
  'КУСТОВЫЕ РОЗЫ В БУКЕТЕ': ('f3', 'Кустовые розы в букете', {'S': 'f3-s', 'M': 'f3-m', 'L': 'f3'}),
  'ГОРТЕНЗИЯ С ХРИЗАНТЕМАМИ': ('f4', 'Гортензия с хризантемами', {'S': 'f4-s', 'M': 'f4', 'L': 'f4-l'}),
  'ФРАНЦУЗСКИЕ РОЗЫ МАНДАЛА С ГОРТЕНЗИЕЙ': ('f5', 'Французские розы Мандала с гортензией', {'S': 'f5-s', 'M': 'f5-m', 'L': 'f5'}),
  'РОЗА МИКС': ('f6', 'Роза микс', {'S': 'f6-s', 'M': 'f6', 'L': 'f6-l'}),
  'ГОРТЕНЗИЯ С КУСТОВЫМИ РОЗАМИ': ('f7', 'Гортензия с кустовыми розами', {'S': 'f7-s', 'M': 'f7-m', 'L': 'f7'}),
  'ХРИЗАНТЕМА МОМОКО С РОЗАМИ МАНДАЛА': ('f8', 'Хризантема Момоко с розами Мандала', {'S': 'f8-s', 'M': 'f8-m', 'L': 'f8'}),
  'ХРИЗАНТЕМА С КУСТОВЫМИ РОЗАМИ': ('f9', 'Хризантема с кустовыми розами', {'S': 'f9-s', 'M': 'f9', 'L': 'f9-l'}),
  'ХРИЗАНТЕМА': ('f10', 'Хризантема', {'S': 'f10-s', 'M': 'f10-m', 'L': 'f10'}),
};

/// Город из API → id, название, центр карты (без координат — среднее по филиалам города).
const cityMap = {
  'Астана': ('astana', 'Астана', 51.1282, 71.4307),
  'Актобе': ('aktobe', 'Актобе', 50.2839, 57.167),
  'Кокшетау Г.А.': ('kokshetau', 'Кокшетау', 53.2833, 69.3964),
  'Костанай': ('kostanay', 'Костанай', 53.2144, 63.6246),
  'Уральск': ('uralsk', 'Уральск', 51.2333, 51.3667),
};

Future<dynamic> getJson(String url) async {
  final r = await http.get(Uri.parse(url));
  if (r.statusCode != 200) throw Exception('API ${r.statusCode}: $url');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

String sentence(String t) => t.isEmpty ? t : t[0] + t.substring(1).toLowerCase();
String q(String s) => "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

/// Самое частое значение (при равенстве — большее).
int mode(List<int> xs) {
  final m = <int, int>{};
  for (final x in xs) { m[x] = (m[x] ?? 0) + 1; }
  final e = m.entries.toList()..sort((a, b) => b.value != a.value ? b.value - a.value : b.key - a.key);
  return e.first.key;
}

/// «проспект Абылай Хана 32» → «пр. Абылай хана, 32» (как shortAddress на сайте).
String shortAddress(String a) => a.trim()
    .replaceFirst(RegExp(r'^проспект\s+', caseSensitive: false), 'пр. ')
    .replaceFirst(RegExp(r'^улица\s+', caseSensitive: false), 'ул. ')
    .replaceFirst(RegExp(r'^шоссе\s+', caseSensitive: false), 'ш. ')
    .replaceFirst(RegExp(r'^микрорайон\s+', caseSensitive: false), 'мкр. ')
    .replaceAllMapped(RegExp(r'\s+Хана(?=[\s,]|$)', unicode: true), (_) => ' хана')
    .replaceAllMapped(RegExp(r'\s+(\d[\p{L}\d/-]*)$', unicode: true), (m) => ', ${m[1]}');

Future<void> main() async {
  final branches = (await getJson('$api/public/branches') as List).cast<Map<String, dynamic>>();
  final date = DateTime.now().toIso8601String().substring(0, 10);

  // ── Букеты ──
  final groups = <String, Map<String, dynamic>>{};
  for (final b in branches) {
    final res = await getJson('$api/categories/$flowersCategory/products?branchId=${b['id']}&includeDescendants=true&page=0&size=200');
    for (final p in (res['products'] as List).cast<Map<String, dynamic>>()) {
      if (p['price'] == null) continue;
      final title = (p['title'] as String).trim();
      final m = RegExp(r'^(.*?)\s+([SML])$').firstMatch(title);
      final base = m != null ? m[1]!.trim() : title, size = m != null ? m[2]! : 'M';
      final g = groups.putIfAbsent(base, () => {'cat': subs[p['categoryId']] ?? 'rozy', 'items': <String, Map<String, dynamic>>{}});
      final lines = '${p['description'] ?? ''}'.split(RegExp(r'\r?\n')).map((s) => s.trim().replaceFirst(RegExp(r'\s+;?$'), '')).where((s) => s.isNotEmpty).toList();
      final composition = lines.join(' ').toUpperCase() == base ? '' : lines.join(', ').replaceAll(RegExp(r'\s+,'), ',');
      final items = g['items'] as Map<String, Map<String, dynamic>>;
      final it = items.putIfAbsent(size, () => {'prices': <int>[], 'img': '$files${p['image']}', 'composition': composition, 'sourceId': p['id']});
      (it['prices'] as List<int>).add((p['price'] as num).round());
      if ((it['composition'] as String).isEmpty && composition.isNotEmpty) it['composition'] = composition;
    }
  }
  final out = StringBuffer()
    ..writeln('// Сгенерировано tool/import_site_data.dart — НЕ ПРАВИТЬ РУКАМИ, перезапустить скрипт.')
    ..writeln('// Источник: каталог 8mart.kz ($api), все филиалы (${branches.length}), цена — самая частая по филиалам, $date.')
    ..writeln("import '../domain/models.dart';")
    ..writeln()
    ..writeln('const flowersSource = (api: ${q(api)}, branches: ${branches.length}, date: ${q(date)});')
    ..writeln()
    ..writeln('/// Букеты: размеры S/M/L — варианты (своя цена и фото); у товара — цена и фото самого маленького / большого размера.')
    ..writeln('const flowerProducts = [');
  final comp = StringBuffer('/// Состав букета по размерам (из описания товара в каталоге).\nconst flowerComposition = <String, List<(String, String)>>{\n');
  final rows = <(String, String)>[];
  for (final e in groups.entries) {
    final items = e.value['items'] as Map<String, Map<String, dynamic>>;
    final k = known[e.key];
    final present = sizes.where(items.containsKey).toList();
    final id = k?.$1 ?? 'f-${(items[present.first]!['sourceId'] as String).substring(0, 8)}';
    final variants = present.map((s) => (id: k?.$3[s] ?? '$id-${s.toLowerCase()}', size: s, price: mode(items[s]!['prices'] as List<int>), img: items[s]!['img'] as String)).toList();
    final largest = items[present.last]!;
    final name = k?.$2 ?? sentence(e.key);
    final v = variants.map((x) => 'ProductVariant(${q(x.id)}, ${q(x.size)}, ${x.price}, ${q(x.img)})').join(', ');
    final minPrice = variants.map((x) => x.price).reduce((a, b) => a < b ? a : b);
    rows.add(('${e.value['cat']}$name', '  Product(id: ${q(id)}, name: ${q(name)}, pack: ${q(present.join(' · '))}, price: $minPrice, image: ${q(largest['img'] as String)}, '
        'delivery: DeliveryKind.flowers, weightKg: 1, categoryId: \'tsvety\', subId: ${q(e.value['cat'] as String)},\n      variants: [$v]),'));
    final cs = present.where((s) => (items[s]!['composition'] as String).isNotEmpty).map((s) => '(${q(s)}, ${q(items[s]!['composition'] as String)})').join(', ');
    comp.writeln('  ${q(id)}: [$cs],');
  }
  rows.sort((a, b) => a.$1.compareTo(b.$1));
  for (final r in rows) { out.writeln(r.$2); }
  out..writeln('];')..writeln()..write(comp)..writeln('};');
  File('lib/data/flowers.g.dart').writeAsStringSync(out.toString());
  stdout.writeln('flowers: ${rows.length} букетов → lib/data/flowers.g.dart');

  // ── Филиалы ──
  final cities = <String, String>{};
  final cityOrder = <String>[];
  for (final b in branches) {
    final raw = b['city'] as String;
    final c = cityMap[raw];
    final id = c?.$1 ?? raw.toLowerCase();
    if (cities.containsKey(id)) continue;
    final own = branches.where((x) => x['city'] == raw).toList();
    final lat = c?.$3 ?? own.map((x) => (x['latitude'] as num).toDouble()).reduce((a, b) => a + b) / own.length;
    final lng = c?.$4 ?? own.map((x) => (x['longitude'] as num).toDouble()).reduce((a, b) => a + b) / own.length;
    cities[id] = 'City(${q(id)}, ${q(c?.$2 ?? raw.replaceFirst(RegExp(r'\s+Г\.А\.$'), ''))}, $lat, $lng)';
    cityOrder.add(id);
  }
  cityOrder.sort((a, b) => a == 'astana' ? -1 : b == 'astana' ? 1 : a.compareTo(b));
  final br = StringBuffer()
    ..writeln('// Сгенерировано tool/import_site_data.dart — НЕ ПРАВИТЬ РУКАМИ, перезапустить скрипт.')
    ..writeln('// Источник: $api/public/branches, $date. В проде — GET /cities и GET /pickup-points?city (живой статус).')
    ..writeln("import '../domain/models.dart';")
    ..writeln()
    ..writeln('/// Города с филиалами: Астана первой, остальные по алфавиту.')
    ..writeln('const branchCities = [')
    ..writeln(cityOrder.map((id) => '  ${cities[id]},').join('\n'))
    ..writeln('];')
    ..writeln()
    ..writeln('/// Филиалы — точки самовывоза. Графика работы в API нет: статус — живые isOpen / acceptingOrders.')
    ..writeln('const branchPoints = [');
  for (final b in branches) {
    final brand = (b['name'] as String).split(RegExp(r'\s+-\s+')).first.trim();
    final raw = b['city'] as String;
    br.writeln('  PickupPoint(${q(b['id'] as String)}, ${q(cityMap[raw]?.$1 ?? raw.toLowerCase())}, ${q(shortAddress(b['address'] as String))}, \'\', '
        '${b['latitude']}, ${b['longitude']}, isOpen: ${b['isOpen']}, acceptingOrders: ${b['isAcceptingOrders']}, kaspiIntegrated: ${b['kaspiIntegrated'] ?? false}'
        '${brand.toUpperCase() != '8MART' ? ', brand: ${q(brand)}' : ''}),');
  }
  br.writeln('];');
  File('lib/data/branches.g.dart').writeAsStringSync(br.toString());
  stdout.writeln('branches: ${branches.length} филиалов, ${cityOrder.length} городов → lib/data/branches.g.dart');
}
