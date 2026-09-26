import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock_data.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/account_cubit.dart';
import '../../state/auth_cubit.dart';
import '../../state/favorites_cubit.dart';
import '../../state/settings_cubit.dart';
import '../../ui/ui.dart';
import '../auth/auth_view.dart';
import 'account_sections.dart';

/// Вкладка «Профиль»: гость — вход; пользователь — активный заказ, разделы со счётчиками, настройки, поддержка.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final auth = context.watch<AuthCubit>().state;
    final acc = context.watch<AccountCubit>().state;
    final favs = context.watch<FavoritesCubit>().state.length;
    final st = context.watch<SettingsCubit>();
    if (auth.authed) context.read<AccountCubit>().load(); // один раз, повторные вызовы игнорируются
    Widget card(List<Widget> ch, {EdgeInsets padding = const EdgeInsets.all(16)}) => Container(padding: padding,
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: ch));
    String? badge(AccountSection s) => switch (s) {
          AccountSection.favorites => favs > 0 ? '$favs' : null,
          AccountSection.promos => acc.promos.isEmpty ? null : '${acc.promos.where((p) => p.status.name == 'active').length}',
          AccountSection.bonus => acc.loading ? null : '${acc.bonusBalance}',
          _ => null,
        };
    final active = acc.active;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(t.tabProfile)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        if (!auth.authed) card([const AuthView()])
        else ...[
          card([
            Row(children: [
              Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: c.primary100, shape: BoxShape.circle),
                child: Text(auth.name.isEmpty ? '?' : auth.name[0], style: MartText.h3.copyWith(color: c.primary))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.name, style: MartText.h3.copyWith(color: c.ink1)), Text(auth.phone, style: MartText.small.copyWith(color: c.ink2)),
              ])),
            ]),
            if (active != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/order/${active.id}'),
                child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(MartRadius.field)),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.orderNo(active.id), style: MartText.caption.copyWith(color: c.ink2)), Text(t.stCourier, style: MartText.bodyStrong.copyWith(color: c.ink1)),
                    ])),
                    if (active.eta != null) Text(active.eta!, style: MartText.small.copyWith(fontWeight: FontWeight.w600, color: c.primary)),
                  ])),
              ),
            ],
          ]),
          const SizedBox(height: 12),
          card([
            for (final s in AccountSection.values) MartListRow(title: sectionTitle(t, s), value: badge(s), valueColor: s == AccountSection.bonus ? c.successText : null, onTap: () => context.go('/profile/${s.name}')),
          ], padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
        ],
        const SizedBox(height: 12),
        card([
          MartListRow(title: t.settings, value: '${st.state.lang == 'kk' ? t.langKk : t.langRu} · ${switch (st.state.themeMode) { ThemeMode.light => t.themeLight, ThemeMode.dark => t.themeDark, _ => t.themeSystem }}', onTap: () => context.go('/profile/settings')),
          MartListRow(title: t.documents, onTap: () => context.go('/profile/settings/documents')),
        ], padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
        const SizedBox(height: 12),
        card([
          MartListRow(title: t.support, sub: 'WhatsApp', onTap: () => launchUrl(Uri.parse('https://wa.me/${MockData.supportWa}'), mode: LaunchMode.externalApplication)),
          MartListRow(title: MockData.supportPhone, sub: t.supportPhone, onTap: () => launchUrl(Uri.parse('tel:${MockData.supportPhone.replaceAll(' ', '')}'))),
        ], padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
        if (auth.authed) ...[
          const SizedBox(height: 12),
          Center(child: TextButton(onPressed: () { context.read<AuthCubit>().logout(); context.read<AccountCubit>().reset(); }, child: Text(t.logout, style: MartText.small.copyWith(color: c.ink3)))),
        ],
      ]),
    );
  }
}
