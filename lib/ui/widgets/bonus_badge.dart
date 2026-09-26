import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';

/// Зелёная монетка «Б» + «+N». 1 бонус = 1 тг.
class BonusBadge extends StatelessWidget {
  const BonusBadge({super.key, required this.amount, this.compact = false, this.label});
  final int amount;
  /// Свой текст вместо «+N» (например, в правилах бонусов).
  final String? label;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final coin = compact ? 12.0 : 16.0;
    return Container(
      height: compact ? 20 : 24,
      padding: EdgeInsets.fromLTRB(compact ? 3 : 4, 0, 8, 0),
      decoration: BoxDecoration(color: c.successBg, borderRadius: BorderRadius.circular(MartRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: coin, height: coin, alignment: Alignment.center, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
          child: Text('Б', style: TextStyle(fontFamily: MartText.family, fontSize: compact ? 8 : 10, fontWeight: FontWeight.w800, color: Colors.white, height: 1))),
        const SizedBox(width: 5),
        Text(label ?? '+$amount', style: MartText.caption.copyWith(fontWeight: FontWeight.w700, color: c.successText)),
      ]),
    );
  }
}
