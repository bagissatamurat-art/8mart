import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/auth_cubit.dart';
import '../../state/checkout_cubit.dart';
import '../../state/order_cubit.dart';
import '../auth/auth_view.dart';
import '../../core/phone_mask.dart';
import '../../domain/shipments.dart';
import '../../domain/slots.dart';
import '../common/slot_days.dart';
import '../common/pickup_split.dart';
import '../common/shipment_texts.dart';
import '../method/method_sheet.dart';

/// Оформление 390 (03 Оформление.dc.html #3b). Не вошёл — шаг входа в белой карточке.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final auth = context.watch<AuthCubit>().state;
    final cart = context.watch<CartCubit>().state;
    return Scaffold(
      body: Column(children: [
        MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
          MartTitleRow(title: auth.authed ? t.checkoutTitle : t.loginTitle, trailing: auth.authed ? t.itemsCount(cart.count) : null),
        ]),
        Expanded(child: auth.authed
            ? const _Form()
            : ListView(padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)), child: const AuthView()),
              ])),
      ]),
      bottomNavigationBar: auth.authed ? const _Cta() : null,
    );
  }
}

TextStyle _f(double size, FontWeight w, Color col, {double? h}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h);

class _Form extends StatelessWidget {
  const _Form();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final cartCubit = context.read<CartCubit>();
    final cart = context.watch<CartCubit>().state;
    final co = context.watch<CheckoutCubit>();
    final s = co.state;
    final auth = context.watch<AuthCubit>().state;
    final pickup = cart.method == ReceiveMethod.pickup;
    final plan = cart.plan(floor: s.floorN, lift: s.lift, goodsTotal: cart.afterDiscount);
    const cfg = ShippingConfig();
    final spendMax = CheckoutCubit.spendMax(cart.afterDiscount);
    final spend = s.useBonus ? spendMax : 0;
    final total = cart.afterDiscount + plan.fee + plan.lift - spend;

