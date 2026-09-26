import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'package:flutter/services.dart';

import '../../core/phone_mask.dart';
import 'mart_icons.dart';

enum MartInputType { text, phone, multiline, number }

/// Поле с плавающим лейблом. Высота 56 (textarea 84). × очистки — только в фокусе и с текстом (у телефона — нет).
class MartInput extends StatefulWidget {
  const MartInput({
    super.key, required this.label, this.controller, this.initialValue, this.onChanged, this.required = false,
    this.error, this.enabled = true, this.type = MartInputType.text, this.textInputAction, this.autofillHints, this.focusNode, this.onSubmitted,
  });
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool required, enabled;
  final String? error;
  final MartInputType type;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;

  @override
  State<MartInput> createState() => _MartInputState();
}

class _MartInputState extends State<MartInput> {
  late final TextEditingController _ctl = widget.controller ?? TextEditingController(text: widget.initialValue);
  late final FocusNode _focus = widget.focusNode ?? FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
    _ctl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctl.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final w = widget;
    final focused = _focus.hasFocus;
    final hasText = _ctl.text.isNotEmpty;
    final floating = focused || hasText;
    final hasError = w.error != null && w.error!.isNotEmpty;
    final multiline = w.type == MartInputType.multiline;
    final h = multiline ? MartHeight.textarea : MartHeight.field;
    final bg = !w.enabled ? c.surface2 : hasError ? c.errorBg : focused ? c.surface : c.surface2;
    final bc = hasError ? c.error : focused ? c.primary : Colors.transparent;
    final labelColor = hasError ? c.error : focused ? c.primary : c.ink2;
    final showClear = focused && hasText && w.enabled && w.type != MartInputType.phone;

    final field = TextField(
      controller: _ctl, focusNode: _focus, enabled: w.enabled,
      maxLines: multiline ? 3 : 1, minLines: 1,
      style: MartText.body.copyWith(color: w.enabled ? c.ink1 : c.ink3, height: 1.25),
      cursorColor: c.primary,
      keyboardType: switch (w.type) { MartInputType.phone => TextInputType.phone, MartInputType.number => TextInputType.number, MartInputType.multiline => TextInputType.multiline, _ => TextInputType.text },
      textInputAction: w.textInputAction ?? (multiline ? TextInputAction.newline : TextInputAction.next),
      autofillHints: w.autofillHints ?? (w.type == MartInputType.phone ? const [AutofillHints.telephoneNumber] : null),
      inputFormatters: w.type == MartInputType.phone ? [PhoneMaskFormatter()] : w.type == MartInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: const InputDecoration.collapsed(hintText: null),
      onChanged: w.onChanged,
      onSubmitted: w.onSubmitted,
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: w.enabled ? _focus.requestFocus : null,
        child: AnimatedContainer(
          duration: MartMotion.press,
          height: h,
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(MartRadius.field),
            border: Border.all(color: bc, width: 1.5),
            boxShadow: focused && !hasError ? [BoxShadow(color: c.focusRing, spreadRadius: 3)] : null,
          ),
          child: Stack(children: [
            AnimatedPositioned(
              duration: MartMotion.press, curve: Curves.easeOut,
              left: 16, right: showClear ? 48 : 16, top: floating ? 8 : (multiline ? 16 : 17),
              child: IgnorePointer(
                child: AnimatedDefaultTextStyle(
                  duration: MartMotion.press,
                  style: MartText.body.copyWith(fontSize: floating ? 12 : 16, color: labelColor, height: 1.2),
                  child: Text.rich(TextSpan(text: w.label, children: [if (w.required) TextSpan(text: ' *', style: TextStyle(color: c.error))])),
                ),
              ),
            ),
            Positioned(left: 16, right: showClear ? 48 : 16, top: multiline ? 28 : 24, bottom: multiline ? 8 : 6, child: Opacity(opacity: floating ? 1 : 0, child: field)),
            if (showClear)
              Positioned(
                right: 4, top: 0, bottom: multiline ? null : 0,
                child: Semantics(
                  button: true, label: 'Очистить',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () { _ctl.clear(); w.onChanged?.call(''); },
                    child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: Container(
                      width: 24, height: 24, decoration: BoxDecoration(color: c.surface3, shape: BoxShape.circle),
                      child: Center(child: MartCross(size: 10, color: c.ink2)),
                    ))),
                  ),
                ),
              ),
          ]),
        ),
      ),
      if (hasError) Padding(padding: const EdgeInsets.fromLTRB(4, 6, 4, 0), child: Text(w.error!, style: MartText.small.copyWith(fontSize: 13, color: c.error))),
    ]);
  }
}
