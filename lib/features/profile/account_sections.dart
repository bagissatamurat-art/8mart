import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/format.dart';
import '../../core/phone_mask.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/account_cubit.dart';
import '../../state/auth_cubit.dart';
import '../../state/cart_cubit.dart';
import '../../state/favorites_cubit.dart';
import '../../ui/ui.dart';
import '../common/product_grid.dart';
import 'order_labels.dart';
import '../method/method_sheet.dart';

enum AccountSection { orders, favorites, addresses, payments, promos, bonus, personal }

String sectionTitle(L10n t, AccountSection s) => switch (s) {
      AccountSection.orders => t.myOrders, AccountSection.favorites => t.favorites, AccountSection.addresses => t.addresses,
      AccountSection.payments => t.paymentMethods, AccountSection.promos => t.promocodes, AccountSection.bonus => t.bonuses, AccountSection.personal => t.personalData,
    };

/// /profile/:section — общий каркас: назад, заголовок, загрузка → скелетоны.
class AccountSectionScreen extends StatefulWidget {
  const AccountSectionScreen({super.key, required this.section});
  final AccountSection section;
  @override
  State<AccountSectionScreen> createState() => _AccountSectionScreenState();
}

class _AccountSectionScreenState extends State<AccountSectionScreen> {
  @override
  void initState() { super.initState(); context.read<AccountCubit>().load(); }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final s = context.watch<AccountCubit>().state;
    final body = s.loading && widget.section != AccountSection.favorites
        ? ListView(padding: const EdgeInsets.all(16), children: const [MartSkeletonRow(), SizedBox(height: 8), MartSkeletonRow(), SizedBox(height: 8), MartSkeletonRow()])
        : switch (widget.section) {
            AccountSection.orders => const _Orders(),
            AccountSection.favorites => const _Favorites(),
            AccountSection.addresses => const _Addresses(),
            AccountSection.payments => const _Payments(),
            AccountSection.promos => const _Promos(),
            AccountSection.bonus => const _Bonus(),
            AccountSection.personal => const _Personal(),
          };
    return Scaffold(
      // Раздел 390 (#6c): белая панель — назад 40 + заголовок 22/800.
      body: Column(children: [
        MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [MartTitleRow(title: sectionTitle(t, widget.section), onBack: () => context.go('/profile'))]),
        Expanded(child: body),
      ]),
    );
  }
}

// ── Мои заказы (MartAccount mobile): активный — розовая рамка, «Привезём к», шкала с подписями, «Следить за заказом»; «История» — карточки с чипом статуса ──
TextStyle _fs(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

class _Orders extends StatelessWidget {
  const _Orders();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final s = context.watch<AccountCubit>().state;
    if (s.orders.isEmpty) return MartEmptyState(title: t.emptyYet, text: t.ordersEmptyHint, action: t.toCatalog, onAction: () => context.go('/catalog'));
    final active = s.orders.where((o) => o.isActive).toList(), past = s.orders.where((o) => !o.isActive).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      for (final o in active) ...[_ActiveOrder(o), const SizedBox(height: 10)],
      if (past.isNotEmpty) Padding(padding: const EdgeInsets.fromLTRB(4, 4, 4, 10), child: Text(t.history, style: _fs(16, FontWeight.w700, c.ink1))),
      for (final o in past) ...[_PastOrder(o), const SizedBox(height: 10)],
    ]);
  }
}

class _ActiveOrder extends StatelessWidget {
  const _ActiveOrder(this.o);
  final OrderSummary o;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final cur = orderStep(o);
    final labels = orderSteps(o);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card), border: Border.all(color: const Color(0xFFF7C6DC), width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Заказ №${o.id} · ${o.date}', style: _fs(13, FontWeight.w400, c.ink3)),
            const SizedBox(height: 4),
            Text(orderStatusLabel(o), style: _fs(20, FontWeight.w800, c.ink1, ls: -0.4)),
            const SizedBox(height: 4),
            Text(o.address, style: _fs(14, FontWeight.w400, c.ink2, h: 1.4)),
          ])),
          if (o.eta != null) ...[
            const SizedBox(width: 12),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(o.method == ReceiveMethod.pickup ? 'Будет готов к' : 'Привезём к', style: _fs(12, FontWeight.w400, c.ink2)),
                const SizedBox(height: 2),
                Text(o.eta!, style: _fs(16, FontWeight.w700, c.ink1)),
              ])),
          ],
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 4, decoration: BoxDecoration(color: i < cur ? c.success : i == cur ? c.primary : c.divider, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 6),
              Text(labels[i], style: _fs(12, i == cur ? FontWeight.w600 : FontWeight.w400, i <= cur ? c.ink1 : c.ink3, h: 1.3)),
            ])),
          ],
        ]),
        const SizedBox(height: 16),
        MartButton(label: 'Следить за заказом', size: MartButtonSize.m44, expanded: true, onPressed: () => context.push('/order/${o.id}')),
      ]),
    );
  }
}

