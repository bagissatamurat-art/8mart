import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/mock_data.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/phone_mask.dart';
import '../../state/auth_cubit.dart';
import '../../state/settings_cubit.dart';

/// Вход: WhatsApp-код (основной) или Telegram-бот. Используется в оформлении и в профиле.
class AuthView extends StatefulWidget {
  const AuthView({super.key});
  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (a, b) => a.step != b.step && b.step == AuthStep.done,
      listener: (context, s) => offerBiometrics(context),
      builder: (context, s) {
        final cubit = context.read<AuthCubit>();
        Widget title(String a, String? b) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a, style: MartText.h2.copyWith(color: c.ink1)),
              if (b != null) ...[const SizedBox(height: 6), Text(b, style: MartText.small.copyWith(color: c.ink2))],
              const SizedBox(height: 20),
            ]);
        switch (s.step) {
          case AuthStep.phone:
            return AutofillGroup(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              title(t.loginTitle, t.loginSub),
              MartInput(label: t.phone, type: MartInputType.phone, required: true, controller: _phone, textInputAction: TextInputAction.done, onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              MartButton(label: t.getCode, expanded: true, loading: s.loading, disabledReason: PhoneMaskFormatter.isComplete(_phone.text) ? null : t.errPhone, onPressed: () => cubit.sendCode(_phone.text)),
              const SizedBox(height: 8),
              TextButton(onPressed: () => _openTg(cubit), child: Text(t.noWhatsapp, style: MartText.small.copyWith(fontWeight: FontWeight.w600, color: c.primary))),
            ]));
          case AuthStep.code:
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [MartBackButton(onTap: cubit.back)]),
              const SizedBox(height: 12),
              title(t.codeTitle, t.codeSent(s.phone)),
              MartCodeInput(controller: _code, state: s.code, onCompleted: cubit.verify),
              if (s.code == CodeState.error) Padding(padding: const EdgeInsets.only(top: 10), child: Text(t.codeWrong, textAlign: TextAlign.center, style: MartText.small.copyWith(color: c.error))),
              const SizedBox(height: 16),
              PasteCodeHint(label: t.pasteCode, action: t.paste, onCode: (v) { _code.text = v; cubit.verify(v); }),
              const SizedBox(height: 8),
              TextButton(onPressed: () => _openTg(cubit), child: Text(t.noWhatsapp, style: MartText.small.copyWith(fontWeight: FontWeight.w600, color: c.primary))),
            ]);
          case AuthStep.telegram:
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [MartBackButton(onTap: cubit.back)]),
              const SizedBox(height: 12),
              title(t.tgTitle, t.tgSteps),
              MartButton(label: t.openTelegram, expanded: true, onPressed: () => launchUrl(Uri.parse(MockData.tgLink(s.tgToken)), mode: LaunchMode.externalApplication)),
              const SizedBox(height: 20),
              Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.primary))),
            ]);
          case AuthStep.name:
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              title(t.whatsYourName, null),
              MartInput(label: t.name, required: true, controller: _name, autofillHints: const [AutofillHints.givenName], textInputAction: TextInputAction.done, onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              MartButton(label: t.checkout == 'Оформить' ? 'Продолжить' : 'Жалғастыру', expanded: true, disabledReason: _name.text.trim().isEmpty ? t.errRequired : null, onPressed: () => cubit.setName(_name.text)),
            ]);
          case AuthStep.done:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _openTg(AuthCubit cubit) async {
    final token = cubit.startTelegram();
    await launchUrl(Uri.parse(MockData.tgLink(token)), mode: LaunchMode.externalApplication);
  }
}

/// После первого входа — предложить Face ID / отпечаток (один раз).
Future<void> offerBiometrics(BuildContext context) async {
  final settings = context.read<SettingsCubit>();
  if (settings.state.biometricsAsked) return;
  final auth = LocalAuthentication();
  final can = await auth.canCheckBiometrics && await auth.isDeviceSupported();
  if (!can || !context.mounted) return;
  final t = L10n.of(context);
  final c = context.mc;
  await showMartSheet(context, builder: (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Icon(Icons.fingerprint, size: 48, color: c.primary),
    const SizedBox(height: 12),
    Text(t.faceIdOffer, textAlign: TextAlign.center, style: MartText.h3.copyWith(color: c.ink1)),
    const SizedBox(height: 6),
    Text(t.faceIdSub, textAlign: TextAlign.center, style: MartText.small.copyWith(color: c.ink2)),
    const SizedBox(height: 20),
    MartButton(label: t.enable, expanded: true, onPressed: () async {
      final ok = await auth.authenticate(localizedReason: t.faceIdOffer, options: const AuthenticationOptions(biometricOnly: true));
      settings.setBiometrics(ok);
      if (ctx.mounted) Navigator.of(ctx).pop();
    }),
    const SizedBox(height: 8),
    MartButton(label: t.notNow, variant: MartButtonVariant.ghost, expanded: true, onPressed: () { settings.setBiometrics(false); Navigator.of(ctx).pop(); }),
  ]));
}
