import '../../core/format.dart';
import '../../domain/shipments.dart';
import '../../l10n/gen/app_localizations.dart';

extension ShipmentTexts on Shipment {
  String tag(L10n t, bool pickup) => pickup ? (isCargo ? t.warehouse : t.store) : (isCargo ? t.cargo : t.courier);
  String? label(L10n t, bool pickup) => count > 1 ? (pickup ? t.pickupN(index, count) : t.shipmentN(index, count)) : null;
  String when(L10n t, bool pickup) => pickup ? (isCargo ? t.tomorrowPickup : t.todayPickup) : (isCargo ? t.tomorrowCargo : t.todayCourier);
  String meta(L10n t, bool pickup, String address) => pickup
      ? (isCargo ? 'Склад, ш. Коргалжын, 3' : address)
      : isCargo ? '${t.cargo} · ${kg(weightKg)}' : '${t.courier} · ${t.itemsCount(qty)}';
  String feeText(L10n t) => fee == 0 ? t.free : money(fee);
}
