import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../domain/shipments.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/auth_cubit.dart';
import '../../state/order_cubit.dart';
import '../../state/settings_cubit.dart';
import '../../ui/ui.dart';

TextStyle _f(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

/// Статус заказа 390 (03 Оформление.dc.html #3b, шаг success): белая панель — назад + «Статус заказа» + «N товаров»;
/// карточка — «Заказ № · дата», на каждое отправление: метка, статус 24/800, подпись, «Привезём к», шкала, курьер/водитель; поддержка WhatsApp;
/// карточка получения и получателя; карточка состава и итогов; «Продолжить покупки»; «Отменить заказ» серой ссылкой.
class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final live = context.watch<OrderCubit>().state;
    final auth = context.watch<AuthCubit>().state;
    final settings = context.watch<SettingsCubit>();
    final o = live.id == id ? live : () {
      final s = MockData.orders.where((x) => x.id == id).firstOrNull;
      if (s == null) return live;
      return orderFromSummary(s, [for (final e in s.items.entries) if (MockData.byId(e.key) case final p?) CartLine(p, e.value)]);
    }();
    final isLive = live.id == id;
    final pickup = o.method == ReceiveMethod.pickup;
    final multi = o.kinds.length > 1;
    final count = o.lines.fold(0, (s, l) => s + l.qty);

    String stage(ShipmentKind k, int i) => [
          t.stAccepted, t.stAssembling,
          pickup ? t.stReady : k == ShipmentKind.cargo ? t.stCargo : t.stCourier,
          pickup ? t.stIssued : t.stDelivered,
        ][i.clamp(0, 3)];
    String sub(ShipmentKind k, int i) => switch (i) {
          0 => 'Оплата прошла, передали заказ в сборку',
          1 => k == ShipmentKind.cargo ? 'Комплектуем на складе, погрузим в Газель' : 'Проверяем наличие и упаковываем',
          2 => pickup ? 'Покажите номер заказа на кассе' : 'Позвоним за 10–15 минут до приезда',
          _ => pickup ? 'Спасибо за покупку!' : 'Спасибо! Оцените доставку в приложении',
        };
    List<TimelineStage> stages(ShipmentKind k, int cur) => [
          for (var i = 0; i < 4; i++) TimelineStage(stage(k, i), sub: sub(k, i), time: i <= cur ? ['14:05', '14:07', '14:40', '15:25'][i] : null),
        ];

    Widget card(List<Widget> ch, {EdgeInsets padding = const EdgeInsets.all(16)}) => Container(
          padding: padding, decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: ch));
    Widget row(String k, String v, {Color? color, bool strong = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          Expanded(child: Text(k, style: _f(14, FontWeight.w400, c.ink2))),
          Text(v, style: _f(14, strong ? FontWeight.w600 : FontWeight.w400, color ?? c.ink1)),
        ]));

    return Scaffold(body: Column(children: [
      MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
        MartTitleRow(title: 'Статус заказа', trailing: count > 0 ? t.itemsCount(count) : null, onBack: () => context.canPop() ? context.pop() : context.go('/')),
      ]),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 20), children: [
        if (isLive && !settings.state.pushAsked && !o.cancelled) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(MartRadius.card)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.pushAsk, style: _f(16, FontWeight.w700, c.ink1)),
              const SizedBox(height: 4),
              Text(t.pushAskSub, style: _f(14, FontWeight.w400, c.ink2, h: 1.4)),
              const SizedBox(height: 12),
              Row(children: [
                // В проде: await FirebaseMessaging.instance.requestPermission();
                MartButton(label: t.allow, size: MartButtonSize.m44, onPressed: settings.markPushAsked),
                const SizedBox(width: 8),
                MartButton(label: t.notNow, size: MartButtonSize.m44, variant: MartButtonVariant.ghost, onPressed: settings.markPushAsked),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        card(padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), [
          Text('Заказ №${o.id} · ${o.date}', style: _f(13, FontWeight.w400, c.ink3)),
          const SizedBox(height: 20),
          if (o.cancelled) ...[
            Text(t.stCancelled, style: _f(24, FontWeight.w800, c.error, ls: -0.48)),
            const SizedBox(height: 6),
            Text(t.refund(money(o.total)), style: _f(14, FontWeight.w400, c.ink2, h: 1.45)),
            if (o.bonus > 0) ...[const SizedBox(height: 6), Text('Вернём ${o.bonus} ${plural(o.bonus, 'бонус', 'бонуса', 'бонусов')}', style: _f(14, FontWeight.w400, c.ink2, h: 1.45))],
          ] else for (var i = 0; i < o.kinds.length; i++) Container(
            padding: EdgeInsets.only(bottom: i < o.kinds.length - 1 ? 20 : 0),
            margin: EdgeInsets.only(bottom: i < o.kinds.length - 1 ? 20 : 0),
            decoration: BoxDecoration(border: i < o.kinds.length - 1 ? Border(bottom: BorderSide(color: c.divider)) : null),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (multi) ...[
                Row(children: [
                  Container(height: 22, padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.center,
                    decoration: BoxDecoration(color: o.kinds[i] == ShipmentKind.cargo ? c.ink1 : c.primary50, borderRadius: BorderRadius.circular(999)),
                    child: Text(o.kinds[i] == ShipmentKind.cargo ? (pickup ? t.warehouse : t.cargo) : (pickup ? t.store : t.courier),
                        style: _f(12, FontWeight.w600, o.kinds[i] == ShipmentKind.cargo ? c.surface : c.primaryPressed))),
                  const SizedBox(width: 8),
                  Text(pickup ? t.pickupN(i + 1, o.kinds.length) : t.shipmentN(i + 1, o.kinds.length), style: _f(13, FontWeight.w400, c.ink2)),
                ]),
                const SizedBox(height: 16),
              ],
              Text(stage(o.kinds[i], o.current[i]), style: _f(24, FontWeight.w800, o.current[i] >= 3 ? c.success : c.ink1, ls: -0.48)),
              const SizedBox(height: 6),
              Text(sub(o.kinds[i], o.current[i]), style: _f(14, FontWeight.w400, c.ink2, h: 1.45)),
              if (o.current[i] < 3) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(14)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Expanded(child: Text(pickup ? 'Будет готов к' : 'Привезём к', style: _f(13, FontWeight.w400, c.ink2))),
                    Text(o.kinds[i] == ShipmentKind.cargo ? 'завтра, 9:00–21:00' : pickup ? '14:35' : '15:20–15:35', style: _f(18, FontWeight.w700, c.ink1)),
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              OrderTimeline(stages: stages(o.kinds[i], o.current[i]), current: o.current[i]),
              if (!pickup && o.current[i] == 2) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(o.kinds[i] == ShipmentKind.cargo ? 'Водитель' : 'Курьер', style: _f(12, FontWeight.w400, c.ink2)),
                      const SizedBox(height: 2),
                      Text(o.kinds[i] == ShipmentKind.cargo ? 'Серик' : 'Ерлан', style: _f(15, FontWeight.w600, c.ink1)),
                    ])),
                    MartButton(label: 'Позвонить', variant: MartButtonVariant.ghost, size: MartButtonSize.m44, onPressed: () => launchUrl(Uri.parse('tel:+77001112233'))),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: c.divider),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => launchUrl(Uri.parse('https://wa.me/${MockData.supportWa}?text=${Uri.encodeComponent('Вопрос по заказу №${o.id}')}'), mode: LaunchMode.externalApplication),
            child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Row(children: [
              Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: c.successBg, shape: BoxShape.circle),
                  child: Container(width: 18, height: 15, decoration: BoxDecoration(border: Border.all(color: c.success, width: 2),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6), bottomRight: Radius.circular(6), bottomLeft: Radius.circular(2))))),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Написать в поддержку', style: _f(15, FontWeight.w600, c.ink1)),
                const SizedBox(height: 1),
                Text('WhatsApp', style: _f(12, FontWeight.w400, c.ink2)),
              ]),
            ])),
          ),
        ]),
        const SizedBox(height: 12),
        card([
          Text(pickup ? t.pickup : t.delivery, style: _f(13, FontWeight.w400, c.ink3)),
          const SizedBox(height: 2),
          Text(o.address, style: _f(14, FontWeight.w600, c.ink1, h: 1.4)),
          const SizedBox(height: 12),
          Text('Получатель', style: _f(13, FontWeight.w400, c.ink3)),
          const SizedBox(height: 2),
          Text('${auth.name} · ${auth.phone}', style: _f(14, FontWeight.w400, c.ink1, h: 1.4)),
        ]),
        if (o.lines.isNotEmpty) ...[
          const SizedBox(height: 12),
          card([
            Text(t.itemsCount(count), style: _f(16, FontWeight.w700, c.ink1)),
            for (final l in o.lines) Padding(padding: const EdgeInsets.only(top: 10), child: Row(children: [
              SizedBox.square(dimension: 44, child: MartImage(l.product.image, radius: 10, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(14, FontWeight.w400, c.ink1)),
                const SizedBox(height: 2),
                Text('${l.qty} × ${money(l.product.price ?? 0)}', style: _f(13, FontWeight.w400, c.ink3)),
              ])),
              const SizedBox(width: 12),
              Text(money(l.sum), style: _f(14, FontWeight.w600, c.ink1)),
            ])),
            const SizedBox(height: 12),
            Container(height: 1, color: c.divider),
            const SizedBox(height: 8),
            row(t.goods, money(o.goods)),
            if (o.discount > 0) row(t.promoLabel, '−${money(o.discount)}', color: c.success),
            if (pickup) row(t.pickup, t.free, color: c.success)
            else for (var i = 0; i < o.fees.length; i++) row('${t.delivery}${multi ? ' · ${o.kinds[i] == ShipmentKind.cargo ? t.cargo : t.courier}' : ''}', o.fees[i] == 0 ? t.free : money(o.fees[i]), color: o.fees[i] == 0 ? c.success : null),
            if (o.spent > 0) row(t.byBonus, '−${money(o.spent)}', color: c.successText, strong: true),
            const SizedBox(height: 8),
            Container(height: 1, color: c.divider),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Expanded(child: Text(t.total, style: _f(16, FontWeight.w700, c.ink1))),
              if (o.paidWith.isNotEmpty) ...[Text(o.paidWith, style: _f(13, FontWeight.w600, c.success)), const SizedBox(width: 8)],
              Text(money(o.total), style: _f(20, FontWeight.w700, c.ink1, ls: -0.2)),
            ]),
            if (o.bonus > 0 && !o.cancelled) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Container(width: 14, height: 14, alignment: Alignment.center, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                      child: const Text('Б', style: TextStyle(fontFamily: 'Onest', fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, height: 1))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(o.allDone ? 'Начислено +${o.bonus} ${plural(o.bonus, 'бонус', 'бонуса', 'бонусов')}' : t.bonusAfter(o.bonus),
                      style: _f(13, FontWeight.w400, const Color(0xFF0F6B3E), h: 1.35))),
                ]),
              ),
            ],
          ]),
        ],
        const SizedBox(height: 12),
        MartButton(label: t.continueShopping, variant: MartButtonVariant.ghost, expanded: true, onPressed: () => context.go('/')),
        if (isLive && o.canCancel) Center(child: GestureDetector(
          onTap: () => showMartSheet(context, title: '${t.cancelOrder}?', builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.refund(money(o.total)), style: _f(14, FontWeight.w400, c.ink2, h: 1.4)),
            if (o.spent > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Вернём ${o.spent} ${plural(o.spent, 'бонус', 'бонуса', 'бонусов')}', style: _f(14, FontWeight.w400, c.ink2))),
            const SizedBox(height: 20),
            MartButton(label: t.cancelOrder, variant: MartButtonVariant.danger, expanded: true, onPressed: () { context.read<OrderCubit>().cancel(); Navigator.of(ctx).pop(); }),
            const SizedBox(height: 8),
            MartButton(label: t.keepOrder, variant: MartButtonVariant.ghost, expanded: true, onPressed: () => Navigator.of(ctx).pop()),
          ])),
          child: SizedBox(height: 44, child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(t.cancelOrder, style: _f(14, FontWeight.w500, c.ink3).copyWith(decoration: TextDecoration.underline, decorationColor: c.ink3))))),
        )),
      ])),
    ]));
  }
}
