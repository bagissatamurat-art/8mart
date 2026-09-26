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
  const MartCodeInput({super.key, this.length = 4, required this.onCompleted, this.state = CodeState.idle, this.controller, this.autofocus = true});
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
      _ctl.clear();
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
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < widget.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            AnimatedContainer(
              duration: MartMotion.press,
              width: 56, height: MartHeight.codeCell,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: st == CodeState.success ? c.successBg : st == CodeState.error ? c.errorBg : i < v.length ? c.surface : c.surface2,
                borderRadius: BorderRadius.circular(MartRadius.field),
                border: Border.all(width: 1.5, color: st == CodeState.success ? c.success : st == CodeState.error ? c.error
                    : (_focus.hasFocus && i == v.length.clamp(0, widget.length - 1)) ? c.primary : i < v.length ? c.border : Colors.transparent),
              ),
              child: Text(i < v.length ? v[i] : '', style: MartText.h2.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: c.ink1)),
            ),
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
