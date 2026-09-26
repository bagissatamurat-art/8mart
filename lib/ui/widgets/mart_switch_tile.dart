import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';

/// Плитка-переключатель (подъём на этаж, списание бонусов): 56+, рамка 1.5, радиус 16, свич 40×24 справа.
/// green — зелёная тема (бонусы), иначе розовая.
class MartSwitchTile extends StatelessWidget {
  const MartSwitchTile({super.key, required this.value, required this.onTap, required this.title, required this.sub, this.leading, this.green = false});
  final bool value, green;
  final VoidCallback onTap;
  final String title, sub;
  final Widget? leading;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final on = green ? c.success : c.primary;
    final onBg = green ? const Color(0xFFF2FBF6) : c.primary50;
    return Semantics(toggled: value, button: true, label: title, child: GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: onTap,
      child: AnimatedContainer(
        duration: MartMotion.press,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
        decoration: BoxDecoration(color: value ? onBg : c.surface, borderRadius: BorderRadius.circular(MartRadius.field), border: Border.all(color: value ? on : c.border, width: 1.5)),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: TextStyle(fontFamily: 'Onest', fontSize: 15, fontWeight: FontWeight.w600, color: c.ink1)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontFamily: 'Onest', fontSize: 12, height: 1.35, color: c.ink2)),
          ])),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: MartMotion.press, width: 40, height: 24, padding: const EdgeInsets.all(2),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(color: value ? on : c.border, borderRadius: BorderRadius.circular(999)),
            child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x3317151A), blurRadius: 2, offset: Offset(0, 1))])),
          ),
        ]),
      ),
    ));
  }
}
