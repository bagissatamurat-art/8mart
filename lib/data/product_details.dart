import '../domain/models.dart';

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
      delivery: WayInfo('Сегодня, за 60–90 минут', '1 000 тг, бесплатно от 20 000 тг'),
      pickup: WayInfo('Через 30 минут', 'В наличии в 6 из 8 точек', 'Храним заказ 24 часа')),
    DeliveryKind.cargo: ProductConditions(tag: 'Тяжёлый товар',
      delivery: WayInfo('Завтра, интервал 9:00–21:00', 'от 3 000 тг — зависит от веса заказа', 'Привезём грузовой машиной. Разгрузка у подъезда, подъём на этаж — 200 тг за единицу за этаж'),
      pickup: WayInfo('Завтра с 9:00', 'Только со склада: ш. Коргалжын, 3', 'Погрузим в машину. Храним заказ 3 дня')),
    DeliveryKind.flowers: ProductConditions(
      delivery: WayInfo('Сегодня, за 60–90 минут', '1 000 тг, бесплатно от 20 000 тг', 'Привезём в коробке с водой, приложим открытку'),
      pickup: WayInfo('Соберём за 40 минут', 'В 4 из 8 точек', 'Храним букет в холодильнике до конца дня')),
  };

  static const _cementDesc = [
    'Портландцемент М400 Д20 — универсальный цемент для большинства строительных работ: приготовления бетона и кладочных растворов, заливки фундаментов, стяжки пола и штукатурки.',
    'Добавка 20% минеральных компонентов повышает водостойкость и снижает риск появления трещин. Подходит для работы при температуре от +5 °C.',
    'Для бетона М200 смешивайте 1 часть цемента, 2,8 части песка и 4,8 части щебня. Готовый раствор используйте в течение 2 часов.',
  ];
  static const _cementSpecs = [('Марка', 'М400 Д20'), ('Фасовка', '50 кг'), ('Назначение', 'Бетон, кладка, стяжка, штукатурка'), ('Время схватывания', 'от 45 минут'),
    ('Температура работы', 'от +5 °C'), ('Хранение', '6 месяцев в сухом помещении'), ('Производитель', 'Central Asia Cement'), ('Страна', 'Казахстан')];

  static const _flowerDesc = ['Букет собираем в день заказа из свежих цветов. Состав может немного отличаться от фото — сохраним стиль и цветовую гамму.',
    'К каждому букету бесплатно прикладываем открытку и подкормку для цветов.'];
  static const _flowerSpecs = [('S', '35 см, 9–11 цветков'), ('M', '45 см, 15–19 цветков'), ('L', '55 см, 25–29 цветков'), ('Упаковка', 'Крафт, атласная лента'),
    ('Стойкость', '5–7 дней'), ('Уход', 'Подрезать стебли, менять воду каждый день')];

  static ProductDetails of(Product p) => p.hasVariants
      ? ProductDetails(images: [...{p.image, ...p.variants!.map((v) => v.image)}, ''], desc: _flowerDesc, specs: _flowerSpecs, conditions: types[p.delivery]!)
      : ProductDetails(
        images: [p.image, '', ''],
        desc: p.id == 'b1' ? _cementDesc : const ['Описание товара появится позже. Уточните детали у поддержки в WhatsApp.'],
        specs: p.id == 'b1' ? _cementSpecs : [('Фасовка', p.pack), ('Производитель', 'Уточняется')],
        conditions: types[p.delivery]!,
      );
  static List<String> placeholders(Product p) => p.hasVariants
      ? [...List.filled(of(p).images.length - 1, ''), 'букет в интерьере']
      : ['', 'фото упаковки', p.isCargo ? 'на поддоне' : 'в работе'];
}
