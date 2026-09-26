import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mart_colors.dart';
import 'mart_text.dart';
import 'mart_tokens.dart';

/// Одна тема на обе платформы. iOS — свайп назад (Cupertino-переходы), Android — системная кнопка «назад».
ThemeData buildMartTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? MartColors.dark : MartColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary, onPrimary: MartColors.onPrimary,
    secondary: c.primary50, onSecondary: c.primary,
    error: c.error, onError: MartColors.onPrimary,
    surface: c.surface, onSurface: c.ink1,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: MartText.family,
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.surface,
    dividerColor: c.divider,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    extensions: [c],
    textTheme: TextTheme(
      headlineMedium: MartText.h1.copyWith(color: c.ink1),
      headlineSmall: MartText.h2.copyWith(color: c.ink1),
      titleLarge: MartText.h3.copyWith(color: c.ink1),
      titleMedium: MartText.title.copyWith(color: c.ink1),
      bodyLarge: MartText.body.copyWith(color: c.ink1),
      bodyMedium: MartText.small.copyWith(color: c.ink1),
      bodySmall: MartText.caption.copyWith(color: c.ink3),
      labelLarge: MartText.button,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface, foregroundColor: c.ink1, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
      titleTextStyle: MartText.h2.copyWith(color: c.ink1),
      systemOverlayStyle: brightness == Brightness.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface, modalBackgroundColor: c.surface, modalBarrierColor: c.overlay, elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(MartRadius.panel))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.inverse, contentTextStyle: MartText.small.copyWith(color: c.onInverse), actionTextColor: c.primaryOnInverse,
      behavior: SnackBarBehavior.floating, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MartRadius.field)),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.primary, selectionColor: c.primary100, selectionHandleColor: c.primary),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    }),
  );
}
