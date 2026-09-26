import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_tokens.dart';
import '../widgets/mart_icons.dart';
import '../widgets/mart_sheet.dart';

/// Белая панель сверху экрана: статус-бар белый, низ скруглён 24 (как во всех макетах 390).
class MartTopPanel extends StatelessWidget {
  const MartTopPanel({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 14), this.gap = 12});
  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Container(
      decoration: BoxDecoration(color: c.surface, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(MartRadius.panel))),
      padding: padding.copyWith(top: padding.top + MediaQuery.paddingOf(context).top),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
      ]),
    );
  }
}

/// Шапка главной (MartHeader mode="mobile"): логотип 24 + способ получения 40, под ними поиск 48.
class MartHomeHeader extends StatelessWidget {
  const MartHomeHeader({super.key, required this.methodText, required this.methodChosen, required this.onMethod, required this.searchHint, required this.onSearch});
  final String methodText, searchHint;
  final bool methodChosen;
  final VoidCallback onMethod, onSearch;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), children: [
      Row(children: [
        SvgPicture.asset('assets/images/logo.svg', package: MartAssets.package, height: 24,
            colorFilter: Theme.of(context).brightness == Brightness.dark ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null),
        const SizedBox(width: 12),
        const Spacer(),
        GestureDetector(
          onTap: onMethod,
          child: Container(
            height: 40, padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MartRadius.pill)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: methodChosen ? c.success : c.warning, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              ConstrainedBox(constraints: const BoxConstraints(maxWidth: 170), child: Text(methodText, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Onest', fontSize: 14, fontWeight: FontWeight.w500, color: c.ink1))),
              const SizedBox(width: 8),
              MartChevron(dir: ChevronDir.down, color: c.ink2, size: 6),
            ]),
          ),
        ),
      ]),
      MartSearchPill(hint: searchHint, onTap: onSearch, height: 48, hintColor: c.ink3, fontSize: 16),
    ]);
  }
}

/// Поле-кнопка поиска (открывает экран поиска). Главная — 48/16, каталог — 44/15.
class MartSearchPill extends StatelessWidget {
  const MartSearchPill({super.key, required this.hint, required this.onTap, this.height = 44, this.fontSize = 15, this.hintColor});
  final String hint;
  final VoidCallback onTap;
  final double height, fontSize;
  final Color? hintColor;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height, padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(MartRadius.pill)),
        child: Row(children: [
          MartSearchIcon(color: c.ink2),
          const SizedBox(width: 10),
          Expanded(child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Onest', fontSize: fontSize, color: hintColor ?? c.ink3))),
        ]),
      ),
    );
  }
}

/// Заголовок внутреннего экрана: назад 40 · заголовок 22/800 · счётчик справа.
class MartTitleRow extends StatelessWidget {
  const MartTitleRow({super.key, required this.title, this.trailing, this.onBack});
  final String title;
  final String? trailing;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(children: [
      MartBackButton(onTap: onBack),
      const SizedBox(width: 8),
      Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontFamily: 'Onest', fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.44, color: c.ink1))),
      if (trailing != null) Text(trailing!, style: TextStyle(fontFamily: 'Onest', fontSize: 14, color: c.ink3)),
    ]);
  }
}

/// Кнопка-чип 36 с шевроном вниз (сортировка) или счётчиком (фильтры: активна → розовая заливка).
class MartActionChip extends StatelessWidget {
  const MartActionChip({super.key, required this.label, required this.onTap, this.count = 0, this.chevron = false});
  final String label;
  final VoidCallback onTap;
  final int count;
  final bool chevron;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final on = count > 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: onTap,
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Container(
        height: MartHeight.chip, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: on ? c.primary : c.surface, borderRadius: BorderRadius.circular(MartRadius.pill), border: Border.all(color: on ? c.primary : c.border, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontFamily: 'Onest', fontSize: 14, fontWeight: FontWeight.w500, color: on ? MartColors.onPrimary : c.ink1)),
          if (on) ...[const SizedBox(width: 8), Container(
            constraints: const BoxConstraints(minWidth: 18), height: 18, padding: const EdgeInsets.symmetric(horizontal: 5), alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
            child: Text('$count', style: TextStyle(fontFamily: 'Onest', fontSize: 12, fontWeight: FontWeight.w700, color: c.primary, height: 1)))],
          if (chevron) ...[const SizedBox(width: 8), MartChevron(dir: ChevronDir.down, color: c.ink2, size: 5)],
        ]),
      )),
    );
  }
}

/// Полосатый плейсхолдер (нет фото / баннер): диагональ 135°, две светлые полосы.
class MartStripes extends StatelessWidget {
  const MartStripes({super.key, this.a = const Color(0xFFF2F2F4), this.b = const Color(0xFFF7F7F8), this.step = 10, this.radius = 14, this.label});
  final Color a, b;
  final double step, radius;
  final String? label;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(painter: _StripePainter(a, b, step), child: label == null ? const SizedBox.expand() : Align(
          alignment: Alignment.bottomLeft,
          child: Padding(padding: const EdgeInsets.all(16), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text(label!, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4, color: Color(0xFFBF0F5E))))),
        )),
      );
}

class _StripePainter extends CustomPainter {
  _StripePainter(this.a, this.b, this.step);
  final Color a, b;
  final double step;
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = b);
    final p = Paint()..color = a..strokeWidth = step;
    final d = step * 2 * 1.4142;
    for (double x = -s.height; x < s.width + s.height; x += d) {
      canvas.drawLine(Offset(x + s.height, 0), Offset(x, s.height), p);
    }
  }
  @override
  bool shouldRepaint(_StripePainter o) => o.a != a || o.b != b || o.step != step;
}
