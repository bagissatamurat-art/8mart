import '../core/format.dart';
import '../domain/models.dart';
import '../domain/shipments.dart';
import 'flowers.g.dart';

/// Условия получения по типу товара (DELIVERY_TYPES в data.js). МОК — заполняет бизнес; в проде приходит в GET /products/{id} (conditions).
class WayInfo {
  const WayInfo(this.when, this.sub, [this.note]);
  final String when, sub;
  final String? note;
}

class ProductConditions {
  const ProductConditions({this.tag, required this.delivery, required this.pickup});
  final String? tag;
  final WayInfo delivery, pickup;
}

class ProductDetails {
  const ProductDetails({required this.images, required this.desc, required this.specs, required this.conditions});
  /// '' — плейсхолдер «фото упаковки» и т.п. (подпись в [placeholders]).
  final List<String> images;
  final List<String> desc;
  final List<(String, String)> specs;
  final ProductConditions conditions;
}

abstract final class ProductDetailsMock {
  static const types = {
    DeliveryKind.express: ProductConditions(
      delivery: WayInfo('Сегодня, за 30–70 минут', 'от 2 000 тг, бесплатно от 20 000 тг'),
      pickup: WayInfo('Через 30 минут', 'В филиалах 8mart', 'Храним заказ 24 часа')),
    DeliveryKind.cargo: ProductConditions(tag: 'Тяжёлый товар',
      delivery: WayInfo('Завтра, интервал 9:00–21:00', 'от 3 000 тг — зависит от веса заказа', 'Привезём грузовой машиной. Разгрузка у подъезда, подъём на этаж — 200 тг за единицу за этаж'),
      pickup: WayInfo('Завтра с 9:00', 'Только со склада: ш. Коргалжын, 3', 'Погрузим в машину. Храним заказ 3 дня')),
    DeliveryKind.flowers: ProductConditions(
      delivery: WayInfo('Сегодня, за 30–70 минут', 'от 2 000 тг, бесплатно от 20 000 тг', 'Привезём в коробке с водой, приложим открытку'),
      pickup: WayInfo('Соберём за 40 минут', 'В филиалах 8mart', 'Храним букет в холодильнике до конца дня')),
  };

  /// Условия по типу товара. Цена курьера — из тарифов (ShippingConfig.current): порог бесплатной доставки
  /// показываем, только если он есть — с бэкендом его задаёт сервер, и обещать «бесплатно от…» без него нельзя.
  static ProductConditions conditionsOf(DeliveryKind kind) {
    final base = types[kind]!;
    final cfg = ShippingConfig.current;
    if (kind == DeliveryKind.cargo || cfg.freeFrom == const ShippingConfig().freeFrom) return base;
    final price = 'от ${moneyText(cfg.courierFee)}${cfg.hasFreeDelivery ? ', бесплатно от ${moneyText(cfg.freeFrom)}' : ''}';
    return ProductConditions(tag: base.tag, delivery: WayInfo(base.delivery.when, price, base.delivery.note), pickup: base.pickup);
  }

  static const _cementDesc = [
    'Портландцемент М400 Д20 — универсальный цемент для большинства строительных работ: приготовления бетона и кладочных растворов, заливки фундаментов, стяжки пола и штукатурки.',
    'Добавка 20% минеральных компонентов повышает водостойкость и снижает риск появления трещин. Подходит для работы при температуре от +5 °C.',
    'Для бетона М200 смешивайте 1 часть цемента, 2,8 части песка и 4,8 части щебня. Готовый раствор используйте в течение 2 часов.',
  ];
  static const _cementSpecs = [('Марка', 'М400 Д20'), ('Фасовка', '50 кг'), ('Назначение', 'Бетон, кладка, стяжка, штукатурка'), ('Время схватывания', 'от 45 минут'),
    ('Температура работы', 'от +5 °C'), ('Хранение', '6 месяцев в сухом помещении'), ('Производитель', 'Central Asia Cement'), ('Страна', 'Казахстан')];

  static const _flowerDesc = ['Букет собираем в день заказа из свежих цветов. Состав может немного отличаться от фото — сохраним стиль и цветовую гамму.',
    'К каждому букету бесплатно прикладываем открытку и подкормку для цветов.'];
  /// Букет: состав по размерам — из каталога 8mart.kz (flowerComposition), как на сайте.
  static List<(String, String)> _flowerSpecs(Product p) => [for (final (size, c) in flowerComposition[p.id] ?? const <(String, String)>[]) ('Размер $size', c)];

  static const _noDesc = ['Описание товара появится позже. Уточните детали у поддержки в WhatsApp.'];

  /// Карточка из ответа `GET /products/{id}`: описание абзацами, характеристики парами, галерея.
  /// Описания нет (у букетов сервер отдаёт состав в характеристиках) — общий текст по типу товара, как в моке.
  static ProductDetails fromJson(Product p, Map<String, dynamic> j) {
    final desc = (j['description'] as String? ?? '').split(RegExp(r'\r?\n')).map((x) => x.trim()).where((x) => x.isNotEmpty).toList();
    final images = (j['images'] as List? ?? const []).whereType<String>().where((x) => x.isNotEmpty).toList();
    return ProductDetails(
      images: images.isNotEmpty ? images : _gallery(p),
      desc: desc.isNotEmpty ? desc : (p.hasVariants ? _flowerDesc : _noDesc),
      specs: [for (final row in (j['specs'] as List? ?? const []).whereType<List>()) if (row.length >= 2) ('${row[0]}', '${row[1]}')],
      conditions: conditionsOf(p.delivery),
    );
  }

  /// Пока карточка грузится: фото из списка, описания и характеристик ещё нет.
  static ProductDetails pending(Product p) => ProductDetails(images: _gallery(p), desc: const [], specs: const [], conditions: conditionsOf(p.delivery));

  static List<String> _gallery(Product p) => [...{if (p.image.isNotEmpty) p.image, ...?p.variants?.map((v) => v.image).where((x) => x.isNotEmpty)}];

  static ProductDetails of(Product p) => p.hasVariants
      ? ProductDetails(images: [...{p.image, ...p.variants!.map((v) => v.image)}, ''], desc: _flowerDesc, specs: _flowerSpecs(p), conditions: conditionsOf(p.delivery))
      : ProductDetails(
        images: [p.image, '', ''],
        desc: p.id == 'b1' ? _cementDesc : _noDesc,
        specs: p.id == 'b1' ? _cementSpecs : [('Фасовка', p.pack), ('Производитель', 'Уточняется')],
        conditions: conditionsOf(p.delivery),
      );
  static List<String> placeholders(Product p) => p.hasVariants
      ? [...List.filled(of(p).images.length - 1, ''), 'букет в интерьере']
      : ['', 'фото упаковки', p.isCargo ? 'на поддоне' : 'в работе'];
}
