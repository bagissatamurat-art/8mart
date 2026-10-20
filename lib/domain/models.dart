import 'package:equatable/equatable.dart';

/// Формы объектов = контракт API (см. data.js в макетах).
enum DeliveryKind { express, cargo, flowers }

class Product extends Equatable {
  const Product({required this.id, required this.name, required this.pack, this.price, this.oldPrice, required this.image,
      this.bonus = 0, this.delivery = DeliveryKind.express, this.weightKg = 1, required this.categoryId, this.subId = '', this.badge, this.variants, this.colors, this.variant, this.color});
  final String id, name, pack, image, categoryId, subId;
  final int? price, oldPrice;
  final int bonus;
  final DeliveryKind delivery;
  final double weightKg;
  final String? badge;
  /// Цветы: размеры S/M/L со своей ценой и фото; цвета на выбор.
  final List<ProductVariant>? variants;
  final List<String>? colors;
  /// Заполнено у позиции корзины для цветов.
  final String? variant, color;
  bool get isCargo => delivery == DeliveryKind.cargo;
  bool get hasVariants => variants != null && variants!.isNotEmpty;

  /// Товар из ответа API (`GET /products…`). В ответе одна категория — `cat` (слаг подкатегории, а у товара прямо
  /// в корне — слаг корня); корень и подкатегорию подставляет вызывающий по дереву категорий (Catalog).
  /// Тот же товар по цене своего филиала (ответ POST /cart/validate): в каталоге цена общая, в корзине — точная.
  Product withPrice(int price) => Product(id: id, name: name, pack: pack, price: price, oldPrice: oldPrice != null && oldPrice! > price ? oldPrice : null, image: image, bonus: bonus,
      delivery: delivery, weightKg: weightKg, categoryId: categoryId, subId: subId, badge: badge, variants: variants, colors: colors, variant: variant, color: color);

  static Product fromJson(Map<String, dynamic> j, {String? categoryId, String subId = ''}) => Product(
        id: '${j['id']}',
        name: j['name'] as String? ?? '',
        pack: (j['pack'] ?? j['weight']) as String? ?? '',
        price: (j['price'] as num?)?.round(),
        oldPrice: (j['oldPrice'] as num?)?.round(),
        image: j['img'] as String? ?? '',
        bonus: (j['bonus'] as num?)?.round() ?? 0,
        delivery: switch (j['delivery']) { 'cargo' => DeliveryKind.cargo, 'flowers' => DeliveryKind.flowers, _ => DeliveryKind.express },
        weightKg: (j['weightKg'] as num?)?.toDouble() ?? 1,
        categoryId: categoryId ?? j['cat'] as String? ?? '',
        subId: subId,
        badge: j['badge'] as String?,
        variants: (j['variants'] as List?)?.map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v as Map))).toList(),
        colors: (j['colors'] as List?)?.cast<String>(),
      );
  Product asVariant(String key, ProductVariant v, String? color) => Product(id: key, name: '$name, ${v.size}${color == null ? '' : ', ${color.toLowerCase()}'}', pack: v.size,
      price: v.price, image: v.image, bonus: bonus, delivery: delivery, weightKg: weightKg, categoryId: categoryId, subId: subId, variant: v.size, color: color);
  @override
  List<Object?> get props => [id];
}

class ProductVariant {
  const ProductVariant(this.id, this.size, this.price, this.image);
  final String id, size, image;
  final int price;
  static ProductVariant fromJson(Map<String, dynamic> j) =>
      ProductVariant('${j['id']}', j['size'] as String? ?? '', (j['price'] as num?)?.round() ?? 0, j['img'] as String? ?? '');
}

