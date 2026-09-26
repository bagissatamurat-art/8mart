import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';
import 'mart_icons.dart';

enum MartStepperTone { primary, neutral }

/// Степпер как в MartStepper.dc.html: пилюля 36 или 44, ± без подложек.
/// primary — розовый с белым (карточка товара), neutral — серый (строка корзины). Зона касания ± — 44.
class MartStepper extends StatelessWidget {
  const MartStepper({super.key, required this.qty, required this.onChanged, this.min = 0, this.max = 99, this.width = 120, this.size = 36, this.tone = MartStepperTone.neutral, this.disabled = false});
  final int qty, min, max;
  final ValueChanged<int> onChanged;
  final double width, size;
  final MartStepperTone tone;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final bg = disabled ? c.surface3 : tone == MartStepperTone.primary ? c.primary : c.surface2;
    final fg = disabled ? c.ink3 : tone == MartStepperTone.primary ? MartColors.onPrimary : c.ink1;
    Widget btn(bool plus) {
      final can = !disabled && (plus ? qty < max : qty > min);
      return Semantics(
        button: true, enabled: can, label: plus ? 'Больше' : 'Меньше',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: can ? () { HapticFeedback.selectionClick(); onChanged(qty + (plus ? 1 : -1)); } : null,
          child: SizedBox(width: size, height: MartHeight.hit, child: Center(child: Opacity(opacity: plus && qty >= max ? .4 : 1, child: MartPlusMinus(plus: plus, color: fg)))),
        ),
      );
    }
    return SizedBox(
      width: width, height: MartHeight.hit,
      child: Stack(alignment: Alignment.center, children: [
        Container(height: size, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(MartRadius.pill))),
        Row(children: [
          btn(false),
          Expanded(child: Text('$qty', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Onest', fontSize: size >= 44 ? 16 : 14, fontWeight: FontWeight.w600, color: fg, fontFeatures: const [FontFeature.tabularFigures()]))),
          btn(true),
        ]),
      ]),
    );
  }
}
