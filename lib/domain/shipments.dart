import 'models.dart';

/// Тарифы — МОК, уточнить у бизнеса. Одно значение — одно место.
class ShippingConfig {
  const ShippingConfig({this.courierFee = 1000, this.freeFrom = 20000, this.liftFee = 200, this.cargoTiers = const [(300.0, 3000), (1000.0, 5000), (1500.0, 7000)]});
  final int courierFee, freeFrom, liftFee;
  final List<(double upToKg, int fee)> cargoTiers;
  int cargoFee(double kg) => (cargoTiers.firstWhere((t) => kg <= t.$1, orElse: () => cargoTiers.last)).$2;
}

enum ShipmentKind { courier, cargo }

class Shipment {
  const Shipment({required this.kind, required this.index, required this.count, required this.lines, required this.fee, required this.lift});
  final ShipmentKind kind;
  final int index, count, fee, lift;
  final List<CartLine> lines;
  Iterable<CartLine> get active => lines.where((l) => !l.soldOut);
  int get qty => active.fold(0, (s, l) => s + l.qty);
  double get weightKg => active.fold(0.0, (s, l) => s + l.product.weightKg * l.qty);
  int get cargoUnits => active.where((l) => l.product.isCargo).fold(0, (s, l) => s + l.qty);
  int get total => fee + lift;
  bool get isCargo => kind == ShipmentKind.cargo;
}

class ShipmentPlan {
  const ShipmentPlan({required this.canSplit, required this.together, required this.shipments});
  final bool canSplit, together;
  final List<Shipment> shipments;
  bool get multi => shipments.length > 1;
  int get fee => shipments.fold(0, (s, x) => s + x.fee);
  int get lift => shipments.fold(0, (s, x) => s + x.lift);
  bool get hasCourierFee => shipments.any((x) => !x.isCargo && x.fee > 0);
}

/// Порт planShipments() из data.js. Тяжёлое (cargo) — Газель завтра, остальное — курьер сегодня.
/// Если есть оба типа: together=false → два отправления, true → всё одной Газелью.
ShipmentPlan planShipments(List<CartLine> lines, {ReceiveMethod method = ReceiveMethod.delivery, bool together = false,
    int? goodsTotal, int floor = 0, bool lift = false, ShippingConfig cfg = const ShippingConfig()}) {
  final pickup = method == ReceiveMethod.pickup;
  final heavy = lines.where((l) => l.product.isCargo).toList();
  final light = lines.where((l) => !l.product.isCargo).toList();
  bool anyActive(List<CartLine> ls) => ls.any((l) => !l.soldOut);
  final canSplit = anyActive(heavy) && anyActive(light);
  final tog = canSplit && together;
  final groups = <(ShipmentKind, List<CartLine>)>[
    if (!anyActive(heavy)) (ShipmentKind.courier, lines)
    else if (!anyActive(light) || tog) (ShipmentKind.cargo, lines)
    else ...[(ShipmentKind.courier, light), (ShipmentKind.cargo, heavy)],
  ];
  final gt = goodsTotal ?? lines.where((l) => !l.soldOut).fold<int>(0, (s, l) => s + l.sum);
  final list = <Shipment>[];
  for (var i = 0; i < groups.length; i++) {
    final (kind, ls) = groups[i];
    final probe = Shipment(kind: kind, index: i + 1, count: groups.length, lines: ls, fee: 0, lift: 0);
    final fee = pickup ? 0 : kind == ShipmentKind.cargo ? cfg.cargoFee(probe.weightKg) : (gt >= cfg.freeFrom ? 0 : cfg.courierFee);
    final liftFee = !pickup && kind == ShipmentKind.cargo && lift && floor > 1 ? cfg.liftFee * probe.cargoUnits * (floor - 1) : 0;
    list.add(Shipment(kind: kind, index: i + 1, count: groups.length, lines: ls, fee: fee, lift: liftFee));
  }
  return ShipmentPlan(canSplit: canSplit, together: tog, shipments: list);
}