class City {
  const City(this.id, this.name, this.lat, this.lng);
  final String id, name;
  final double lat, lng;
  /// `GET /cities`.
  static City fromJson(Map<String, dynamic> j) => City('${j['id']}', j['name'] as String? ?? '', (j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());
}

/// Точка самовывоза (филиал 8mart.kz). hours — график, если известен (в API его нет — пусто);
/// isOpen / acceptingOrders — живой статус филиала; brand — вывеска, если не 8MART (ROMANTIC);
/// kaspiIntegrated — Kaspi Pay подключён автоматически (иначе счёт в Kaspi на номер).
class PickupPoint {
  const PickupPoint(this.id, this.city, this.name, this.hours, this.lat, this.lng,
      {this.isOpen = true, this.acceptingOrders = true, this.kaspiIntegrated = false, this.brand});
  final String id, city, name, hours;
  final double lat, lng;
  final bool isOpen, acceptingOrders, kaspiIntegrated;
  final String? brand;
  /// `GET /pickup-points`. Графика в ответе нет — hours пустой, статус по isOpen / acceptingOrders.
  static PickupPoint fromJson(Map<String, dynamic> j) => PickupPoint(
        '${j['id']}', j['city'] as String? ?? '', j['name'] as String? ?? '', j['hours'] as String? ?? '',
        (j['lat'] as num).toDouble(), (j['lng'] as num).toDouble(),
        isOpen: j['isOpen'] as bool? ?? true, acceptingOrders: j['acceptingOrders'] as bool? ?? true,
        kaspiIntegrated: j['kaspiIntegrated'] as bool? ?? false, brand: j['brand'] as String?,
      );
}

class Category extends Equatable {
  const Category({required this.id, required this.name, required this.image});
  final String id, name, image;
  @override
  List<Object?> get props => [id];
}

class SavedCard extends Equatable {
  const SavedCard({required this.id, required this.brand, required this.last4, required this.exp, this.isDefault = false});
  final String id, brand, last4, exp;
  final bool isDefault;
  String get title => '$brand •• $last4';
  @override
  List<Object?> get props => [id];
}

enum ReceiveMethod { delivery, pickup }

/// Зона доставки 8mart.kz для адреса (GET /public/branches/resolve-delivery?lat&lng): стоимость и время курьера, филиал.
class DeliveryQuote extends Equatable {
  const DeliveryQuote({required this.fee, required this.eta, required this.branchName, required this.zone, this.kaspiIntegrated = false});
  final int fee, eta;
  final String branchName, zone;
  final bool kaspiIntegrated;
  Map<String, dynamic> toJson() => {'fee': fee, 'eta': eta, 'branchName': branchName, 'zone': zone, 'kaspiIntegrated': kaspiIntegrated};
  static DeliveryQuote? fromJson(Object? j) => j is Map ? DeliveryQuote(fee: j['fee'] as int, eta: j['eta'] as int, branchName: j['branchName'] as String? ?? '',
      zone: j['zone'] as String? ?? '', kaspiIntegrated: j['kaspiIntegrated'] as bool? ?? false) : null;
  @override
  List<Object?> get props => [fee, eta, branchName, zone, kaspiIntegrated];
}

class CartLine extends Equatable {
  const CartLine(this.product, this.qty, {this.soldOut = false});
  final Product product;
  final int qty;
  final bool soldOut;
  int get sum => (product.price ?? 0) * qty;
  @override
  List<Object?> get props => [product.id, qty, soldOut];
}

class SubCategory extends Equatable {
  const SubCategory(this.id, this.name, this.parentId);
  final String id, name, parentId;
  @override
  List<Object?> get props => [id];
}

enum SortKind { popular, cheap, expensive, sale, bonus }

/// Фильтры каталога. Цена от–до есть всегда; остальное — по категории (CAT_FILTERS в data.js).
class CatalogFilter extends Equatable {
  const CatalogFilter({this.min, this.max, this.sale = false});
  final int? min, max;
  final bool sale;
  int get count => (min != null || max != null ? 1 : 0) + (sale ? 1 : 0);
  bool accepts(Product p) => (min == null || (p.price ?? 0) >= min!) && (max == null || (p.price ?? 0) <= max!) && (!sale || p.oldPrice != null);
  @override
  List<Object?> get props => [min, max, sale];
}

enum OrderStatus { accepted, assembling, onway, ready, done, cancelled }

class OrderSummary extends Equatable {
  const OrderSummary({required this.id, required this.date, required this.method, required this.status, required this.items, required this.total, this.eta, this.bonus = 0, this.address = '', this.number = ''});
  final String id, date, address;
  /// Номер для людей («1042»): с бэкендом [id] — длинный ключ заказа, показывать его незачем.
  final String number;
  String get title => number.isEmpty ? id : number;
  final ReceiveMethod method;
  final OrderStatus status;
  final Map<String, int> items;
  final int total, bonus;
  final String? eta;
  bool get isActive => status.index < OrderStatus.done.index;
  @override
  List<Object?> get props => [id, status];
}

class Address extends Equatable {
  const Address({required this.id, required this.title, required this.street, required this.city, this.entrance = '', this.floor = '', this.flat = '', this.isDefault = false});
  final String id, title, street, city, entrance, floor, flat;
  final bool isDefault;
  String get details => [if (entrance.isNotEmpty) 'подъезд $entrance', if (floor.isNotEmpty) 'этаж $floor', if (flat.isNotEmpty) 'кв. $flat'].join(', ');
  Address copyWith({String? title, String? street, String? entrance, String? floor, String? flat, bool? isDefault}) => Address(
      id: id, city: city, title: title ?? this.title, street: street ?? this.street, entrance: entrance ?? this.entrance, floor: floor ?? this.floor, flat: flat ?? this.flat, isDefault: isDefault ?? this.isDefault);
  @override
  List<Object?> get props => [id, title, street, entrance, floor, flat, isDefault];
}

enum PromoStatus { active, used, expired }

class UserPromo extends Equatable {
  const UserPromo({required this.code, required this.title, required this.cond, required this.until, this.status = PromoStatus.active});
  final String code, title, cond, until;
  final PromoStatus status;
  @override
  List<Object?> get props => [code];
}

class BonusOp {
  const BonusOp(this.title, this.date, this.amount);
  final String title, date;
  final int amount;
}

/// Сторис (как на сайте): кружок-обложка на главной → слайды. Видео-слайд (сторис 8mart.kz): img — обложка, video — ролик.
class Story extends Equatable {
  const Story({required this.id, required this.title, required this.cover, required this.slides});
  final String id, title, cover;
  final List<StorySlide> slides;
  @override
  List<Object?> get props => [id];
}

class StorySlide {
  const StorySlide({required this.img, this.title = '', this.text = '', this.video, this.duration, this.ctaLabel, this.ctaPath, this.ctaCopy});
  final String img, title, text;
  /// Видео (сторис 8mart.kz): текст уже в ролике — title/text пустые.
  final String? video;
  /// Длительность из API, с — пока видео не загрузилось.
  final int? duration;
  /// Кнопка: переход в приложении (ctaPath) или «скопировать код» (ctaCopy).
  final String? ctaLabel, ctaPath, ctaCopy;
}
