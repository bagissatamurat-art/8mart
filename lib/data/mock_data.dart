import '../domain/models.dart';
import 'branches.g.dart';
import 'flowers.g.dart';

/// МОК вместо API. Формы объектов сохранить, данные заменить на ответы бэкенда.
abstract final class MockData {
  static const categories = [
    // Основной товар — цветы (букеты 8mart.kz); остальные категории — вторичные, без акцента.
    Category(id: 'tsvety', name: 'Цветы', image: 'assets/images/cat-flowers.png'),
    Category(id: 'stroymaterialy', name: 'Стройматериалы', image: 'assets/images/cat-build.png'),
    Category(id: 'instrumenty', name: 'Инструменты', image: 'assets/images/cat-tools.png'),
    Category(id: 'dlya-doma', name: 'Для дома', image: 'assets/images/cat-home.png'),
    Category(id: 'podarki', name: 'Подарки', image: 'assets/images/cat-goods.png'),
  ];

  static const subcategories = [
    SubCategory('sukhie-smesi', 'Сухие смеси', 'stroymaterialy'), SubCategory('kirpich-i-bloki', 'Кирпич и блоки', 'stroymaterialy'),
    SubCategory('gipsokarton', 'Гипсокартон', 'stroymaterialy'), SubCategory('kraski', 'Краски', 'stroymaterialy'),
    SubCategory('uteplitel', 'Утеплитель', 'stroymaterialy'), SubCategory('plitka', 'Плитка', 'stroymaterialy'),
    SubCategory('ruchnoy', 'Ручной инструмент', 'instrumenty'), SubCategory('elektro', 'Электроинструмент', 'instrumenty'), SubCategory('krepezh', 'Крепёж', 'instrumenty'),
    SubCategory('hoztovary', 'Хозтовары', 'dlya-doma'), SubCategory('svet', 'Освещение', 'dlya-doma'), SubCategory('santehnika', 'Сантехника', 'dlya-doma'),
    SubCategory('upakovka', 'Упаковка', 'podarki'), SubCategory('otkrytki', 'Открытки', 'podarki'), SubCategory('shary', 'Шары', 'podarki'),
    SubCategory('gortenzii', 'Гортензии', 'tsvety'), SubCategory('rozy', 'Розы', 'tsvety'), SubCategory('hrizantemy', 'Хризантемы', 'tsvety'),
  ];
  static List<SubCategory> subsOf(String categoryId) => subcategories.where((s) => s.parentId == categoryId).toList();
  static String subName(String id) => subcategories.where((s) => s.id == id).firstOrNull?.name ?? '';
  static Category? category(String id) => categories.where((c) => c.id == id).firstOrNull;