    Widget card(List<Widget> children, {Widget? head}) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (head != null) head,
            for (final w in children) ...[const SizedBox(height: 12), w],
          ]),
        );
    Widget title(String text, {String? action, VoidCallback? onAction}) => Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(text, style: _f(16, FontWeight.w700, c.ink1))),
          if (action != null) GestureDetector(onTap: onAction, child: Text(action, style: _f(13, FontWeight.w600, c.primary))),
        ]);
    Widget row(String k, String v, {Color? color, Widget? tag}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          Text(k, style: _f(14, FontWeight.w400, c.ink2)),
          if (tag != null) ...[const SizedBox(width: 6), tag],
          const Spacer(),
          Text(v, style: _f(14, color == null ? FontWeight.w400 : FontWeight.w600, color ?? c.ink1)),
        ]));

    // Слоты считаются от текущего времени Казахстана; выбранный пропал (время прошло) — первый доступный.
    final eta = '${cfg.etaMin}–${cfg.etaMax} мин';
    final courierDays = courierSlots(DateTime.now(), asapLabel: t.slotAsap, eta: eta), cargoDays = cargoSlots(DateTime.now());
    final cSlot = effectiveSlot(courierDays, s.courierSlot), gSlot = effectiveSlot(cargoDays, s.cargoSlot);
    final phone = s.recipientPhone ?? auth.phone, kaspiPhone = s.kaspiPhone ?? auth.phone;
    final kaspiInvoice = s.payment == 'kaspi' && !cart.kaspiIntegrated;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      // Блока «Получатель» нет (вошедший пользователь): телефон получателя, комментарий и «Оставить у двери» — здесь.
      card(head: title(pickup ? t.pickup : t.delivery, action: t.change, onAction: () => openMethodSheet(context)), [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(cart.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(14, FontWeight.w600, c.ink1))),
          ]),
        ),
        if (!pickup) Row(children: [
          Expanded(child: MartInput(label: t.entrance, type: MartInputType.number, initialValue: s.entrance, onChanged: (v) => co.set((x) => x.copyWith(entrance: v)))),
          const SizedBox(width: 8),
          Expanded(child: MartInput(label: t.floor, type: MartInputType.number, initialValue: s.floor, onChanged: (v) => co.set((x) => x.copyWith(floor: v)))),
          const SizedBox(width: 8),
          Expanded(child: MartInput(label: t.flat, initialValue: s.flat, onChanged: (v) => co.set((x) => x.copyWith(flat: v)))),
        ]),
        MartInput(label: t.recipientPhone, type: MartInputType.phone, required: true, initialValue: phone,
            hint: pickup ? t.recipientHintPickup : t.recipientHintDelivery,
            error: s.touched && !PhoneMaskFormatter.isComplete(phone) ? t.blockedPhone : null,
            onChanged: (v) => co.set((x) => x.copyWith(recipientPhone: v, touched: true))),
        MartInput(label: pickup ? t.commentOrder : t.commentCourier, type: MartInputType.multiline, initialValue: s.comment, onChanged: (v) => co.set((x) => x.copyWith(comment: v))),
        if (!pickup) MartSwitchTile(value: s.leaveAtDoor, onTap: co.toggleLeaveAtDoor, title: t.leaveAtDoor, sub: t.leaveAtDoorSub),
      ]),
      const SizedBox(height: 12),
      // «Способ доставки» / «Когда забрать»: отправления, время курьера и грузового, подъём на этаж.
      card(head: title(pickup ? t.shipTitlePickup : t.shipTitleDelivery), [
        if (plan.canSplit) PickupSplitChoice(cart: cart, onChanged: cartCubit.setTogether),
        for (final sh in plan.shipments) Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(MartRadius.field), border: Border.all(color: c.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ShipmentHead(tag: sh.tag(t, pickup), cargo: sh.isCargo, label: sh.label(t, pickup),
                when: (!pickup ? slotTitle(context, sh.isCargo ? cargoDays : courierDays, sh.isCargo ? gSlot : cSlot) : null) ?? sh.when(t, pickup),
                meta: sh.meta(t, pickup, cart.address), feeText: pickup ? null : sh.feeText(t)),
            const SizedBox(height: 12),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final l in sh.lines) SizedBox.square(dimension: 40, child: MartImage(l.product.image, radius: 10, fit: BoxFit.cover))]),
            if (!pickup) ...[
              const SizedBox(height: 12),
              Text(sh.isCargo ? t.whenBring : t.whenDeliver, style: _f(14, FontWeight.w600, c.ink1)),
              const SizedBox(height: 8),
              SlotPicker(timeLabel: t.timeLabel, days: pickerDays(context, sh.isCargo ? cargoDays : courierDays), value: sh.isCargo ? gSlot : cSlot,
                  onChanged: (id) => co.set((x) => sh.isCargo ? x.copyWith(cargoSlot: id) : x.copyWith(courierSlot: id))),
            ],
            if (!pickup && sh.isCargo) ...[
              const SizedBox(height: 12),
              MartSwitchTile(value: s.lift, onTap: co.toggleLift, title: t.liftToFloor,
                  sub: s.floorN > 1 ? t.liftSubCalc(moneyText(cfg.liftFee), sh.cargoUnits, s.floorN, money(cfg.liftFee * sh.cargoUnits * (s.floorN - 1))) : t.liftSubNoFloor),
            ],
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      card(head: title(t.payment), [
        PaymentPicker(value: s.payment, cards: MockData.cards, onChanged: co.setPayment,
            labels: PaymentLabels(kaspiSub: t.kaspiSub, cardOnline: t.cardOnline, savedCards: t.savedCards, newCard: t.newCard, newCardSub: t.newCardSub)),
        // Kaspi Pay в филиале не подключён автоматически — выставим счёт в Kaspi на номер (из профиля, можно поменять).
        if (kaspiInvoice) MartInput(label: t.kaspiPhone, type: MartInputType.phone, required: true, initialValue: kaspiPhone, hint: t.kaspiHint,
            error: s.touched && !PhoneMaskFormatter.isComplete(kaspiPhone) ? t.blockedKaspiPhone : null,
            onChanged: (v) => co.set((x) => x.copyWith(kaspiPhone: v, touched: true))),
      ]),
      const SizedBox(height: 12),
      card(head: title(t.itemsCount(cart.count), action: t.change, onAction: () => context.go('/cart')), [
        for (final l in cart.active) Row(children: [
          SizedBox.square(dimension: 44, child: MartImage(l.product.image, radius: 10, fit: BoxFit.cover)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(14, FontWeight.w400, c.ink1)),
            const SizedBox(height: 2),
            Text('${l.qty} × ${money(l.product.price ?? 0)}', style: _f(12, FontWeight.w400, c.ink3)),
          ])),
          const SizedBox(width: 10),
          Text(money(l.sum), style: _f(14, FontWeight.w600, c.ink1)),
        ]),
        MartPromo(label: t.promoLabel, applyLabel: t.promoApply, appliedLabel: t.promoApplied, appliedCode: cart.promo, discountText: '−${money(cart.discount)}',
          onRemove: cartCubit.removePromo,
          onApply: (code) => switch (cartCubit.applyPromo(code)) {
            PromoResult.ok => null, PromoResult.notFound => t.promoErrNotFound, PromoResult.expired => t.promoErrExpired,
            PromoResult.minSum => t.promoErrMinSum(money(PromoRules.minSum)),
          }),
        if (spendMax > 0) MartSwitchTile(green: true, value: s.useBonus, onTap: co.toggleBonus,
            leading: Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                child: const Text('Б', style: TextStyle(fontFamily: 'Onest', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, height: 1))),
            title: t.spendBonus(t.bonusCount(spendMax).substring(1)), sub: t.spendBonusSub(moneyText(MockData.bonusBalance).replaceAll('тг', '').trim(), MockData.bonusMaxPart)),
        Container(height: 1, color: c.divider),
        Column(children: [
          row(t.goods, money(cart.goods)),
          if (cart.discount > 0) row(t.promoLabel, '−${money(cart.discount)}', color: c.success, tag: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(999)),
            child: Text('${cart.promo} · −${PromoRules.pct}%', style: _f(12, FontWeight.w600, c.success)))),
          if (pickup) row(t.pickup, t.free, color: c.success)
          else for (final sh in plan.shipments) row('${t.delivery}${plan.multi ? ' · ${sh.tag(t, false)}' : ''}', sh.feeText(t), color: sh.fee == 0 ? c.success : null),
          if (plan.lift > 0) row(t.liftToFloor, money(plan.lift)),
          if (spend > 0) row(t.byBonus, '−${money(spend)}', color: c.successText),
        ]),
        Container(height: 1, color: c.divider),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(t.total, style: _f(16, FontWeight.w700, c.ink1))),
          Text(money(total), style: _f(20, FontWeight.w700, c.ink1).copyWith(letterSpacing: -0.2)),
        ]),
        if (cart.bonus > 0) Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(width: 14, height: 14, alignment: Alignment.center, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                child: const Text('Б', style: TextStyle(fontFamily: 'Onest', fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1))),
            const SizedBox(width: 8),
            Expanded(child: Text(t.bonusAfter(cart.bonus), style: _f(13, FontWeight.w400, const Color(0xFF0F6B3E), h: 1.35))),
          ]),
        ),
      ]),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: co.toggleOffer,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedContainer(duration: MartMotion.press, width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(color: s.offer ? c.primary : c.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: s.offer ? c.primary : c.border, width: 1.5)),
              child: s.offer ? const Center(child: MartCheck(color: Colors.white)) : null),
            const SizedBox(width: 10),
            Expanded(child: Text.rich(TextSpan(text: t.offerPrefix, children: [
              TextSpan(text: t.offerLink, style: const TextStyle(decoration: TextDecoration.underline)),
              TextSpan(text: t.offerSuffix),
            ]), style: _f(13, FontWeight.w400, c.ink2, h: 1.4))),
          ]),
        ),
      ),
    ]);
  }
}

