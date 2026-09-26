/// Шкалы 8mart: одно значение — одно место.
abstract final class MartSpace {
  static const double s4 = 4, s8 = 8, s12 = 12, s16 = 16, s20 = 20, s24 = 24, s32 = 32;
}

abstract final class MartRadius {
  static const double badge = 8, photo = 12, field = 16, card = 20, panel = 24, pill = 999;
}

/// Высоты контролов: 36 чип · 40 степпер/кнопка S · 44 кнопка M · 56 кнопка L/поле · 64 ячейка кода/таб-бар.
abstract final class MartHeight {
  static const double chip = 36, stepper = 40, buttonS = 36, buttonSM = 40, buttonM = 44, buttonL = 56;
  static const double field = 56, textarea = 84, codeCell = 64, tabBar = 64;
  /// Минимальная зона касания (iOS 44 pt, Android 48 dp — берём 44 визуально + отступы до 48).
  static const double hit = 44;
}

/// Для использования виджетов из другого пакета (Widgetbook): MartAssets.package = 'mart8'.
abstract final class MartAssets {
  static String? package;
}

abstract final class MartMotion {
  static const press = Duration(milliseconds: 150);
  static const sheet = Duration(milliseconds: 250);
  static const page = Duration(milliseconds: 300);
}