  static const _i = 'assets/images/';
  static const products = [
    Product(id: 'b1', name: 'Цемент М400, 50 кг', pack: '50 кг', price: 2890, oldPrice: 3290, badge: 'Товар дня', image: '${_i}b-cement.png', bonus: 87, delivery: DeliveryKind.cargo, weightKg: 50, categoryId: 'stroymaterialy', subId: 'sukhie-smesi'),
    Product(id: 'b8', name: 'Цемент М500 Д0, 50 кг', pack: '50 кг', price: 3190, image: '${_i}b-cement.png', bonus: 64, delivery: DeliveryKind.cargo, weightKg: 50, categoryId: 'stroymaterialy', subId: 'sukhie-smesi'),
    Product(id: 'b6', name: 'Клей для плитки, 25 кг', pack: '25 кг', price: 2190, oldPrice: 2490, image: '${_i}b-glue.png', bonus: 45, weightKg: 25, categoryId: 'stroymaterialy', subId: 'sukhie-smesi'),
    Product(id: 'b11', name: 'Штукатурка гипсовая, 30 кг', pack: '30 кг', price: 2890, image: '${_i}b-glue.png', bonus: 58, delivery: DeliveryKind.cargo, weightKg: 30, categoryId: 'stroymaterialy', subId: 'sukhie-smesi'),
    Product(id: 'b2', name: 'Кирпич керамический рядовой М150', pack: '1 шт', price: 145, image: '${_i}b-brick.png', delivery: DeliveryKind.cargo, weightKg: 2.5, categoryId: 'stroymaterialy', subId: 'kirpich-i-bloki'),
    Product(id: 'b3', name: 'Гипсокартон стеновой 12,5 мм, 2500×1200', pack: '1 лист', price: 3490, oldPrice: 3890, image: '${_i}b-drywall.png', bonus: 70, delivery: DeliveryKind.cargo, weightKg: 25, categoryId: 'stroymaterialy', subId: 'gipsokarton'),
    Product(id: 'b4', name: 'Краска интерьерная белая, 10 л', pack: '10 л', price: 12900, oldPrice: 14500, badge: 'Хит', image: '${_i}b-paint.png', bonus: 390, weightKg: 14, categoryId: 'stroymaterialy', subId: 'kraski'),
    Product(id: 'b12', name: 'Краска фасадная белая, 10 л', pack: '10 л', price: 14900, image: '${_i}b-paint.png', bonus: 450, weightKg: 14, categoryId: 'stroymaterialy', subId: 'kraski'),
    Product(id: 'b5', name: 'Утеплитель минеральная вата, 50 мм, рулон', pack: '12 м²', price: 8400, image: '${_i}b-wool.png', bonus: 250, delivery: DeliveryKind.cargo, weightKg: 10, categoryId: 'stroymaterialy', subId: 'uteplitel'),
    Product(id: 'b7', name: 'Плитка керамогранит серый 60×60', pack: '1,44 м²', price: 9990, image: '${_i}b-tile.png', delivery: DeliveryKind.cargo, weightKg: 32, categoryId: 'stroymaterialy', subId: 'plitka'),
    Product(id: 't1', name: 'Молоток слесарный 500 г', pack: '1 шт', price: 3490, image: '${_i}p-t1.png', weightKg: .7, categoryId: 'instrumenty', subId: 'ruchnoy'),
    Product(id: 't2', name: 'Набор отвёрток, 6 шт', pack: '6 шт', price: 4990, oldPrice: 5890, image: '${_i}p-t2.png', weightKg: .6, categoryId: 'instrumenty', subId: 'ruchnoy'),
    Product(id: 't3', name: 'Рулетка 5 м', pack: '1 шт', price: 1890, image: '${_i}p-t3.png', weightKg: .3, categoryId: 'instrumenty', subId: 'ruchnoy'),
    Product(id: 't4', name: 'Дрель-шуруповёрт аккумуляторная 18 В', pack: '1 шт', price: 32900, oldPrice: 36900, image: '${_i}p-t4.png', weightKg: 1.4, categoryId: 'instrumenty', subId: 'elektro'),
    Product(id: 't5', name: 'Перфоратор 800 Вт', pack: '1 шт', price: 44900, image: '${_i}p-t5.png', weightKg: 3.1, categoryId: 'instrumenty', subId: 'elektro'),
    Product(id: 't6', name: 'Саморезы по дереву 3,5×35, 200 шт', pack: '200 шт', price: 1290, image: '${_i}p-t6.png', weightKg: .5, categoryId: 'instrumenty', subId: 'krepezh'),
    Product(id: 't7', name: 'Дюбель-гвоздь 6×40, 100 шт', pack: '100 шт', price: 1590, image: '${_i}p-t7.png', weightKg: .4, categoryId: 'instrumenty', subId: 'krepezh'),
    Product(id: 'h1', name: 'Мешки для строительного мусора, 10 шт', pack: '10 шт', price: 1490, image: '${_i}p-h1.png', weightKg: .8, categoryId: 'dlya-doma', subId: 'hoztovary'),
    Product(id: 'h2', name: 'Ведро строительное 12 л', pack: '12 л', price: 990, image: '${_i}p-h2.png', weightKg: .6, categoryId: 'dlya-doma', subId: 'hoztovary'),
    Product(id: 'h3', name: 'Лампа светодиодная E27, 12 Вт', pack: '1 шт', price: 690, image: '${_i}p-h3.png', weightKg: .1, categoryId: 'dlya-doma', subId: 'svet'),
    Product(id: 'h4', name: 'Удлинитель 5 м, 4 розетки', pack: '1 шт', price: 3990, image: '${_i}p-h4.png', weightKg: .8, categoryId: 'dlya-doma', subId: 'svet'),
    Product(id: 'h5', name: 'Смеситель для раковины', pack: '1 шт', price: 12900, oldPrice: 14900, image: '${_i}p-h5.png', weightKg: 1.2, categoryId: 'dlya-doma', subId: 'santehnika'),
    Product(id: 'g1', name: 'Подарочная коробка крафт', pack: '1 шт', price: 1990, image: '${_i}p-g1.png', weightKg: .3, categoryId: 'podarki', subId: 'upakovka'),
    Product(id: 'g2', name: 'Лента атласная, 5 м', pack: '5 м', price: 590, image: '${_i}p-g2.png', weightKg: .05, categoryId: 'podarki', subId: 'upakovka'),
    Product(id: 'g3', name: 'Открытка «С днём рождения»', pack: '1 шт', price: 490, image: '${_i}p-g3.png', weightKg: .05, categoryId: 'podarki', subId: 'otkrytki'),
    Product(id: 'g4', name: 'Шар фольгированный «Сердце»', pack: '1 шт', price: 1490, image: '${_i}p-g4.png', weightKg: .1, categoryId: 'podarki', subId: 'shary'),
    // Цветы — настоящие букеты 8mart.kz (lib/data/flowers.g.dart, tool/import_site_data.dart): размеры S/M/L со своей ценой и фото.
    ...flowerProducts,
    Product(id: 'g5', name: 'Набор латексных шаров, 10 шт', pack: '10 шт', price: 2490, image: '${_i}p-g5.png', weightKg: .2, categoryId: 'podarki', subId: 'shary'),
  ];

