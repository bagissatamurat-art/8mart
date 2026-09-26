import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'mart_button.dart';

/// Пустое / ошибочное состояние: розовый круг с иллюстрацией или иконкой, заголовок, текст, действие.
class MartEmptyState extends StatelessWidget {
  const MartEmptyState({super.key, required this.title, this.text, this.image, this.icon, this.action, this.onAction});
  final String title;
  final String? text, image, action;
  final IconData? icon;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 128, height: 128, decoration: BoxDecoration(color: c.primary50, shape: BoxShape.circle),
          child: Center(child: image != null ? Image.asset(image!, package: MartAssets.package, width: 80, height: 80) : Icon(icon ?? Icons.search_off_rounded, size: 48, color: c.primary))),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: MartText.h3.copyWith(color: c.ink1)),
        if (text != null) ...[const SizedBox(height: 8), Text(text!, textAlign: TextAlign.center, style: MartText.small.copyWith(color: c.ink2))],
        if (action != null) ...[const SizedBox(height: 16), MartButton(label: action!, variant: MartButtonVariant.secondary, size: MartButtonSize.m44, onPressed: onAction)],
      ]),
    ));
  }
}
