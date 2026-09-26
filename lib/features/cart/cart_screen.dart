import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../domain/models.dart';
import '../../domain/shipments.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';
import '../common/shipment_texts.dart';
import '../method/method_sheet.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final cubit = context.watch<CartCubit>();
    final s = cubit.state;
    final pickup = s.method == ReceiveMethod.pickup;
    final plan = s.plan(goodsTotal: s.afterDiscount);
    const cfg = ShippingConfig();
    final total = s.afterDiscount + plan.fee;
    final reason = s.method == null ? t.blockedMethod : s.hasSoldOut ? t.blockedSoldOut : null;
    TextStyle f(double size, FontWeight w, Color col, {double? h}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h);

    Widget card(Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) =>
        Container(padding: padding, decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)), child: child);

    // Корзина 390 (02 Корзина.dc.html #2b): белая панель — назад · «Корзина · N товаров» · Очистить; под ней способ получения (серый блок 14).
    final header = MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
      Row(children: [
        MartBackButton(onTap: () => context.go('/')),
        const SizedBox(width: 8),
        Expanded(child: Text.rich(TextSpan(text: t.cartTitle, children: [if (s.count > 0) TextSpan(text: ' · ${t.itemsCount(s.count)}', style: f(22, FontWeight.w600, c.ink3))]),
            maxLines: 1, overflow: TextOverflow.ellipsis, style: f(22, FontWeight.w800, c.ink1).copyWith(letterSpacing: -0.44))),
        if (s.lines.isNotEmpty) GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: cubit.clearCart,
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(t.clear, style: f(14, FontWeight.w600, c.ink2)))),
      ]),
      if (s.lines.isNotEmpty) GestureDetector(
        onTap: () => openMethodSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.method == null ? t.howToGet : pickup ? t.pickup : t.delivery, style: f(12, FontWeight.w400, c.ink2)),
              const SizedBox(height: 2),
              Text(s.address.isEmpty ? '—' : s.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: f(14, FontWeight.w600, c.ink1)),
            ])),
            const SizedBox(width: 12),
            Text(t.change, style: f(13, FontWeight.w600, c.primary)),
          ]),
        ),
      ),
    ]);

    return Scaffold(
      body: Column(children: [
        header,
        Expanded(child: s.lines.isEmpty
          ? MartEmptyState(image: 'assets/images/empty-cart.png', title: t.cartEmpty, text: t.cartEmptyHint, action: t.toCatalog, onAction: () => context.go('/catalog'))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
              if (s.hasSoldOut) ...[
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: c.errorBg, borderRadius: BorderRadius.circular(14)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: c.error, shape: BoxShape.circle),
                      child: const Text('!', style: TextStyle(fontFamily: 'Onest', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, height: 1))),
                    const SizedBox(width: 10),
                    Expanded(child: Text.rich(TextSpan(text: '${t.soldOutAlert} ', children: [
                      WidgetSpan(alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic, child: GestureDetector(onTap: cubit.removeSoldOut,
                        child: Text(t.removeAll, style: f(13, FontWeight.w600, c.error, h: 1.4)))),
                    ]), style: f(13, FontWeight.w400, c.ink1, h: 1.4))),
                  ])),
                const SizedBox(height: 12),
              ],
              if (plan.canSplit) ...[
                card(SplitChoice(
                  title: pickup ? t.splitTitlePickup : t.splitTitle, sub: t.splitSub, together: s.together, onChanged: cubit.setTogether,
                  options: [
                    SplitOption(together: false, title: pickup ? t.splitTwoPickup : t.splitTwo, sub: '${t.todayCourier} + ${t.tomorrowCargo}',
                        feeText: s.copyWith(together: false).plan(goodsTotal: s.afterDiscount).shipments.map((x) => x.feeText(t)).join(' + ')),
                    SplitOption(together: true, title: pickup ? t.splitTogetherPickup : t.splitTogether, sub: pickup ? t.tomorrowPickup : t.tomorrowCargo,
                        feeText: s.copyWith(together: true).plan(goodsTotal: s.afterDiscount).shipments.first.feeText(t)),
                  ],
                )),
                const SizedBox(height: 12),
              ],
              for (final sh in plan.shipments) ...[
                card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 8), child: ShipmentHead(tag: sh.tag(t, pickup), cargo: sh.isCargo, label: sh.label(t, pickup), when: sh.when(t, pickup), meta: sh.meta(t, pickup, s.address), feeText: pickup ? null : sh.feeText(t))),
                  Container(height: 1, margin: const EdgeInsets.fromLTRB(10, 0, 10, 2), color: c.divider),
                  for (final l in sh.lines) Padding(padding: const EdgeInsets.only(top: 2),
                    child: MartCartLine(line: l, onQty: (q) => cubit.setQty(l.product.id, q), soldOutLabel: t.soldOut, notCountedLabel: t.notCounted, notInStockLabel: t.notInStock,
                        removeLabel: t.removeFromCart, perPieceLabel: t.perPiece, bonusText: t.bonusCount)),
                ]), padding: const EdgeInsets.all(6)),
                const SizedBox(height: 12),
              ],
              card(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                MartPromo(label: t.promoLabel, applyLabel: t.promoApply, appliedLabel: t.promoApplied, appliedCode: s.promo, discountText: '−${money(s.discount)}',
                  onRemove: cubit.removePromo,
                  onApply: (code) => switch (cubit.applyPromo(code)) {
                    PromoResult.ok => null, PromoResult.notFound => t.promoErrNotFound, PromoResult.expired => t.promoErrExpired,
                    PromoResult.minSum => t.promoErrMinSum(money(PromoRules.minSum)),
                  }),
                const SizedBox(height: 12),
                _Row(t.itemsCount(s.count), money(s.goods)),
                if (s.discount > 0) _Row(t.promoLabel, '−${money(s.discount)}', ok: true),
                if (pickup) _Row(t.pickup, t.free, ok: true)
                else for (final sh in plan.shipments) _Row('${t.delivery}${plan.multi ? ' · ${sh.tag(t, false)}' : ''}', sh.feeText(t), ok: sh.fee == 0),
                if (!pickup && plan.hasCourierFee && s.afterDiscount > 0) ...[
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: (s.afterDiscount / cfg.freeFrom).clamp(0, 1), minHeight: 6, backgroundColor: c.bg, color: c.success)),
                  const SizedBox(height: 6),
                  Text((plan.multi ? t.untilFreeCourier : t.untilFree)(moneyText((cfg.freeFrom - s.afterDiscount).clamp(0, cfg.freeFrom).toInt())), style: f(13, FontWeight.w400, c.ink2)),
                ],
                if (s.bonus > 0) ...[const SizedBox(height: 8), _BonusNote(t.bonusAfter(s.bonus))],
              ])),
            ])),
      ]),
      bottomNavigationBar: s.lines.isEmpty ? null : MartBottomBar(
        note: reason,
        child: MartButton(label: t.checkout, amount: money(total), expanded: true, disabledReason: reason, onPressed: () => context.push('/checkout')),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.k, this.v, {this.ok = false});
  final String k, v;
  final bool ok;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Expanded(child: Text(k, style: TextStyle(fontFamily: 'Onest', fontSize: 14, color: c.ink2))),
      const SizedBox(width: 12),
      Text(v, style: TextStyle(fontFamily: 'Onest', fontSize: 14, color: ok ? c.success : c.ink1)),
    ]));
  }
}

class _BonusNote extends StatelessWidget {
  const _BonusNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 14, height: 14, alignment: Alignment.center, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
          child: const Text('Б', style: TextStyle(fontFamily: MartText.family, fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1))),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontFamily: 'Onest', fontSize: 13, height: 1.35, color: Color(0xFF0F6B3E)))),
      ]));
  }
}