class _PastOrder extends StatelessWidget {
  const _PastOrder(this.o);
  final OrderSummary o;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final cancelled = o.status == OrderStatus.cancelled;
    final (chipBg, chipFg) = orderTone(o.status);
    final ids = o.items.keys.toList();
    final n = ids.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('№${o.id}', style: _fs(15, FontWeight.w600, c.ink1)),
          Text(o.date, style: _fs(13, FontWeight.w400, c.ink3)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(999)),
              child: Text(orderStatusLabel(o), style: _fs(12, FontWeight.w600, chipFg))),
          if (o.status == OrderStatus.done && o.bonus > 0) BonusBadge(amount: o.bonus, compact: true),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          for (final id in ids.take(4)) if (MockData.byId(id) case final p?) Padding(padding: const EdgeInsets.only(right: 6),
              child: Opacity(opacity: cancelled ? .5 : 1, child: SizedBox.square(dimension: 44, child: MartImage(p.image, radius: 10, fit: BoxFit.cover)))),
          if (n > 4) Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
              child: Text('+${n - 4}', style: _fs(13, FontWeight.w600, c.ink2))),
        ]),
        const SizedBox(height: 10),
        Text('$n ${plural(n, 'позиция', 'позиции', 'позиций')} · ${o.method == ReceiveMethod.pickup ? 'Самовывоз' : 'Доставка'}, ${o.address}', style: _fs(13, FontWeight.w400, c.ink2)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Text(money(o.total), style: _fs(17, FontWeight.w700, cancelled ? c.ink3 : c.ink1).copyWith(decoration: cancelled ? TextDecoration.lineThrough : null, decorationColor: c.ink3))),
          GestureDetector(onTap: () => context.push('/order/${o.id}'), child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.center,
              child: Text(t.details, style: _fs(14, FontWeight.w600, c.ink2)))),
          const SizedBox(width: 4),
          MartButton(label: t.repeat, variant: MartButtonVariant.secondary, size: MartButtonSize.s40, onPressed: () {
            context.read<CartCubit>().addAll(o.items);
            showMartToast(context, t.addedFromOrder, action: t.open, onAction: () => context.go('/cart'));
          }),
        ]),
      ]),
    );
  }
}

// ── Избранное ──
class _Favorites extends StatelessWidget {
  const _Favorites();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final ids = context.watch<FavoritesCubit>().state;
    final items = [for (final id in ids) if (MockData.byId(id) case final p?) p];
    final c = context.mc;
    // Пусто (MartAccount): белая карточка — контур сердца 40, «Пока пусто», подсказка.
    if (items.isEmpty) {
      return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: Column(children: [
            const Icon(Icons.favorite_border, size: 40, color: Color(0xFFC9C7CE)),
            const SizedBox(height: 8),
            Text(t.emptyYet, style: _fs(17, FontWeight.w700, c.ink1)),
            const SizedBox(height: 8),
            Text('Нажмите на сердце в карточке товара, чтобы сохранить его здесь', textAlign: TextAlign.center, style: _fs(14, FontWeight.w400, c.ink2, h: 1.4)),
          ]),
        ),
      ]);
    }
    return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), sliver: ProductGridSliver(items: items))]);
  }
}

