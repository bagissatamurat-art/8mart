import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'mart_icons.dart';

/// Чип 36 (зона касания 44). selected — тёмная заливка, removable — × справа.
class MartChip extends StatelessWidget {
  const MartChip({super.key, required this.label, this.selected = false, this.enabled = true, this.count, this.removable = false, this.onTap});
  final String label;
  final bool selected, enabled, removable;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final bg = !enabled ? c.surface2 : selected ? c.ink1 : c.surface;
    final fg = !enabled ? c.ink3 : selected ? c.surface : c.ink1;
    final bc = !enabled ? c.divider : selected ? c.ink1 : c.border;
    return Semantics(
      button: true, selected: selected, enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: (MartHeight.hit - MartHeight.chip) / 2),
          child: AnimatedContainer(
            duration: MartMotion.press,
            height: MartHeight.chip,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(MartRadius.pill), border: Border.all(color: bc, width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: MartText.small.copyWith(fontWeight: FontWeight.w500, color: fg)),
              if (count != null) ...[const SizedBox(width: 6), Text('$count', style: MartText.caption.copyWith(color: fg.withValues(alpha: .7)))],
              if (removable) ...[const SizedBox(width: 8), MartCross(size: 10, color: fg)],
            ]),
          ),
        ),
      ),
    );
  }
}
