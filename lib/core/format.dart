/// Деньги: «4 090 тг.» (пробел-разделитель тысяч, неразрывный). В свободном тексте — moneyText(): «4 090 тг».
String _group(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '−' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('\u00A0');
    b.write(s[i]);
  }
  return b.toString();
}

String money(int n) => '${_group(n)}\u00A0тг.';
String moneyText(int n) => '${_group(n)}\u00A0тг';
String kg(num v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')}\u00A0т' : '${v.round()}\u00A0кг';

/// Склонение: plural(5, 'товар', 'товара', 'товаров') → «товаров».
String plural(int n, String one, String few, String many) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}
