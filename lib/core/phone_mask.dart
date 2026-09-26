import 'dart:math';

import 'package:flutter/services.dart';

/// Маска телефона +7 (999) 999-99-99.
/// • Ведущая 8 заменяется на +7. • Если после «+» код не 7 — свободный формат «+цифры».
/// • Маска считается только по цифрам: Backspace на символе маски стирает соседнюю цифру.
/// • Пустое поле — действительно пустое.
class PhoneMaskFormatter extends TextInputFormatter {
  static final _nonDigit = RegExp(r'\D');

  static String digitsOf(String s) => s.replaceAll(_nonDigit, '');

  static bool isComplete(String s) {
    final d = digitsOf(s);
    if (s.startsWith('+') && !s.startsWith('+7')) return d.length >= 8;
    return d.length == 11;
  }

  static String format(String digits) {
    final d = digits.substring(1);
    final b = StringBuffer('+7');
    if (d.isEmpty) return b.toString();
    b.write(' (${d.substring(0, min(3, d.length))}');
    if (d.length <= 3) return b.toString();
    b.write(') ${d.substring(3, min(6, d.length))}');
    if (d.length <= 6) return b.toString();
    b.write('-${d.substring(6, min(8, d.length))}');
    if (d.length <= 8) return b.toString();
    b.write('-${d.substring(8, min(10, d.length))}');
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    final deleting = raw.length < oldValue.text.length;
    if (raw == '+' && !deleting) return const TextEditingValue(text: '+', selection: TextSelection.collapsed(offset: 1));
    var digits = digitsOf(raw);
    if (deleting && digits == digitsOf(oldValue.text) && digits.isNotEmpty) {
      final cur = newValue.selection.baseOffset.clamp(0, raw.length);
      final before = digitsOf(raw.substring(0, cur)).length - 1;
      if (before >= 0) digits = digits.substring(0, before) + digits.substring(before + 1);
    }
    final intl = raw.startsWith('+') && digits.isNotEmpty && digits[0] != '7';
    String text;
    if (intl) {
      text = '+${digits.substring(0, min(15, digits.length))}';
    } else if (digits.isEmpty) {
      text = '';
    } else {
      if (digits[0] == '8') digits = '7${digits.substring(1)}';
      if (digits[0] != '7') digits = '7$digits';
      text = format(digits.substring(0, min(11, digits.length)));
      if (text == '+7' && deleting) text = '';
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