class _Cta extends StatelessWidget {
  const _Cta();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final cart = context.watch<CartCubit>().state;
    final co = context.watch<CheckoutCubit>();
    final s = co.state;
    final plan = cart.plan(floor: s.floorN, lift: s.lift, goodsTotal: cart.afterDiscount);
    final spend = s.useBonus ? CheckoutCubit.spendMax(cart.afterDiscount) : 0;
    final total = cart.afterDiscount + plan.fee + plan.lift - spend;
    final auth = context.watch<AuthCubit>().state;
    final kaspiInvoice = s.payment == 'kaspi' && !cart.kaspiIntegrated;
    final reason = cart.hasSoldOut ? t.blockedSoldOut
        : !PhoneMaskFormatter.isComplete(s.recipientPhone ?? auth.phone) ? t.blockedPhone
        : kaspiInvoice && !PhoneMaskFormatter.isComplete(s.kaspiPhone ?? auth.phone) ? t.blockedKaspiPhone
        : !s.offer ? t.blockedOffer : null;
    Future<void> place() async {
      final id = await co.place();
      if (!context.mounted) return;
      context.read<OrderCubit>().create(id: id, plan: plan, method: cart.method ?? ReceiveMethod.delivery, total: total, bonus: cart.bonus,
          lines: cart.active.toList(), address: cart.address, paidWith: s.payment == 'kaspi' ? 'Оплачено Kaspi' : 'Оплачено картой',
          goods: cart.goods, discount: cart.discount, spent: spend,
          recipientPhone: s.recipientPhone ?? auth.phone, leaveAtDoor: cart.method == ReceiveMethod.delivery && s.leaveAtDoor);
      if (s.payment == 'kaspi') {
        // В проде: ссылка оплаты от бэкенда → приложение Kaspi → возврат по 8mart.kz/pay/return?order=<id>
        await launchUrl(Uri.parse('https://kaspi.kz/pay/8mart?order=$id'), mode: LaunchMode.externalApplication);
      }
      if (context.mounted) { context.read<CartCubit>().clearCart(); context.go('/order/$id'); }
    }
    return MartBottomBar(
      note: reason,
      child: s.payment == 'kaspi'
          ? KaspiPayButton(loading: s.placing, disabledReason: reason, onPressed: place)
          : MartButton(label: t.pay, amount: money(total), expanded: true, loading: s.placing, disabledReason: reason, onPressed: place),
    );
  }
}