  static final _byId = {for (final p in products) p.id: p};
  static Product? byId(String id) => _byId[id];

  /// Позиция корзины: '<id>' или для цветов '<variantId>|<цвет>' (как cartItem() в data.js).
  static Product? cartItem(String key) {
    final parts = key.split('|');
    final id = parts.first, color = parts.length > 1 ? parts[1] : null;
    final plain = _byId[id];
    if (plain != null && plain.variants == null) return plain;
    for (final g in products) {
      final v = g.variants?.where((x) => x.id == id).firstOrNull;
      if (v != null) return g.asVariant(key, v, color);
    }
    return null;
  }
  static String cartKey(ProductVariant v, String? color) => color == null ? v.id : '${v.id}|$color';

  /// Цвет свотча (COLOR_SWATCH в data.js). «Микс» — четыре сектора.
  static const colorSwatch = {'Розовый': 0xFFF4A6C0, 'Красный': 0xFFD7263D, 'Белый': 0xFFFFFFFF, 'Голубой': 0xFF9EC5F0, 'Жёлтый': 0xFFF7D774,
    'Слоновая кость': 0xFFF3EBD8, 'Светло-серый': 0xFFD9DADC, 'Бежевый': 0xFFE6D3B3};
  static const flowerSizeHint = {'S': '35 см', 'M': '45 см', 'L': '55 см'};

  /// Города и филиалы 8mart.kz (lib/data/branches.g.dart). В проде — GET /cities и GET /pickup-points?city (живой статус).
  static const cities = branchCities;
  static const pickupPoints = branchPoints;

  static const popularQueries = ['Розы', 'Гортензии', 'Хризантемы', 'Букет', 'Цемент', 'Краска'];

  static const cards = [
    SavedCard(id: 'c1', brand: 'Visa', last4: '4821', exp: '09/28', isDefault: true),
    SavedCard(id: 'c2', brand: 'Mastercard', last4: '1097', exp: '03/27'),
  ];

  static const orders = [
    OrderSummary(id: '8M-10482', date: '26 сентября, 14:05', method: ReceiveMethod.delivery, status: OrderStatus.onway, eta: '15:20–15:35', items: {'b1': 2, 'b6': 1, 'b4': 1}, total: 21970, bonus: 609, address: 'Астана, Кабанбай батыра, 11'),
    OrderSummary(id: '8M-10311', date: '12 сентября, 10:42', method: ReceiveMethod.pickup, status: OrderStatus.done, items: {'b3': 6, 'b11': 2}, total: 26720, bonus: 536, address: 'пр. Мангилик Ел, 55'),
    OrderSummary(id: '8M-10107', date: '28 августа, 18:10', method: ReceiveMethod.delivery, status: OrderStatus.done, items: {'b12': 1, 't3': 1}, total: 17790, bonus: 450, address: 'Астана, Кабанбай батыра, 11'),
    OrderSummary(id: '8M-09984', date: '14 августа, 12:30', method: ReceiveMethod.delivery, status: OrderStatus.cancelled, items: {'b8': 10}, total: 31900, address: 'Астана, Кабанбай батыра, 11'),
  ];

  static const addresses = [
    Address(id: 'a1', title: 'Дом', street: 'Кабанбай батыра, 11', city: 'Астана', entrance: '2', floor: '7', flat: '48', isDefault: true),
    Address(id: 'a2', title: 'Объект', street: 'ул. Сарайшык, 5', city: 'Астана'),
  ];

  static const promos = [
    UserPromo(code: 'MART10', title: '−10% на заказ', cond: 'от 15 000 тг', until: 'до 31 октября'),
    UserPromo(code: 'FREEDEL', title: 'Бесплатная доставка', cond: 'на любой заказ', until: 'до 15 октября'),
    UserPromo(code: 'SPRING', title: '−500 тг', cond: 'от 5 000 тг', until: 'истёк 31 мая', status: PromoStatus.expired),
  ];

  static const bonusHistory = [
    BonusOp('Начислено за заказ №8M-10311', '12 сентября', 536),
    BonusOp('Списано в заказе №8M-10107', '28 августа', -500),
    BonusOp('Начислено за заказ №8M-10107', '29 августа', 450),
  ];

  static const supportWa = '77000000000';
  static const supportPhone = '+7 700 133 90 71';
  static const tgBot = 'mart8_auth_bot';
  static String tgLink(String token) => 'https://t.me/$tgBot?start=$token';
  static const bonusBalance = 1240, bonusMaxPart = 30;
}