// ── Адреса ──
class _Addresses extends StatelessWidget {
  const _Addresses();
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final cubit = context.read<AccountCubit>();
    final list = context.watch<AccountCubit>().state.addresses;
    Widget act(String label, VoidCallback onTap, {bool pink = false}) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap,
        child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 8), alignment: Alignment.center, child: Text(label, style: _fs(14, FontWeight.w600, pink ? c.primary : c.ink2))));
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      for (final a in list) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card), border: Border.all(color: a.isDefault ? const Color(0xFFF7C6DC) : Colors.transparent, width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(a.title, style: _fs(16, FontWeight.w700, c.ink1)),
              if (a.isDefault) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(999)),
                  child: Text('Основной', style: _fs(12, FontWeight.w600, c.primary)))],
            ]),
            const SizedBox(height: 4),
            Text('${a.street}, ${a.city}', style: _fs(15, FontWeight.w400, c.ink1, h: 1.4)),
            if (a.details.isNotEmpty) ...[const SizedBox(height: 4), Text(a.details, style: _fs(13, FontWeight.w400, c.ink2))],
            const SizedBox(height: 8),
            Transform.translate(offset: const Offset(-8, 0), child: Wrap(spacing: 4, children: [
              if (!a.isDefault) act('Сделать основным', () => cubit.setDefaultAddress(a.id), pink: true),
              act('Изменить', () => openAddressSheet(context, a)),
              act('Удалить', () => cubit.deleteAddress(a.id)),
            ])),
          ]),
        ),
        const SizedBox(height: 10),
      ],
      GestureDetector(onTap: () => openAddressSheet(context, null), child: CustomPaint(
        foregroundPainter: _DashedBox(c.border),
        child: SizedBox(height: 56, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          MartPlusMinus(plus: true, color: c.primary, size: 14),
          const SizedBox(width: 10),
          Text('Добавить адрес', style: _fs(15, FontWeight.w600, c.ink1)),
        ])),
      )),
    ]);
  }
}

class _DashedBox extends CustomPainter {
  _DashedBox(this.color, {this.radius = MartRadius.card});
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(.75));
    final p = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) { for (double d = 0; d < m.length; d += 9) { canvas.drawPath(m.extractPath(d, d + 5), p); } }
  }
  @override
  bool shouldRepaint(_DashedBox o) => o.color != color;
}

/// Добавить / изменить адрес — та же шторка с картой, что «Способ получения», в режиме address-only (название, «Сохранить адрес»).
Future<void> openAddressSheet(BuildContext context, Address? a) {
  final cubit = context.read<AccountCubit>();
  return openMethodSheet(context, address: AddressDraft(title: a?.title ?? '', street: a?.street ?? '', city: a?.city ?? 'Астана', entrance: a?.entrance ?? '', flat: a?.flat ?? ''),
      onSaveAddress: (d) => cubit.saveAddress((a ?? Address(id: DateTime.now().microsecondsSinceEpoch.toString(), title: '', street: '', city: d.city))
          .copyWith(title: d.title.trim().isEmpty ? d.street : d.title.trim(), street: d.street, entrance: d.entrance, flat: d.flat)));
}

// ── Способы оплаты (MartAccount mobile): Kaspi без привязки, карты — маска от шлюза, «Основная», × удалить ──
class _Payments extends StatelessWidget {
  const _Payments();
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final cards = context.watch<AccountCubit>().state.cards;
    Widget row(Widget icon, Widget body, {Widget? trailing}) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: Row(children: [icon, const SizedBox(width: 14), Expanded(child: body), if (trailing != null) trailing]),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      row(ClipRRect(borderRadius: BorderRadius.circular(10), child: SvgPicture.asset('assets/images/kaspi-logo.svg', package: MartAssets.package, width: 40, height: 40)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kaspi Pay', style: _fs(15, FontWeight.w600, c.ink1)),
            const SizedBox(height: 2),
            Text('Оплата в приложении Kaspi — привязывать не нужно', style: _fs(13, FontWeight.w400, c.ink2, h: 1.4)),
          ])),
      for (final k in cards) ...[
        const SizedBox(height: 10),
        row(
          Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(10)),
            child: Container(width: 24, height: 17, decoration: BoxDecoration(border: Border.all(color: c.ink1, width: 2), borderRadius: BorderRadius.circular(3)),
                child: Align(alignment: const Alignment(0, -.3), child: Container(height: 2, color: c.ink1)))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(k.title, style: _fs(15, FontWeight.w600, c.ink1)),
              if (k.isDefault) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(999)),
                  child: Text('Основная', style: _fs(12, FontWeight.w600, c.primary)))],
            ]),
            const SizedBox(height: 2),
            Text('Действует до ${k.exp}', style: _fs(13, FontWeight.w400, c.ink2)),
          ]),
          trailing: Semantics(button: true, label: 'Удалить карту', child: GestureDetector(
            onTap: () => context.read<AccountCubit>().deleteCard(k.id),
            child: SizedBox.square(dimension: 44, child: Center(child: MartCross(size: 14, color: c.ink2))))),
        ),
      ],
      Padding(padding: const EdgeInsets.fromLTRB(4, 10, 4, 0), child: Text('Новая карта сохранится при следующей оплате картой онлайн', style: _fs(13, FontWeight.w400, c.ink2, h: 1.4))),
    ]);
  }
}

