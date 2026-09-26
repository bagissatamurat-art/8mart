import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';
import '../widgets/mart_button.dart';
import '../widgets/mart_icons.dart';
import '../widgets/mart_input.dart';

/// Промокод (MartPromo.dc.html): поле 56 + «Применить» (secondary 56) → после применения зелёная плашка с кодом, скидкой и ×.
/// Ошибки — под полем: не найден / истёк / не достигнута сумма.
class MartPromo extends StatefulWidget {
  const MartPromo({super.key, required this.label, required this.applyLabel, required this.appliedLabel, this.appliedCode, this.discountText = '', required this.onApply, required this.onRemove});
  final String label, applyLabel, appliedLabel, discountText;
  final String? appliedCode;
  /// Возвращает текст ошибки или null при успехе.
  final String? Function(String code) onApply;
  final VoidCallback onRemove;
  @override
  State<MartPromo> createState() => _MartPromoState();
}

class _MartPromoState extends State<MartPromo> {
  final _ctl = TextEditingController();
  String? _error;
  @override
  void dispose() { _ctl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    if (widget.appliedCode != null) {
      return Container(
        height: 56, padding: const EdgeInsets.only(left: 16, right: 8),
        decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(MartRadius.field), border: Border.all(color: const Color(0xFFB7E4CC), width: 1.5)),
        child: Row(children: [
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.appliedLabel, style: TextStyle(fontFamily: 'Onest', fontSize: 12, fontWeight: FontWeight.w600, color: c.success)),
            const SizedBox(height: 2),
            Text(widget.appliedCode!, style: TextStyle(fontFamily: 'Onest', fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: .6, color: c.ink1)),
          ])),
          Text(widget.discountText, style: TextStyle(fontFamily: 'Onest', fontSize: 14, fontWeight: FontWeight.w600, color: c.success)),
          const SizedBox(width: 8),
          Semantics(button: true, label: 'Убрать промокод', child: GestureDetector(
            behavior: HitTestBehavior.opaque, onTap: () { _ctl.clear(); widget.onRemove(); },
            child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: Container(width: 36, height: 36,
              decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle), child: Center(child: MartCross(size: 11, color: c.ink2))))),
          )),
        ]),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: MartInput(label: widget.label, controller: _ctl, error: _error, onChanged: (_) => setState(() => _error = null))),
      const SizedBox(width: 8),
      MartButton(label: widget.applyLabel, variant: MartButtonVariant.secondary, size: MartButtonSize.l56,
          onPressed: _ctl.text.trim().isEmpty ? null : () => setState(() => _error = widget.onApply(_ctl.text))),
    ]);
  }
}
