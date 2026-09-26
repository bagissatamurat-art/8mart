import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/push.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/auth_cubit.dart';
import '../../state/settings_cubit.dart';
import '../../ui/ui.dart';

Widget _card(BuildContext context, List<Widget> ch) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: context.mc.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: ch));

PreferredSizeWidget _bar(String title) => AppBar(leading: const Padding(padding: EdgeInsets.only(left: 8), child: Center(child: MartBackButton())), leadingWidth: 60, title: Text(title));

/// Профиль → Настройки: язык, тема, уведомления, Face ID, документы, о приложении. Доступно и гостю (кроме Face ID).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final st = context.watch<SettingsCubit>();
    final authed = context.watch<AuthCubit>().state.authed;
    final themeLabel = switch (st.state.themeMode) { ThemeMode.light => t.themeLight, ThemeMode.dark => t.themeDark, _ => t.themeSystem };
    return Scaffold(
      appBar: _bar(t.settings),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        _card(context, [
          MartListRow(title: t.language, value: st.state.lang == 'kk' ? t.langKk : t.langRu, onTap: () => _pick(context, t.language, [('ru', t.langRu), ('kk', t.langKk)], st.state.lang, st.setLang)),
          MartListRow(title: t.theme, value: themeLabel, onTap: () => _pick(context, t.theme,
              [(ThemeMode.system, t.themeSystem), (ThemeMode.light, t.themeLight), (ThemeMode.dark, t.themeDark)], st.state.themeMode, st.setTheme)),
          MartListRow(title: t.notifications, onTap: () => context.go('/profile/settings/notifications')),
          if (authed) SwitchListTile.adaptive(contentPadding: const EdgeInsets.symmetric(horizontal: 4), activeColor: c.primary, value: st.state.biometrics, onChanged: st.setBiometrics,
              title: Text(t.biometrics, style: MartText.bodyStrong.copyWith(fontWeight: FontWeight.w500, color: c.ink1))),
        ]),
        const SizedBox(height: 12),
        _card(context, [
          MartListRow(title: t.documents, onTap: () => context.go('/profile/settings/documents')),
          MartListRow(title: t.rateApp, onTap: () {}), // in_app_review
          MartListRow(title: t.aboutApp, value: t.version('0.1.0 (1)'), chevron: false),
        ]),
      ]),
    );
  }

  void _pick<T>(BuildContext context, String title, List<(T, String)> items, T value, ValueChanged<T> onPick) {
    showMartSheet(context, title: title, builder: (ctx) => Column(children: [
      for (final (v, l) in items) Padding(padding: const EdgeInsets.only(bottom: 8), child: MartRadioTile(selected: v == value, title: l, onTap: () { onPick(v); Navigator.of(ctx).pop(); })),
    ]));
  }
}

/// Уведомления: переключатель на каждый канал. Статус заказа — транзакционный, включён по умолчанию.
/// Если системное разрешение не дано — плашка «Открыть настройки».
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final st = context.watch<SettingsCubit>();
    final rows = [
      (PushChannel.orders, t.pushOrders, t.pushOrdersSub), (PushChannel.bonus, t.pushBonus, t.pushBonusSub),
      (PushChannel.promo, t.pushPromo, t.pushPromoSub), (PushChannel.cart, t.pushCart, t.pushCartSub),
    ];
    return Scaffold(
      appBar: _bar(t.notifications),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        if (!st.state.pushAllowed) ...[
          Container(padding: const EdgeInsets.fromLTRB(14, 10, 6, 10), decoration: BoxDecoration(color: c.warningBg, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: Text(t.pushSystemOff, style: MartText.small.copyWith(color: c.ink1))),
              TextButton(onPressed: () => launchUrl(Uri.parse('app-settings:')), child: Text(t.openSettings, style: MartText.small.copyWith(fontWeight: FontWeight.w600, color: c.primary))),
            ])),
          const SizedBox(height: 12),
        ],
        _card(context, [
          for (final (ch, title, sub) in rows) SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4), activeColor: c.primary,
            value: st.state.channels.contains(ch.name), onChanged: (v) => st.setChannel(ch.name, v),
            title: Text(title, style: MartText.bodyStrong.copyWith(fontWeight: FontWeight.w500, color: c.ink1)),
            subtitle: Text(sub, style: MartText.caption.copyWith(fontSize: 13, color: c.ink2)),
          ),
        ]),
      ]),
    );
  }
}

/// Документы: открываются в браузере приложения (SFSafariViewController / Custom Tabs). URL — из GET /app/config.
/// Тексты ещё не написаны — сейчас ссылки-заглушки, страницы подготовит бизнес.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});
  static const base = 'https://8mart.kz/legal';
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final docs = [(t.docOffer, 'offer'), (t.docPrivacy, 'privacy'), (t.docPd, 'personal-data'), (t.docDelivery, 'delivery-returns'), (t.docBonus, 'bonus-rules')];
    return Scaffold(
      appBar: _bar(t.documents),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        _card(context, [
          for (final (title, slug) in docs) MartListRow(title: title, onTap: () => launchUrl(Uri.parse('$base/$slug'), mode: LaunchMode.inAppBrowserView)),
          MartListRow(title: t.docLicenses, onTap: () => showLicensePage(context: context, applicationName: '8mart')),
        ]),
      ]),
    );
  }
}
