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
      bottomNavigationBar: widget.section == AccountSection.addresses && !s.loading
          ? MartBottomBar(child: MartButton(label: t.addAddress, variant: MartButtonVariant.secondary, expanded: true, onPressed: () => openAddressSheet(context, null)))
          : null,
    );
  }
}

Widget _card(BuildContext context, Widget child, {EdgeInsets padding = const EdgeInsets.all(16)}) =>
    Container(padding: padding, decoration: BoxDecoration(color: context.mc.surface, borderRadius: BorderRadius.circular(MartRadius.card)), child: child);

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
    if (items.isEmpty) return MartEmptyState(icon: Icons.favorite_border, title: t.emptyYet, text: t.favoritesEmptyHint, action: t.toCatalog, onAction: () => context.go('/catalog'));
    return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(16), sliver: ProductGridSliver(items: items))]);
  }
}

// ── Адреса ──
class _Addresses extends StatelessWidget {
  const _Addresses();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final list = context.watch<AccountCubit>().state.addresses;
    if (list.isEmpty) return MartEmptyState(icon: Icons.place_outlined, title: t.emptyYet);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      for (final a in list) Padding(padding: const EdgeInsets.only(bottom: 8), child: GestureDetector(
        onTap: () => openAddressSheet(context, a),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card), border: Border.all(color: a.isDefault ? c.primary100 : Colors.transparent, width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(a.title, style: MartText.bodyStrong.copyWith(color: c.ink1))),
              if (a.isDefault) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(MartRadius.pill)),
                child: Text(t.mainLabel, style: MartText.caption.copyWith(fontWeight: FontWeight.w600, color: c.primaryPressed))),
            ]),
            const SizedBox(height: 4),
            Text('${a.city}, ${a.street}', style: MartText.small.copyWith(color: c.ink1)),
            if (a.details.isNotEmpty) Text(a.details, style: MartText.caption.copyWith(fontSize: 13, color: c.ink2)),
          ]),
        ),
      )),
    ]);
  }
}

/// Добавить / изменить адрес. В проде — та же шторка с картой, что и «Способ получения» (address-only).
Future<void> openAddressSheet(BuildContext context, Address? a) {
  final t = L10n.of(context);
  final cubit = context.read<AccountCubit>();
  final title = TextEditingController(text: a?.title ?? ''), street = TextEditingController(text: a?.street ?? ''),
      entrance = TextEditingController(text: a?.entrance ?? ''), floor = TextEditingController(text: a?.floor ?? ''), flat = TextEditingController(text: a?.flat ?? '');
  return showMartSheet(context, title: a == null ? t.addAddress : t.change, builder: (ctx) => StatefulBuilder(builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Container(height: 140, alignment: Alignment.center, decoration: BoxDecoration(color: ctx.mc.surface2, borderRadius: BorderRadius.circular(MartRadius.field)),
      child: Text('Mapbox · пин по центру', style: MartText.small.copyWith(color: ctx.mc.ink3))),
    const SizedBox(height: 12),
    MartInput(label: t.street, required: true, controller: street, onChanged: (_) => set(() {})),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: MartInput(label: t.entrance, type: MartInputType.number, controller: entrance)), const SizedBox(width: 8),
      Expanded(child: MartInput(label: t.floor, type: MartInputType.number, controller: floor)), const SizedBox(width: 8),
      Expanded(child: MartInput(label: t.flat, controller: flat)),
    ]),
    const SizedBox(height: 8),
    MartInput(label: t.addressTitle, controller: title),
    const SizedBox(height: 16),
    MartButton(label: t.save, expanded: true, disabledReason: street.text.trim().isEmpty ? t.errRequired : null, onPressed: () {
      cubit.saveAddress((a ?? Address(id: DateTime.now().microsecondsSinceEpoch.toString(), title: '', street: '', city: 'Астана'))
          .copyWith(title: title.text.trim().isEmpty ? street.text.trim() : title.text.trim(), street: street.text.trim(), entrance: entrance.text, floor: floor.text, flat: flat.text));
      Navigator.of(ctx).pop();
    }),
    if (a != null) ...[
      if (!a.isDefault) ...[const SizedBox(height: 8), MartButton(label: t.makeMain, variant: MartButtonVariant.ghost, expanded: true, onPressed: () { cubit.setDefaultAddress(a.id); Navigator.of(ctx).pop(); })],
      const SizedBox(height: 8),
      MartButton(label: t.delete, variant: MartButtonVariant.danger, expanded: true, onPressed: () { cubit.deleteAddress(a.id); Navigator.of(ctx).pop(); }),
    ],
  ])));
}

