import 'package:flutter/material.dart';

/// Цветовые токены 8mart. Источник правды — App UI Kit.dc.html.
@immutable
class MartColors extends ThemeExtension<MartColors> {
  const MartColors({
    required this.bg, required this.surface, required this.surface2, required this.surface3,
    required this.ink1, required this.ink2, required this.ink3, required this.border, required this.divider,
    required this.primary, required this.primaryPressed, required this.primary50, required this.primary100, required this.focusRing,
    required this.success, required this.successText, required this.successBg, required this.error, required this.errorBg,
    required this.warning, required this.warningBg, required this.inverse, required this.onInverse, required this.primaryOnInverse,
    required this.overlay,
  });

  final Color bg, surface, surface2, surface3, ink1, ink2, ink3, border, divider;
  final Color primary, primaryPressed, primary50, primary100, focusRing;
  final Color success, successText, successBg, error, errorBg, warning, warningBg;
  final Color inverse, onInverse, primaryOnInverse, overlay;

  /// Постоянные цвета — не зависят от темы.
  static const onPrimary = Color(0xFFFFFFFF);
  static const photoBg = Color(0xFFFFFFFF); // фото товаров всегда на белом
  static const kaspi = Color(0xFFF14635);
  static const favorite = Color(0xFFEE1D74);
  static const favoriteOutline = Color(0xFF6B6873);

  static const light = MartColors(
    bg: Color(0xFFF2F2F4), surface: Color(0xFFFFFFFF), surface2: Color(0xFFF7F7F8), surface3: Color(0xFFEEEDF1),
    ink1: Color(0xFF17151A), ink2: Color(0xFF6B6873), ink3: Color(0xFF9E9BA6), border: Color(0xFFE3E2E7), divider: Color(0xFFEEEDF1),
    primary: Color(0xFFEE1D74), primaryPressed: Color(0xFFD6136A), primary50: Color(0xFFFDF0F6), primary100: Color(0xFFFBDCEA), focusRing: Color(0x2EEE1D74),
    success: Color(0xFF1DA765), successText: Color(0xFF13824D), successBg: Color(0xFFEAF7F0), error: Color(0xFFE23D3D), errorBg: Color(0xFFFDEDED),
    warning: Color(0xFFF59E0B), warningBg: Color(0xFFFEF3DC), inverse: Color(0xFF17151A), onInverse: Color(0xFFFFFFFF), primaryOnInverse: Color(0xFFF7B4D1),
    overlay: Color(0x7317151A),
  );

  static const dark = MartColors(
    bg: Color(0xFF0F0E11), surface: Color(0xFF1B1A1F), surface2: Color(0xFF25232A), surface3: Color(0xFF2E2C33),
    ink1: Color(0xFFF4F3F6), ink2: Color(0xFFA9A6B1), ink3: Color(0xFF75727D), border: Color(0xFF34323A), divider: Color(0xFF2A2830),
    primary: Color(0xFFF2438A), primaryPressed: Color(0xFFEE1D74), primary50: Color(0xFF3A1627), primary100: Color(0xFF4E1A33), focusRing: Color(0x47F2438A),
    success: Color(0xFF2FBF78), successText: Color(0xFF5BD394), successBg: Color(0xFF12301F), error: Color(0xFFFF5C5C), errorBg: Color(0xFF3A1717),
    warning: Color(0xFFFBBF24), warningBg: Color(0xFF3A2E10), inverse: Color(0xFFF4F3F6), onInverse: Color(0xFF17151A), primaryOnInverse: Color(0xFFD6136A),
    overlay: Color(0x99000000),
  );

  @override
  MartColors copyWith() => this;

  @override
  MartColors lerp(ThemeExtension<MartColors>? other, double t) {
    if (other is! MartColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return MartColors(
      bg: c(bg, other.bg), surface: c(surface, other.surface), surface2: c(surface2, other.surface2), surface3: c(surface3, other.surface3),
      ink1: c(ink1, other.ink1), ink2: c(ink2, other.ink2), ink3: c(ink3, other.ink3), border: c(border, other.border), divider: c(divider, other.divider),
      primary: c(primary, other.primary), primaryPressed: c(primaryPressed, other.primaryPressed), primary50: c(primary50, other.primary50),
      primary100: c(primary100, other.primary100), focusRing: c(focusRing, other.focusRing),
      success: c(success, other.success), successText: c(successText, other.successText), successBg: c(successBg, other.successBg),
      error: c(error, other.error), errorBg: c(errorBg, other.errorBg), warning: c(warning, other.warning), warningBg: c(warningBg, other.warningBg),
      inverse: c(inverse, other.inverse), onInverse: c(onInverse, other.onInverse), primaryOnInverse: c(primaryOnInverse, other.primaryOnInverse),
      overlay: c(overlay, other.overlay),
    );
  }
}

extension MartThemeX on BuildContext {
  MartColors get mc => Theme.of(this).extension<MartColors>()!;
}