// ── Промокоды (MartAccount): код в пунктирной рамке · название · условие и срок · «Скопировать» → «Скопировано» ──
class _Promos extends StatefulWidget {
  const _Promos();
  @override
  State<_Promos> createState() => _PromosState();
}

class _PromosState extends State<_Promos> {
  String? _copied;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final list = context.watch<AccountCubit>().state.promos;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      for (final p in list) ...[
        Opacity(opacity: p.status == PromoStatus.active ? 1 : .5, child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: Row(children: [
            CustomPaint(foregroundPainter: _DashedBox(p.status == PromoStatus.active ? c.primary : const Color(0xFFC9C7CE), radius: 12), child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(p.code, style: _fs(15, FontWeight.w700, p.status == PromoStatus.active ? c.primary : c.ink2, ls: .9)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.title, style: _fs(15, FontWeight.w600, c.ink1)),
              const SizedBox(height: 2),
              Text('${p.cond} · ${p.until}', style: _fs(13, FontWeight.w400, c.ink2)),
            ])),
            if (p.status == PromoStatus.active) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () { Clipboard.setData(ClipboardData(text: p.code)); setState(() => _copied = p.code); },
                child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center,
                  decoration: BoxDecoration(color: _copied == p.code ? c.successBg : c.surface2, borderRadius: BorderRadius.circular(999)),
                  child: Text(_copied == p.code ? 'Скопировано' : 'Скопировать', style: _fs(14, FontWeight.w600, _copied == p.code ? c.success : c.ink1))),
              ),
            ],
          ]),
        )),
        const SizedBox(height: 10),
      ],
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text('Промокод вводится в корзине или при оформлении', style: _fs(13, FontWeight.w400, c.ink2, h: 1.4))),
    ]);
  }
}

// ── Бонусы (MartAccount): тёмная карточка баланса 40/800 + правила; «История» — строки с разделителями ──
class _Bonus extends StatelessWidget {
  const _Bonus();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final s = context.watch<AccountCubit>().state;
    const muted = Color(0xFFC9C7CE);
    String grp(int n) => money(n.abs()).replaceAll(RegExp(r'\s*тг\.'), '');
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF17151A), borderRadius: BorderRadius.circular(MartRadius.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ваш баланс', style: _fs(14, FontWeight.w400, muted)),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(grp(s.bonusBalance), style: _fs(40, FontWeight.w800, Colors.white, ls: -0.8)),
            const SizedBox(width: 10),
            Text(plural(s.bonusBalance, 'бонус', 'бонуса', 'бонусов'), style: _fs(16, FontWeight.w400, muted)),
          ]),
          const SizedBox(height: 8),
          Text.rich(TextSpan(text: '1 бонус = 1 тг · за товары с отметкой ', children: [
            const WidgetSpan(alignment: PlaceholderAlignment.middle, child: BonusBadge(amount: 0, compact: true, label: '+N')),
            TextSpan(text: ' начисляем бонусы после получения заказа · оплачивайте бонусами до ${MockData.bonusMaxPart}% суммы товаров'),
          ]), style: _fs(14, FontWeight.w400, muted, h: 1.5)),
        ]),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t.history, style: _fs(16, FontWeight.w700, c.ink1))),
          for (final op in s.bonusHistory) Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(op.title, style: _fs(14, FontWeight.w400, c.ink1, h: 1.4)),
                const SizedBox(height: 2),
                Text(op.date, style: _fs(13, FontWeight.w400, c.ink3)),
              ])),
              const SizedBox(width: 12),
              Text('${op.amount > 0 ? '+' : '−'}${grp(op.amount)}', style: _fs(15, FontWeight.w700, op.amount > 0 ? c.success : c.ink1)),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

class _Personal extends StatefulWidget {
  const _Personal();
  @override
  State<_Personal> createState() => _PersonalState();
}

