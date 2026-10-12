import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/geo_repository.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../ui/ui.dart';

TextStyle _f(double size, FontWeight w, Color col, {double? h}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h);

/// Выбранный в поиске адрес: дом (с координатами, если есть) и город — его можно сменить прямо в поиске.
class AddressPick {
  const AddressPick(this.suggestion, this.city);
  final AddressSuggestion suggestion;
  final City city;
}

/// Поиск адреса — отдельный экран поверх выбора способа (как на сайте): поле, ниже город (список), подсказки с подсветкой совпадения.
/// Подсказки — только в выбранном городе (точнее и меньше запросов к DaData), с 3 символов, debounce 300 мс, устаревший ответ отбрасывается.
/// Улица без дома → в поле «Улица, » и курсор для номера дома; с домом — экран закрывается, карта летит к дому.
/// «Указать на карте» — закрыть без выбора (адрес поставят пином).
Future<AddressPick?> openAddressSearch(BuildContext context, {required String value, required City city}) =>
    Navigator.of(context).push<AddressPick>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => _AddressSearch(value: value, city: city)));

class _AddressSearch extends StatefulWidget {
  const _AddressSearch({required this.value, required this.city});
  final String value;
  final City city;
  @override
  State<_AddressSearch> createState() => _AddressSearchState();
}

class _AddressSearchState extends State<_AddressSearch> {
  static const _geo = GeoRepository();
  late final _ctl = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  late City _city = widget.city;
  Timer? _debounce;
  List<AddressSuggestion> _items = const [];
  bool _loading = false, _error = false;
  int _req = 0;
  /// Ответы за сессию: тот же текст в том же городе — без запроса.
  static final _cache = <String, List<AddressSuggestion>>{};

  @override
  void initState() {
    super.initState();
    _ctl.selection = TextSelection.collapsed(offset: _ctl.text.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _search();
  }

  @override
  void dispose() { _debounce?.cancel(); _ctl.dispose(); _focus.dispose(); super.dispose(); }

  String get _q => _ctl.text.trim();

  void _search() {
    _debounce?.cancel();
    final q = _q, key = '${_city.id}|${q.toLowerCase()}';
    if (q.length < 3) { setState(() { _items = const []; _loading = false; _error = false; }); return; }
    final hit = _cache[key];
    if (hit != null) { setState(() { _items = hit; _loading = false; _error = false; }); return; }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final req = ++_req;
      try {
        final r = await _geo.suggest(q, _city);
        _cache[key] = r;
        if (mounted && req == _req) setState(() { _items = r; _loading = false; _error = false; });
      } catch (_) {
        if (mounted && req == _req) setState(() { _items = const []; _loading = false; _error = true; });
      }
    });
  }

  void _pick(AddressSuggestion s) {
    if (!s.needHouse) { Navigator.of(context).pop(AddressPick(s, _city)); return; }
    // Улица без дома — дописать номер: «Улица, » и курсор в конец.
    final next = '${s.title}, ';
    _ctl.value = TextEditingValue(text: next, selection: TextSelection.collapsed(offset: next.length));
    _focus.requestFocus();
    _search();
  }

  /// Куски текста, совпавшие с началами слов запроса («каб 11» → **Каб**анбай батыра, **11**).
  List<TextSpan> _highlight(String text, TextStyle base, TextStyle mark) {
    final words = RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(_q.toLowerCase()).map((m) => m[0]!).toList()..sort((a, b) => b.length - a.length);
    if (words.isEmpty) return [TextSpan(text: text, style: base)];
    final re = RegExp('(?<![\\p{L}\\p{N}])(${words.map(RegExp.escape).join('|')})', caseSensitive: false, unicode: true);
    final out = <TextSpan>[];
    var i = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > i) out.add(TextSpan(text: text.substring(i, m.start), style: base));
      out.add(TextSpan(text: m[0], style: mark));
      i = m.end;
    }
    if (i < text.length) out.add(TextSpan(text: text.substring(i), style: base));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final q = _q;
    Widget hint(String text) => Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 0), child: Text(text, style: _f(14, FontWeight.w400, c.ink2, h: 1.4)));
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(8, 8, 16, 8), child: Row(children: [
          Semantics(button: true, label: 'Назад', child: GestureDetector(
            behavior: HitTestBehavior.opaque, onTap: () => Navigator.of(context).pop(),
            child: SizedBox.square(dimension: MartHeight.hit, child: Center(child: MartChevron(dir: ChevronDir.left, color: c.ink1, size: 7))),
          )),
          const SizedBox(width: 4),
          Text('Адрес доставки', style: _f(18, FontWeight.w700, c.ink1)),
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          MartInput(label: 'Улица и номер дома', controller: _ctl, focusNode: _focus, textInputAction: TextInputAction.search,
              onChanged: (_) => _search(), onSubmitted: (_) { if (_items.isNotEmpty) _pick(_items.first); }),
          const SizedBox(height: 12),
          if (MockData.cities.length > 1) MartSelect(label: 'Город', value: _city.id, sheetTitle: 'Город',
              options: [for (final ct in MockData.cities) MartSelectOption(ct.id, ct.name)],
              onChanged: (id) { setState(() => _city = MockData.cities.firstWhere((x) => x.id == id)); _search(); }),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 16), keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, children: [
          if (q.length < 3) hint('Ищем в городе ${_city.name}. Начните с улицы — например, «Кабанбай батыра 11»')
          else if (_loading && _items.isEmpty) ...[for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.all(4), child: MartSkeletonRow())]
          else if (_error) hint('Подсказки недоступны — укажите дом пином на карте')
          else if (_items.isEmpty) hint('Не нашли «$q» — поставьте пин на карте, адрес подставится')
          else for (final s in _items) Opacity(opacity: _loading ? .55 : 1, child: Semantics(
            button: true, label: s.needHouse ? '${s.title}. Добавьте номер дома' : '${s.title}, ${s.sub}',
            child: InkWell(
              onTap: () => _pick(s), borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 60), child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ExcludeSemantics(child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: c.surface2, shape: BoxShape.circle),
                      child: Center(child: MartSearchIcon(color: c.ink2, size: 14))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text.rich(TextSpan(children: _highlight(s.title, _f(15, FontWeight.w500, c.ink1, h: 1.3), _f(15, FontWeight.w700, c.primary, h: 1.3)))),
                    const SizedBox(height: 2),
                    Text(s.needHouse ? 'Добавьте номер дома' : s.sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: _f(13, FontWeight.w400, s.needHouse ? c.primary : c.ink2, h: 1.3)),
                  ])),
                ])),
              )),
            ),
          )),
        ])),
        Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.divider))),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, onTap: () => Navigator.of(context).pop(),
            child: SizedBox(height: MartHeight.hit, child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Text('Указать на карте', style: _f(15, FontWeight.w600, c.primary)),
            ])),
          ),
        ),
      ])),
    );
  }
}