// ── Способы оплаты ──
class _Payments extends StatelessWidget {
  const _Payments();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final cards = context.watch<AccountCubit>().state.cards;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      _card(context, MartListRow(title: 'Kaspi Pay', sub: t.kaspiNoBind, chevron: false,
          leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: SvgPicture.asset('assets/images/kaspi-logo.svg', package: MartAssets.package, width: 28, height: 28))),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      const SizedBox(height: 8),
      for (final k in cards) Padding(padding: const EdgeInsets.only(bottom: 8), child: _card(context, Row(children: [
        Icon(Icons.credit_card, color: c.ink1), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k.title, style: MartText.bodyStrong.copyWith(color: c.ink1)),
          Text('до ${k.exp}${k.isDefault ? ' · ${t.mainLabel.toLowerCase()}' : ''}', style: MartText.caption.copyWith(fontSize: 13, color: c.ink2)),
        ])),
        TextButton(onPressed: () => context.read<AccountCubit>().deleteCard(k.id), child: Text(t.delete, style: MartText.small.copyWith(color: c.error))),
      ]))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), child: Text(t.cardsByGateway, style: MartText.small.copyWith(color: c.ink2))),
    ]);
  }
}

// ── Промокоды ──
class _Promos extends StatelessWidget {
  const _Promos();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final list = context.watch<AccountCubit>().state.promos;
    if (list.isEmpty) return MartEmptyState(icon: Icons.local_offer_outlined, title: t.emptyYet);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      for (final p in list) Padding(padding: const EdgeInsets.only(bottom: 8), child: Opacity(
        opacity: p.status == PromoStatus.active ? 1 : .5,
        child: _card(context, Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, style: MartText.bodyStrong.copyWith(color: c.ink1)),
            Text(t.validUntil(p.cond, p.until), style: MartText.caption.copyWith(fontSize: 13, color: c.ink2)),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(MartRadius.pill)),
              child: Text(p.code, style: MartText.small.copyWith(fontWeight: FontWeight.w700, letterSpacing: .6, color: c.successText))),
          ])),
          if (p.status == PromoStatus.active)
            MartButton(label: t.copy, variant: MartButtonVariant.ghost, size: MartButtonSize.s36, onPressed: () {
              Clipboard.setData(ClipboardData(text: p.code));
              showMartToast(context, t.copied);
            })
          else Text(p.status == PromoStatus.used ? t.promoUsed : t.promoExpired, style: MartText.small.copyWith(color: c.ink3)),
        ])),
      )),
    ]);
  }
}

// ── Бонусы ── (правила — МОК, уточнить у бизнеса)
class _Bonus extends StatelessWidget {
  const _Bonus();
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final s = context.watch<AccountCubit>().state;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      _card(context, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.onAccount, style: MartText.small.copyWith(color: c.ink2)),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text('${s.bonusBalance}', style: MartText.h1.copyWith(fontSize: 40, color: c.ink1)),
          const SizedBox(width: 10), BonusBadge(amount: s.bonusBalance),
        ]),
        const SizedBox(height: 8),
        Text(t.bonusRules(MockData.bonusMaxPart), style: MartText.small.copyWith(color: c.ink2)),
      ])),
      const SizedBox(height: 16),
      Text(t.history, style: MartText.title.copyWith(color: c.ink1)),
      const SizedBox(height: 8),
      _card(context, Column(children: [
        for (final op in s.bonusHistory) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(op.title, style: MartText.small.copyWith(color: c.ink1)), Text(op.date, style: MartText.caption.copyWith(color: c.ink3)),
          ])),
          Text(op.amount > 0 ? '+${op.amount}' : '${op.amount}', style: MartText.bodyStrong.copyWith(color: op.amount > 0 ? c.successText : c.ink2)),
        ])),
      ]), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
    ]);
  }
}

// ── Личные данные ──
class _Personal extends StatefulWidget {
  const _Personal();
  @override
  State<_Personal> createState() => _PersonalState();
}

class _PersonalState extends State<_Personal> {
  late final _name = TextEditingController(text: context.read<AuthCubit>().state.name);
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final auth = context.watch<AuthCubit>().state;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
      _card(context, Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        MartInput(label: t.name, required: true, controller: _name, onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        MartButton(label: t.save, expanded: true, disabledReason: _name.text.trim().isEmpty || _name.text.trim() == auth.name ? '' : null,
            onPressed: () { context.read<AuthCubit>().rename(_name.text); FocusScope.of(context).unfocus(); }),
      ])),
      const SizedBox(height: 8),
      _card(context, MartListRow(title: t.phone, sub: auth.phone, value: t.change, valueColor: c.primary, chevron: false, onTap: () => openChangePhoneSheet(context)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
      const SizedBox(height: 32),
      Center(child: TextButton(onPressed: () => _confirmDelete(context), child: Text(t.deleteAccount, style: MartText.small.copyWith(color: c.ink3, decoration: TextDecoration.underline)))),
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
        if (v == '0000') { set(() => code = CodeState.error); return; }
        set(() => code = CodeState.success);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (ctx.mounted) { context.read<AuthCubit>().changePhone(phone.text); Navigator.of(ctx).pop(); }
      }),
      if (code == CodeState.error) Padding(padding: const EdgeInsets.only(top: 10), child: Text(t.codeWrong, textAlign: TextAlign.center, style: MartText.small.copyWith(color: ctx.mc.error))),
    ]);
  }));
}