class _PersonalState extends State<_Personal> {
  late final _name = TextEditingController(text: context.read<AuthCubit>().state.name);
  bool _saved = false;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final auth = context.watch<AuthCubit>().state;
    // Личные данные (MartAccount): карточка — «Имя», серый блок «Телефон» с «Изменить»; «Сохранить» — только если имя изменено; «Удалить аккаунт» серой ссылкой.
    final dirty = _name.text.trim() != auth.name;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MartInput(label: t.name, required: true, controller: _name, error: _name.text.trim().isEmpty ? 'Укажите имя' : null, onChanged: (_) => setState(() => _saved = false)),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 56), padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MartRadius.field)),
            child: Row(children: [
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.phone, style: _fs(12, FontWeight.w400, c.ink2)),
                const SizedBox(height: 2),
                Text(auth.phone, style: _fs(16, FontWeight.w400, c.ink1)),
              ])),
              GestureDetector(onTap: () => openChangePhoneSheet(context), child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(999)), child: Text(t.change, style: _fs(14, FontWeight.w600, c.primary)))),
            ]),
          ),
          if (dirty) ...[
            const SizedBox(height: 16),
            MartButton(label: t.save, expanded: true, disabledReason: _name.text.trim().isEmpty ? 'Укажите имя' : null,
                onPressed: () { context.read<AuthCubit>().rename(_name.text); FocusScope.of(context).unfocus(); setState(() => _saved = true); }),
          ],
          if (_saved && !dirty) ...[const SizedBox(height: 16), Text('Сохранено', style: _fs(14, FontWeight.w600, c.success))],
        ]),
      ),
      const SizedBox(height: 10),
      Align(alignment: Alignment.centerLeft, child: GestureDetector(
        onTap: () => _confirmDelete(context),
        child: SizedBox(height: 44, child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(t.deleteAccount, style: _fs(14, FontWeight.w500, c.ink3).copyWith(decoration: TextDecoration.underline, decorationColor: c.ink3))))),
      )),
    ]);
  }

  void _confirmDelete(BuildContext context) {
    final t = L10n.of(context);
    showMartSheet(context, title: '${t.deleteAccount}?', builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(t.deleteAccountText, style: MartText.small.copyWith(color: ctx.mc.ink2)),
      const SizedBox(height: 20),
      MartButton(label: t.deleteAccount, variant: MartButtonVariant.danger, expanded: true, onPressed: () {
        // В проде: DELETE /me → очистить токены в secure storage
        Navigator.of(ctx).pop();
        context.read<AuthCubit>().logout();
        context.read<AccountCubit>().reset();
        context.read<CartCubit>().clearCart();
        context.go('/');
        showMartToast(context, t.accountDeleted);
      }),
      const SizedBox(height: 8),
      MartButton(label: t.cancel, variant: MartButtonVariant.ghost, expanded: true, onPressed: () => Navigator.of(ctx).pop()),
    ]));
  }
}

/// Смена телефона: новый номер → код в WhatsApp (как при входе, purpose=changePhone) → сохранено.
Future<void> openChangePhoneSheet(BuildContext context) {
  final t = L10n.of(context);
  final phone = TextEditingController();
  var step = 0;
  var code = CodeState.idle;
  return showMartSheet(context, title: t.changePhone, builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
    if (step == 0) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        MartInput(label: t.newPhone, type: MartInputType.phone, required: true, controller: phone, onChanged: (_) => set(() {})),
        const SizedBox(height: 16),
        MartButton(label: t.getCode, expanded: true, disabledReason: PhoneMaskFormatter.isComplete(phone.text) ? null : t.errPhone, onPressed: () => set(() => step = 1)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(t.codeSent(phone.text), style: MartText.small.copyWith(color: ctx.mc.ink2)),
      const SizedBox(height: 16),
      MartCodeInput(state: code, onCompleted: (v) async {
        set(() => code = CodeState.checking);
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (v != '1234') { set(() => code = CodeState.error); return; }
        set(() => code = CodeState.success);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (ctx.mounted) { context.read<AuthCubit>().changePhone(phone.text); Navigator.of(ctx).pop(); }
      }),
      if (code == CodeState.error) Padding(padding: const EdgeInsets.only(top: 10), child: Text(t.codeWrong, textAlign: TextAlign.center, style: MartText.small.copyWith(color: ctx.mc.error))),
    ]);
  }));
}
