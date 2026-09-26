import 'package:flutter/material.dart';

/// Типографика на Onest. Цвет задаётся темой (DefaultTextStyle) или copyWith(color:).
abstract final class MartText {
  static const family = 'Onest';
  static const h1 = TextStyle(fontFamily: family, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.56, height: 1.15);
  static const h2 = TextStyle(fontFamily: family, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.44, height: 1.2);
  static const h3 = TextStyle(fontFamily: family, fontSize: 18, fontWeight: FontWeight.w700, height: 1.3);
  static const title = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3);
  static const body = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w400, height: 1.45);
  static const bodyStrong = TextStyle(fontFamily: family, fontSize: 15, fontWeight: FontWeight.w600, height: 1.3);
  static const small = TextStyle(fontFamily: family, fontSize: 14, fontWeight: FontWeight.w400, height: 1.4);
  static const caption = TextStyle(fontFamily: family, fontSize: 12, fontWeight: FontWeight.w500, height: 1.35);
  static const tab = TextStyle(fontFamily: family, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2);
  static const price = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]);
  static const button = TextStyle(fontFamily: family, fontSize: 16, fontWeight: FontWeight.w600, height: 1);
}
