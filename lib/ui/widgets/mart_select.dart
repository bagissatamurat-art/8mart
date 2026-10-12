import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'mart_icons.dart';
import 'mart_sheet.dart';

class MartSelectOption {
  const MartSelectOption(this.id, this.label, [this.sub]);
  final String id, label;
  /// Подпись справа: «~30 мин».
  final String? sub;
}

/// Выпадающий список в виде поля (56, r16, подпись сверху — как MartInput). По нажатию — шторка со списком,
/// выбранный пункт — розовым с галочкой. Как MartSelect сайта: время доставки в оформлении.
class MartSelect extends StatelessWidget {
  const MartSelect({super.key, required this.label, required this.options, required this.value, required this.onChanged, this.sheetTitle});
  final String label;
  final List<MartSelectOption> options;
  final String value;
  final ValueChanged<String> onChanged;
  /// Заголовок шторки (по умолчанию — label).
  final String? sheetTitle;

  Future<void> _open(BuildContext context) async {
    final id = await showMartSheet<String>(context, title: sheetTitle ?? label, builder: (ctx) {
      final c = ctx.mc;
      return Column(mainAxisSize: MainAxisSize.min, children: [
        for (final o in options) Semantics(
          button: true, selected: o.id == value, label: o.sub == null ? o.label : '${o.label}, ${o.sub}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, onTap: () => Navigator.of(ctx).pop(o.id),
            child: Container(
              constraints: const BoxConstraints(minHeight: MartHeight.field), margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: o.id == value ? c.primary50 : null, borderRadius: BorderRadius.circular(12)),
              child: ExcludeSemantics(child: Row(children: [
                Expanded(child: Text(o.label, style: MartText.body.copyWith(fontWeight: o.id == value ? FontWeight.w600 : FontWeight.w400, color: c.ink1,
                    fontFeatures: const [FontFeature.tabularFigures()]))),
                if (o.sub != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(o.sub!, style: MartText.small.copyWith(color: c.ink2))),
                SizedBox(width: 28, child: o.id == value ? Align(alignment: Alignment.centerRight, child: MartCheck(color: c.primary)) : null),
              ])),
            ),
          ),
        ),
      ]);
    });
    if (id != null && id != value) onChanged(id);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final cur = options.where((o) => o.id == value).firstOrNull;
    return Semantics(
      button: true, label: '$label: ${cur == null ? '—' : cur.sub == null ? cur.label : '${cur.label}, ${cur.sub}'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: () => _open(context),
        child: Container(
          height: MartHeight.field, padding: const EdgeInsets.only(left: 16, right: 14),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MartRadius.field)),
          child: ExcludeSemantics(child: Row(children: [
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: MartText.caption.copyWith(fontWeight: FontWeight.w400, color: c.ink2)),
              const SizedBox(height: 2),
              Text.rich(TextSpan(text: cur?.label ?? '—', children: [
                if (cur?.sub != null) TextSpan(text: ' · ${cur!.sub}', style: TextStyle(color: c.ink2, fontWeight: FontWeight.w400)),
              ]), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: MartText.body.copyWith(fontWeight: FontWeight.w500, color: c.ink1, height: 1.2, fontFeatures: const [FontFeature.tabularFigures()])),
            ])),
            MartChevron(color: c.ink2, size: 7, dir: ChevronDir.down),
          ])),
        ),
      ),
    );
  }
}
