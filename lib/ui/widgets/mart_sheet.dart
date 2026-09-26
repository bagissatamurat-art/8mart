import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import '../theme/mart_tokens.dart';
import 'mart_icons.dart';

/// Шторка: граббер 36×5, свайп вниз закрывает, до 94 % высоты, учитывает клавиатуру.
/// bodyPadding — отступы содержимого (товар: 0 по бокам, галерея во всю ширину). closeOverlay — белая × 44 справа сверху поверх содержимого.
Future<T?> showMartSheet<T>(BuildContext context, {String? title, required WidgetBuilder builder, Widget? footer,
    EdgeInsets bodyPadding = const EdgeInsets.fromLTRB(16, 8, 16, 16), bool closeOverlay = false}) {
  return showModalBottomSheet<T>(
    context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: false,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .94),
    builder: (ctx) {
      final c = ctx.mc;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Stack(children: [Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 5, decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(3))),
          if (title != null) Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(children: [
              Expanded(child: Text(title, style: MartText.h2.copyWith(fontSize: 20, color: c.ink1))),
              MartCloseButton(onTap: () => Navigator.of(ctx).pop()),
            ]),
          ),
          Flexible(child: SingleChildScrollView(padding: bodyPadding, child: builder(ctx))),
          if (footer != null) MartBottomBar(child: footer),
        ]),
          if (closeOverlay) Positioned(right: 12, top: 12, child: Semantics(button: true, label: 'Закрыть', child: GestureDetector(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xF0FFFFFF), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x1F17151A), blurRadius: 8, offset: Offset(0, 2))]),
              child: const Center(child: MartCross(size: 14, color: Color(0xFF17151A)))),
          ))),
        ]),
      );
    },
  );
}

class MartCloseButton extends StatelessWidget {
  const MartCloseButton({super.key, required this.onTap, this.label = 'Закрыть'});
  final VoidCallback onTap;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Semantics(button: true, label: label, child: GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: onTap,
      child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: Container(width: 36, height: 36,
        decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle), child: Center(child: MartCross(size: 13, color: c.ink2))))),
    ));
  }
}

class MartBackButton extends StatelessWidget {
  const MartBackButton({super.key, this.onTap});
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Semantics(button: true, label: 'Назад', child: GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: Container(width: 40, height: 40, decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
        child: Center(child: MartChevron(dir: ChevronDir.left, color: c.ink1))))),
    ));
  }
}

/// Закреплённая снизу панель CTA: белый фон (surface), линия сверху divider, safe area.
class MartBottomBar extends StatelessWidget {
  const MartBottomBar({super.key, required this.child, this.note});
  final Widget child;
  final String? note;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.divider))),
      child: SafeArea(top: false, minimum: const EdgeInsets.only(bottom: 8), child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (note != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(note!, textAlign: TextAlign.center, style: MartText.caption.copyWith(fontSize: 13, color: c.error))),
          child,
        ]),
      )),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: c.warningBg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c.warning, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: MartText.small.copyWith(color: c.ink1))),
      ]),
    );
  }
}

void showMartToast(BuildContext context, String text, {String? action, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text), duration: const Duration(seconds: 3),
      action: action == null ? null : SnackBarAction(label: action, onPressed: onAction ?? () {}),
    ));
}
