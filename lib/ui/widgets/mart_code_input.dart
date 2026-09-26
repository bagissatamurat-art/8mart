import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'package:flutter/services.dart';

enum CodeState { idle, checking, error, success }

/// 4 ячейки поверх одного скрытого TextField: тап по ячейкам фокусирует, Backspace стирает,
/// вставка и автозаполнение (AutofillHints.oneTimeCode / Android SMS Retriever) работают из коробки.
/// Проверка — автоматически на последней цифре через [onCompleted].
class MartCodeInput extends StatefulWidget {
  const MartCodeInput({super.key, this.length = 4, required this.onCompleted, this.state = CodeState.idle, this.controller, this.autofocus = true, this.onEdit});
  /// Пользователь начал править код после ошибки — сбросить ошибку.
  final VoidCallback? onEdit;
  final int length;
  final ValueChanged<String> onCompleted;
  final CodeState state;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  State<MartCodeInput> createState() => _MartCodeInputState();
}

class _MartCodeInputState extends State<MartCodeInput> {
  late final TextEditingController _ctl = widget.controller ?? TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(MartCodeInput old) {
    super.didUpdateWidget(old);
    if (old.state != CodeState.error && widget.state == CodeState.error) {
      HapticFeedback.mediumImpact();
      // Не стираем: пользователь видит, что ввёл; следующая цифра заменит код.
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() {});
    if (widget.state == CodeState.error) widget.onEdit?.call();
    if (v.length == widget.length) widget.onCompleted(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final v = _ctl.text;
    final st = widget.state;
    return GestureDetector(
      onTap: _focus.requestFocus,
      child: Stack(alignment: Alignment.center, children: [
        // Как в MartAuth.dc.html: 4 ячейки на всю ширину (зазор 10), 64, радиус 16, белые, рамка 1.5 border;
        // активная — primary + кольцо 3; ошибка — рамка error; успех — зелёные фон, рамка и цифры. Пустая активная — розовая каретка.
        Row(children: [
          for (var i = 0; i < widget.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: () {
              final busy = st == CodeState.checking || st == CodeState.success;
              final active = _focus.hasFocus && !busy && i == v.length.clamp(0, widget.length - 1);
              final ok = st == CodeState.success, err = st == CodeState.error;
              return AnimatedContainer(
                duration: MartMotion.press, height: MartHeight.codeCell, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ok ? c.successBg : c.surface,
                  borderRadius: BorderRadius.circular(MartRadius.field),
                  border: Border.all(width: 1.5, color: ok ? c.success : err ? c.error : active ? c.primary : c.border),
                  boxShadow: active && !err ? [BoxShadow(color: c.focusRing, spreadRadius: 3)] : null,
                ),
                child: i < v.length
                    ? Text(v[i], style: TextStyle(fontFamily: 'Onest', fontSize: 28, fontWeight: FontWeight.w700, color: ok ? c.success : c.ink1))
                    : active && !err ? Container(width: 2, height: 28, decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(1))) : null,
              );
            }()),
          ],
        ]),
        Positioned.fill(
          child: Opacity(
            opacity: 0.01,
            child: TextField(
              controller: _ctl, focusNode: _focus, autofocus: widget.autofocus,
              enabled: st != CodeState.checking && st != CodeState.success,
              keyboardType: TextInputType.number, textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
              showCursor: false, enableSuggestions: false, autocorrect: false,
              decoration: const InputDecoration.collapsed(hintText: null),
              onChanged: _onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}

/// «Скопировали код? · Вставить». На iOS чтение буфера показывает системный запрос —
/// поэтому проверяем только hasStrings(), а читаем по нажатию.
class PasteCodeHint extends StatefulWidget {
  const PasteCodeHint({super.key, required this.label, required this.action, required this.onCode, this.length = 4});
  final String label, action;
  final ValueChanged<String> onCode;
  final int length;
  @override
  State<PasteCodeHint> createState() => _PasteCodeHintState();
}

class _PasteCodeHintState extends State<PasteCodeHint> with WidgetsBindingObserver {
  bool _has = false;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _check(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.resumed) _check(); }
  Future<void> _check() async { final has = await Clipboard.hasStrings(); if (mounted) setState(() => _has = has); }
  Future<void> _paste() async {
    final d = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (d.length >= widget.length) widget.onCode(d.substring(0, widget.length));
  }
  @override
  Widget build(BuildContext context) {
    if (!_has) return const SizedBox.shrink();
    final c = context.mc;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(child: Text(widget.label, style: MartText.small.copyWith(color: c.ink1))),
        GestureDetector(
          onTap: _paste,
          child: Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center,
            decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(MartRadius.pill)),
            child: Text(widget.action, style: MartText.small.copyWith(color: MartColors.onPrimary, fontWeight: FontWeight.w600))),
        ),
      ]),
    );
  }
}
