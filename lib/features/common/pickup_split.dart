import 'package:flutter/material.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';
import 'shipment_texts.dart';

/// «Как забрать заказ» — только самовывоз смешанной корзины (plan.canSplit): в два приёма или всё завтра со склада.
/// В доставке выбора нет: курьер и грузовой — разные машины, это всегда две доставки.
class PickupSplitChoice extends StatelessWidget {
  const PickupSplitChoice({super.key, required this.cart, required this.onChanged});
  final CartState cart;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    String fee(bool together) => cart.copyWith(together: together).plan(goodsTotal: cart.afterDiscount).shipments.map((x) => x.feeText(t)).join(' + ');
    return SplitChoice(
      title: t.splitTitlePickup, sub: t.splitSub, together: cart.together, onChanged: onChanged,
      options: [
        SplitOption(together: false, title: t.splitTwoPickup, sub: '${t.todayPickup} + ${t.tomorrowPickup}', feeText: fee(false)),
        SplitOption(together: true, title: t.splitTogetherPickup, sub: t.tomorrowPickup, feeText: fee(true)),
      ],
    );
  }
}
