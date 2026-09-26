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
  Product asVariant(String key, ProductVariant v, String? color) => Product(id: key, name: '$name, ${v.size}${color == null ? '' : ', ${color.toLowerCase()}'}', pack: v.size,
      price: v.price, image: v.image, bonus: bonus, delivery: delivery, weightKg: weightKg, categoryId: categoryId, subId: subId, variant: v.size, color: color);
  @override
  List<Object?> get props => [id];
}

class ProductVariant {
  const ProductVariant(this.id, this.size, this.price, this.image);
  final String id, size, image;
  final int price;
}

class City {
  const City(this.id, this.name, this.lat, this.lng);
  final String id, name;
  final double lat, lng;
}

/// Точка самовывоза. acceptsCargo — выдаёт тяжёлые товары (склад).
class PickupPoint {
  const PickupPoint(this.id, this.city, this.name, this.hours, this.lat, this.lng);
  final String id, city, name, hours;
  final double lat, lng;
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
  const OrderSummary({required this.id, required this.date, required this.method, required this.status, required this.items, required this.total, this.eta, this.bonus = 0, this.address = ''});
  final String id, date, address;
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
