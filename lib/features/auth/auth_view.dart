import 'dart:async';

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

TextStyle _f(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

/// Вход (MartAuth.dc.html, mobile): телефон → код из WhatsApp (4 ячейки, таймер 45 с) → «Как вас зовут?»; альтернатива — Telegram-бот.
/// changePhone — смена номера в кабинете (другой заголовок, без Telegram и условий).
class AuthView extends StatefulWidget {
  const AuthView({super.key, this.changePhone = false});
  final bool changePhone;
  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _code = TextEditingController();
  Timer? _tick;
  int _left = 45;
  bool _tgOpened = false;

  @override
  void dispose() { _tick?.cancel(); _phone.dispose(); _name.dispose(); _code.dispose(); super.dispose(); }

  void _startTimer() {
    _tick?.cancel();
    setState(() => _left = 45);
    _tick = Timer.periodic(const Duration(seconds: 1), (t) { if (!mounted) return; setState(() => _left = (_left - 1).clamp(0, 45)); if (_left == 0) t.cancel(); });
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (a, b) => a.step != b.step,
      listener: (context, s) {
        if (s.step == AuthStep.code) { _code.clear(); _startTimer(); }
        if (s.step == AuthStep.telegram) setState(() => _tgOpened = false);
        if (s.step == AuthStep.done && !widget.changePhone) offerBiometrics(context);
      },
      builder: (context, s) {
        final cubit = context.read<AuthCubit>();
        Widget head(String title, Widget sub) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(title, style: _f(24, FontWeight.w800, c.ink1, ls: -0.48)),
              const SizedBox(height: 6),
              sub,
            ]);
        Widget subText(String v) => Text(v, style: _f(14, FontWeight.w400, c.ink2, h: 1.4));
        Widget link(String label, VoidCallback onTap, {Color? color}) => GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onTap,
              child: SizedBox(height: 44, child: Center(child: Text(label, style: _f(14, FontWeight.w600, color ?? c.ink2)))));
        const gap = SizedBox(height: 20);

        switch (s.step) {
          case AuthStep.phone:
            final ok = PhoneMaskFormatter.isComplete(_phone.text);
            return AutofillGroup(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              head(widget.changePhone ? t.newPhoneTitle : t.authTitle, subText(widget.changePhone ? t.newPhoneSub : t.authSub)),
              gap,
              MartInput(label: t.phone, type: MartInputType.phone, required: true, controller: _phone, textInputAction: TextInputAction.done, onChanged: (_) => setState(() {})),
              gap,
              MartButton(label: t.getCodeWa, expanded: true, loading: s.loading, disabledReason: ok ? null : t.enterFullPhone, onPressed: () => cubit.sendCode(_phone.text)),
              if (!widget.changePhone) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: Container(height: 1, color: c.divider)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(t.or, style: _f(13, FontWeight.w400, c.ink3))),
                  Expanded(child: Container(height: 1, color: c.divider)),
                ]),
                const SizedBox(height: 12),
                MartButton(label: t.loginTelegram, variant: MartButtonVariant.ghost, expanded: true, onPressed: cubit.startTelegram),
                gap,
                Text.rich(TextSpan(text: t.termsPrefix, children: [
                  TextSpan(text: t.termsLink, style: TextStyle(color: c.ink2, decoration: TextDecoration.underline)),
                  TextSpan(text: t.termsAnd),
                  TextSpan(text: t.privacyLink, style: TextStyle(color: c.ink2, decoration: TextDecoration.underline)),
                ]), textAlign: TextAlign.center, style: _f(12, FontWeight.w400, c.ink3, h: 1.4)),
              ],
            ]));

          case AuthStep.code:
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              head(t.codeWaTitle, Text.rich(TextSpan(text: t.codeSentTo(s.phone), children: [
                WidgetSpan(alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic,
                    child: GestureDetector(onTap: cubit.back, child: Text(t.changeLink, style: _f(14, FontWeight.w600, c.primary, h: 1.4)))),
              ]), style: _f(14, FontWeight.w400, c.ink2, h: 1.4))),
              gap,
              MartCodeInput(controller: _code, state: s.code, onCompleted: cubit.verify, onEdit: cubit.resetCodeError),
              const SizedBox(height: 8),
              if (s.code == CodeState.error) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(t.codeWrongMsg, style: _f(13, FontWeight.w400, c.error))),
              if (s.code == CodeState.success) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(t.codeOk, style: _f(13, FontWeight.w600, c.success))),
              if (s.code == CodeState.checking) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Row(children: [
                SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary, backgroundColor: c.border)),
                const SizedBox(width: 8),
                Text(t.codeChecking, style: _f(13, FontWeight.w400, c.ink2)),
              ])),
              const SizedBox(height: 12),
              PasteCodeHint(label: t.pasteCode, action: t.paste, onCode: (v) { _code.text = v; cubit.verify(v); }),
              if (_left == 0) link(t.resendCode, () { cubit.sendCode(s.phone); _startTimer(); }, color: c.primary)
              else SizedBox(height: 44, child: Center(child: Text(t.resendIn('0:${_left.toString().padLeft(2, '0')}'), style: _f(14, FontWeight.w400, c.ink3)))),
              if (!widget.changePhone) link(t.noWaTelegram, cubit.startTelegram),
              Text(t.codeProtoHint, textAlign: TextAlign.center, style: _f(12, FontWeight.w400, c.ink3)),
            ]);

          case AuthStep.telegram:
            final stepBg = s.tgOk ? c.successBg : c.primary50, stepFg = s.tgOk ? c.success : c.primary;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              head(t.tgLoginTitle, subText(t.tgLoginSub)),
              gap,
              for (final (i, text) in [t.tgStep1, t.tgStep2, t.tgStep3].indexed) Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: stepBg, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: _f(13, FontWeight.w700, stepFg))),
                  const SizedBox(width: 12),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(text, style: _f(15, FontWeight.w400, c.ink1, h: 1.4)))),
                ]),
              ),
              gap,
              MartButton(label: t.openTg, expanded: true, onPressed: () {
                setState(() => _tgOpened = true);
                cubit.waitTelegram();
                launchUrl(Uri.parse(MockData.tgLink(s.tgToken)), mode: LaunchMode.externalApplication);
              }),
              if (_tgOpened || s.tgOk) ...[
                const SizedBox(height: 12),
                Container(
                  height: 44, alignment: Alignment.center,
                  decoration: BoxDecoration(color: s.tgOk ? c.successBg : c.surface2, borderRadius: BorderRadius.circular(14)),
                  child: s.tgOk
                      ? Text(t.tgConfirmed(s.phone), style: _f(14, FontWeight.w600, c.success))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary, backgroundColor: c.border)),
                          const SizedBox(width: 10),
                          Text(t.tgWaitingMsg, style: _f(14, FontWeight.w400, c.ink2)),
                        ]),
                ),
              ],
              const SizedBox(height: 8),
              link(t.loginByWa, cubit.back),
            ]);

          case AuthStep.name:
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              head(t.nameTitle, subText(t.nameSub)),
              gap,
              MartInput(label: t.name, required: true, controller: _name, autofillHints: const [AutofillHints.givenName], textInputAction: TextInputAction.done, onChanged: (_) => setState(() {})),
              gap,
              MartButton(label: t.continueBtn, expanded: true, disabledReason: _name.text.trim().isEmpty ? t.enterName : null, onPressed: () => cubit.setName(_name.text)),
            ]);

          case AuthStep.done:
            return const SizedBox.shrink();
        }
      },
    );
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
