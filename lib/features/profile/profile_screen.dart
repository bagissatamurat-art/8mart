import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../state/account_cubit.dart';
import '../../state/auth_cubit.dart';
import '../../state/favorites_cubit.dart';
import '../../ui/ui.dart';
import '../auth/auth_view.dart';
import 'account_sections.dart';
import 'order_labels.dart';

TextStyle _f(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

/// Профиль 390 (06 Личный кабинет.dc.html #6b): белая панель — аватар 52 + имя 20/800 + телефон;
/// активный заказ (розовая рамка, «к 15:20», шкала из 4 полос) → разделы строками 56 со счётчиками → «Выйти».
/// «Настройки» — только в приложении (язык, тема, уведомления, документы — APP_SPEC).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final auth = context.watch<AuthCubit>().state;
    final acc = context.watch<AccountCubit>().state;
    final favs = context.watch<FavoritesCubit>().state.length;
    if (auth.authed) context.read<AccountCubit>().load(); // один раз, повторные вызовы игнорируются

    if (!auth.authed) {
      return Scaffold(body: Column(children: [
        MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [Text(t.tabProfile, style: _f(24, FontWeight.w800, c.ink1, ls: -0.48))]),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)), child: const AuthView()),
          const SizedBox(height: 12),
          _Row(label: t.settings, onTap: () => context.go('/profile/settings')),
        ])),
      ]));
    }

    String? badge(AccountSection s) => switch (s) {
          AccountSection.orders => acc.active != null ? '1 активный' : null,
          AccountSection.favorites => favs > 0 ? '$favs' : null,
          AccountSection.promos => acc.promos.isEmpty ? null : '${acc.promos.where((p) => p.status.name == 'active').length}',
          AccountSection.bonus => acc.loading ? null : '${acc.bonusBalance}',
          _ => null,
        };
    final active = acc.active;
    return Scaffold(body: Column(children: [
      MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), children: [
        Row(children: [
          Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: c.primary50, shape: BoxShape.circle),
              child: Text(auth.name.isEmpty ? '?' : auth.name[0].toUpperCase(), style: _f(20, FontWeight.w700, c.primary))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auth.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(20, FontWeight.w800, c.ink1, ls: -0.4)),
            const SizedBox(height: 2),
            Text(auth.phone, style: _f(14, FontWeight.w400, c.ink2)),
          ])),
        ]),
      ]),
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
        if (active != null) ...[
          GestureDetector(
            onTap: () => context.push('/order/${active.id}'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card), border: Border.all(color: const Color(0xFFF7C6DC), width: 1.5)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text('Активный заказ №${active.id}', style: _f(13, FontWeight.w400, c.ink3))),
                  MartChevron(color: c.ink3, size: 5),
                ]),
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Expanded(child: Text(orderStatusLabel(active), style: _f(18, FontWeight.w800, c.ink1))),
                  if (active.eta != null) Text('к ${active.eta!.split('–').first}', style: _f(14, FontWeight.w400, c.ink2)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(
                        color: i < orderStep(active) ? c.success : i == orderStep(active) ? c.primary : c.divider, borderRadius: BorderRadius.circular(2)))),
                  ],
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
          child: Column(children: [
            for (final s in AccountSection.values) _NavRow(label: sectionTitle(t, s), badge: badge(s), badgeColor: s == AccountSection.bonus ? c.successText : c.ink2, onTap: () => context.go('/profile/${s.name}')),
            _NavRow(label: t.settings, onTap: () => context.go('/profile/settings')),
          ]),
        ),
        const SizedBox(height: 12),
        _Row(label: t.logout, muted: true, chevron: false, onTap: () { context.read<AuthCubit>().logout(); context.read<AccountCubit>().reset(); }),
      ])),
    ]));
  }
}

/// Строка раздела 56 внутри белой карточки: название 16, справа счётчик 14/600 и шеврон.
class _NavRow extends StatelessWidget {
  const _NavRow({required this.label, required this.onTap, this.badge, this.badgeColor});
  final String label;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Material(color: Colors.transparent, borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias, child: InkWell(
      onTap: onTap, highlightColor: c.surface2, splashColor: Colors.transparent,
      child: SizedBox(height: 56, child: Padding(padding: const EdgeInsets.only(left: 14, right: 12), child: Row(children: [
        Expanded(child: Text(label, style: _f(16, FontWeight.w400, c.ink1))),
        if (badge != null) ...[Text(badge!, style: _f(14, FontWeight.w600, badgeColor ?? c.ink2)), const SizedBox(width: 10)],
        MartChevron(color: c.ink3, size: 5),
      ]))),
    ));
  }
}

/// Отдельная белая строка 56 (радиус 20): «Выйти» серым.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.onTap, this.muted = false, this.chevron = true});
  final String label;
  final VoidCallback onTap;
  final bool muted, chevron;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return GestureDetector(onTap: onTap, child: Container(
      height: 56, padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
      child: Row(children: [
        Expanded(child: Text(label, style: _f(16, FontWeight.w400, muted ? c.ink2 : c.ink1))),
        if (chevron) MartChevron(color: c.ink3, size: 5),
      ]),
    ));
  }
}
