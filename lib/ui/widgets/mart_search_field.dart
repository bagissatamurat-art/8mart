import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'mart_icons.dart';

/// Поле поиска 48, pill. readOnly + onTap — для шапки главной (открывает экран поиска).
class MartSearchField extends StatefulWidget {
  const MartSearchField({super.key, required this.hint, this.controller, this.onChanged, this.onSubmitted, this.onTap, this.readOnly = false, this.autofocus = false});
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onTap;
  final bool readOnly, autofocus;
  @override
  State<MartSearchField> createState() => _MartSearchFieldState();
}

class _MartSearchFieldState extends State<MartSearchField> {
  late final TextEditingController _ctl = widget.controller ?? TextEditingController();
  final _focus = FocusNode();
  @override
  void initState() { super.initState(); _ctl.addListener(() => setState(() {})); _focus.addListener(() => setState(() {})); }
  @override
  void dispose() { if (widget.controller == null) _ctl.dispose(); _focus.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: MartMotion.press, height: 48, padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MartRadius.pill),
        border: Border.all(color: focused ? c.primary : Colors.transparent, width: 1.5),
        boxShadow: focused ? [BoxShadow(color: c.focusRing, spreadRadius: 3)] : null),
      child: Row(children: [
        Icon(Icons.search, size: 20, color: c.ink2),
        const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: _ctl, focusNode: _focus, readOnly: widget.readOnly, autofocus: widget.autofocus, onTap: widget.onTap,
          textInputAction: TextInputAction.search, style: MartText.body.copyWith(color: c.ink1), cursorColor: c.primary,
          decoration: InputDecoration.collapsed(hintText: widget.hint, hintStyle: MartText.body.copyWith(color: c.ink3)),
          onChanged: widget.onChanged, onSubmitted: widget.onSubmitted,
        )),
        if (_ctl.text.isNotEmpty && !widget.readOnly)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { _ctl.clear(); widget.onChanged?.call(''); },
            child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: Container(width: 24, height: 24, decoration: BoxDecoration(color: c.surface3, shape: BoxShape.circle),
              child: Center(child: MartCross(size: 10, color: c.ink2))))),
          )
        else const SizedBox(width: 12),
      ]),
    );
  }
}
