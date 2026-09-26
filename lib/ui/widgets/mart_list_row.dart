import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'mart_icons.dart';

/// Строка списка (кабинет, настройки): 56, заголовок, подпись, значение справа, шеврон.
class MartListRow extends StatelessWidget {
  const MartListRow({super.key, required this.title, this.sub, this.value, this.valueColor, this.leading, this.onTap, this.chevron = true});
  final String title;
  final String? sub, value;
  final Color? valueColor;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool chevron;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Semantics(button: onTap != null, label: title, child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(MartRadius.field),
      child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 56), child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: MartText.bodyStrong.copyWith(fontWeight: FontWeight.w500, color: c.ink1)),
            if (sub != null) Text(sub!, style: MartText.caption.copyWith(fontSize: 13, color: c.ink2)),
          ])),
          if (value != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(value!, style: MartText.small.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? c.ink2))),
          if (chevron && onTap != null) ...[const SizedBox(width: 8), MartChevron(color: c.ink3, size: 6)],
        ]),
      )),
    ));
  }
}
