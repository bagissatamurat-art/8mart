import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'mart_icons.dart';

/// Поле-кнопка: выглядит как MartInput (56, r16, подпись сверху), но не редактируется — по нажатию открывается отдельный экран
/// (поиск адреса в выборе способа: клавиатура не всплывает поверх карты). busy — справа лоадер вместо лупы.
class MartTapField extends StatelessWidget {
  const MartTapField({super.key, required this.label, required this.value, required this.onTap, this.required = false, this.busy = false, this.error = false});
  final String label, value;
  final VoidCallback onTap;
  final bool required, busy, error;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final filled = value.trim().isNotEmpty;
    return Semantics(
      button: true, label: filled ? '$label: $value. Изменить' : '$label — найти адрес',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onTap,
        child: AnimatedContainer(
          duration: MartMotion.press, height: MartHeight.field, padding: const EdgeInsets.only(left: 16, right: 14),
          decoration: BoxDecoration(color: error ? c.errorBg : c.surface2, borderRadius: BorderRadius.circular(MartRadius.field),
              border: Border.all(color: error ? c.error : Colors.transparent, width: 1.5)),
          child: ExcludeSemantics(child: Row(children: [
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(text: label, children: [if (required) TextSpan(text: ' *', style: TextStyle(color: c.error))]),
                  style: MartText.body.copyWith(fontSize: filled ? 12 : 16, color: c.ink2, height: 1.2)),
              if (filled) ...[
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: MartText.body.copyWith(color: c.ink1, height: 1.25)),
              ],
            ])),
            const SizedBox(width: 8),
            busy
                ? SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.primary, backgroundColor: c.border))
                : MartSearchIcon(color: c.ink2, size: 16),
          ])),
        ),
      ),
    );
  }
}
