import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MartButtonVariant { primary, secondary, ghost, danger }

enum MartButtonSize {
  s36(MartHeight.buttonS, 16, 14), s40(MartHeight.buttonSM, 16, 14), m44(MartHeight.buttonM, 20, 15), l56(MartHeight.buttonL, 28, 16);
  const MartButtonSize(this.height, this.padding, this.fontSize);
  final double height, padding, fontSize;
}

/// Кнопка. amount → split-CTA «текст · сумма». disabledReason блокирует кнопку и объясняет почему (показывайте текст под кнопкой).
class MartButton extends StatefulWidget {
  const MartButton({
    super.key, required this.label, this.onPressed, this.variant = MartButtonVariant.primary, this.size = MartButtonSize.l56,
    this.amount, this.loading = false, this.expanded = false, this.disabledReason,
  });
  final String label;
  final VoidCallback? onPressed;
  final MartButtonVariant variant;
  final MartButtonSize size;
  final String? amount;
  final bool loading, expanded;
  final String? disabledReason;

  bool get enabled => onPressed != null && disabledReason == null;

  @override
  State<MartButton> createState() => _MartButtonState();
}

class _MartButtonState extends State<MartButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final w = widget;
    late Color bg, bgDown, fg;
    Border? border;
    switch (w.variant) {
      case MartButtonVariant.primary: bg = c.primary; bgDown = c.primaryPressed; fg = MartColors.onPrimary;
      case MartButtonVariant.secondary: bg = c.primary50; bgDown = c.primary100; fg = c.primary;
      case MartButtonVariant.ghost: bg = Colors.transparent; bgDown = c.surface3; fg = c.ink1; border = Border.all(color: c.border, width: 1.5);
      case MartButtonVariant.danger: bg = c.errorBg; bgDown = c.errorBg; fg = c.error;
    }
    if (!w.enabled) { bg = c.surface3; bgDown = c.surface3; fg = c.ink3; border = null; }
    final style = MartText.button.copyWith(fontSize: w.size.fontSize, color: fg);
    final content = w.loading
        ? SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(w.label, style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (w.amount != null && w.amount!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(width: 1, height: 16, color: fg.withValues(alpha: .35)),
              const SizedBox(width: 10),
              Text(w.amount!, style: style.copyWith(fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ]);
    return Semantics(
      button: true, enabled: w.enabled, label: w.amount == null ? w.label : '${w.label}, ${w.amount}', hint: w.disabledReason,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: w.enabled && !w.loading ? w.onPressed : null,
        onTapDown: w.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? .99 : 1, duration: MartMotion.press,
          child: AnimatedContainer(
            duration: MartMotion.press,
            height: w.size.height,
            width: w.expanded ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: w.size.padding),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _down ? bgDown : bg, borderRadius: BorderRadius.circular(MartRadius.pill), border: border),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Официальная кнопка Kaspi Pay (SVG от банка) — без суммы, только радиус pill.
class KaspiPayButton extends StatelessWidget {
  const KaspiPayButton({super.key, this.onPressed, this.loading = false, this.disabledReason});
  final VoidCallback? onPressed;
  final bool loading;
  final String? disabledReason;
  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && disabledReason == null && !loading;
    return Semantics(
      button: true, enabled: enabled, label: 'Kaspi Pay', hint: disabledReason,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Opacity(
          opacity: enabled || loading ? 1 : .4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MartRadius.pill),
            child: SizedBox(
              height: MartHeight.buttonL, width: double.infinity,
              child: loading
                  ? const ColoredBox(color: MartColors.kaspi, child: Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))))
                  : SvgPicture.asset('assets/images/kaspi-pay.svg', package: MartAssets.package, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
