import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../data/mock_data.dart';
import '../../domain/shipments.dart';
import '../../domain/slots.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';

/// «Вопросы и ответы» (Профиль) — те же 10 вопросов, что на сайте. Цифры — из конфигурации (тарифы, слоты, бонусы, города), не текстом.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    const ship = ShippingConfig(), slots = SlotConfig();
    final items = [
      (t.faq1Q, t.faq1A('${ship.etaMin}–${ship.etaMax}', slots.courierIntervals.join(', '))),
      (t.faq2Q, t.faq2A(moneyText(ship.courierFee), moneyText(ship.freeFrom))),
      (t.faq3Q, t.faq3A),
      (t.faq4Q, t.faq4A(MockData.cities.map((x) => x.name).join(', '))),
      (t.faq5Q, t.faq5A),
      (t.faq6Q, t.faq6A),
      (t.faq7Q, t.faq7A),
      (t.faq8Q, t.faq8A(MockData.bonusMaxPart)),
      (t.faq9Q, t.faq9A),
      (t.faq10Q, t.faq10A(MockData.supportPhone)),
    ];
    return Scaffold(
      appBar: AppBar(leading: const Padding(padding: EdgeInsets.only(left: 8), child: Center(child: MartBackButton())), leadingWidth: 60, title: Text(t.faqTitle)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        Container(
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: Theme(
            // Без линий ExpansionTile сверху и снизу — разделители рисуем сами.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Column(children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, indent: 16, endIndent: 16, color: c.divider),
                ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  iconColor: c.primary, collapsedIconColor: c.ink2, expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(items[i].$1, style: MartText.bodyStrong.copyWith(color: c.ink1)),
                  children: [Text(items[i].$2, style: MartText.small.copyWith(color: c.ink2, height: 1.5))],
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
