import 'package:flutter/material.dart';

import '../theme/mart_colors.dart';
import '../theme/mart_text.dart';
import 'mart_image.dart';

/// Миниатюра сторис на главной (как на сайте, mobile 88×116, r18): фото, затемнение снизу, подпись белым.
/// Не просмотрена — розовая рамка, просмотрена — серая.
class MartStoryThumb extends StatelessWidget {
  const MartStoryThumb({super.key, required this.cover, required this.title, required this.seen, required this.onTap});
  final String cover, title;
  final bool seen;
  final VoidCallback onTap;

  static const width = 88.0, height = 116.0;

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Semantics(
      button: true, label: seen ? title : '$title, не просмотрено',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width, height: height, padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: seen ? c.border : c.primary, width: 2.5)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Stack(fit: StackFit.expand, children: [
              MartImage(cover, radius: 0, fit: BoxFit.cover),
              const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x0017151A), Color(0x9917151A)], stops: [.45, 1]))),
              // Одно слово не переносится по буквам — в одну строку, длинное слегка ужимается.
              Positioned(left: 6, right: 6, bottom: 8, child: ExcludeSemantics(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                  child: Text(title, maxLines: 1, softWrap: false, style: MartText.caption.copyWith(fontWeight: FontWeight.w700, color: Colors.white, height: 1.2))))),
            ]),
          ),
        ),
      ),
    );
  }
}
