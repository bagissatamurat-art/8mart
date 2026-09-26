import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/shipments.dart';
import '../../state/order_cubit.dart';
import '../../state/settings_cubit.dart';

class OrderStatusScreen extends StatelessWidget {
  const OrderStatusScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final o = context.watch<OrderCubit>().state;
    final settings = context.watch<SettingsCubit>();
    final pickup = o.method == ReceiveMethod.pickup;
    final multi = o.kinds.length > 1;

    List<TimelineStage> stagesFor(ShipmentKind k) => [
          TimelineStage(t.stAccepted, sub: 'Оплата прошла, передали заказ', time: '14:05'),
          TimelineStage(t.stAssembling, sub: k == ShipmentKind.cargo ? 'Комплектуем на складе' : 'Проверяем наличие и упаковываем', time: '14:07'),
          TimelineStage(pickup ? t.stReady : k == ShipmentKind.cargo ? t.stCargo : t.stCourier, sub: pickup ? 'Покажите номер заказа на кассе' : 'Позвоним за 10–15 минут до приезда'),
          TimelineStage(pickup ? t.stIssued : t.stDelivered),
        ];

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(t.orderNo(id))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        if (!settings.state.pushAsked && !o.cancelled) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(MartRadius.card)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.pushAsk, style: MartText.title.copyWith(color: c.ink1)),
              const SizedBox(height: 4),
              Text(t.pushAskSub, style: MartText.small.copyWith(color: c.ink2)),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: o.cancelled
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.stCancelled, style: MartText.h2.copyWith(color: c.error)),
                  const SizedBox(height: 6),
                  Text(t.refund(money(o.total)), style: MartText.small.copyWith(color: c.ink2)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (var i = 0; i < o.kinds.length; i++) ...[
                    if (i > 0) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: c.divider)),
                    if (multi) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(
                      '${pickup ? t.pickupN(i + 1, o.kinds.length) : t.shipmentN(i + 1, o.kinds.length)} · ${o.kinds[i] == ShipmentKind.cargo ? t.cargo : t.courier}',
                      style: MartText.caption.copyWith(fontSize: 13, color: c.ink2))),
                    Text(stagesFor(o.kinds[i])[o.current[i].clamp(0, 3)].title, style: MartText.h2.copyWith(color: o.current[i] >= 3 ? c.success : c.ink1)),
                    const SizedBox(height: 16),
                    OrderTimeline(stages: stagesFor(o.kinds[i]), current: o.current[i]),
                  ],
                ]),
        ),
        const SizedBox(height: 12),
        if (o.bonus > 0 && !o.cancelled) Text(o.allDone ? 'Начислено +${o.bonus}' : t.bonusAfter(o.bonus), style: MartText.small.copyWith(color: c.successText)),
        const SizedBox(height: 12),
        MartButton(label: t.support, variant: MartButtonVariant.ghost, expanded: true,
            onPressed: () => launchUrl(Uri.parse('https://wa.me/${MockData.supportWa}?text=${Uri.encodeComponent('Вопрос по заказу №$id')}'), mode: LaunchMode.externalApplication)),
        const SizedBox(height: 8),
        MartButton(label: t.continueShopping, variant: MartButtonVariant.secondary, expanded: true, onPressed: () => context.go('/')),
        if (o.canCancel) Center(child: TextButton(
          onPressed: () => showMartSheet(context, title: '${t.cancelOrder}?', builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(t.refund(money(o.total)), style: MartText.small.copyWith(color: c.ink2)),
            const SizedBox(height: 20),
            MartButton(label: t.cancelOrder, variant: MartButtonVariant.danger, expanded: true, onPressed: () { context.read<OrderCubit>().cancel(); Navigator.of(ctx).pop(); }),
            const SizedBox(height: 8),
            MartButton(label: t.keepOrder, variant: MartButtonVariant.ghost, expanded: true, onPressed: () => Navigator.of(ctx).pop()),
          ])),
          child: Text(t.cancelOrder, style: MartText.small.copyWith(color: c.ink3, decoration: TextDecoration.underline)),
        )),
      ]),
    );
  }
}
