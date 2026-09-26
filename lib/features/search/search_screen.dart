import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/catalog_repository.dart';
import '../../data/mock_data.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/catalog_cubit.dart';
import '../../state/search_history_cubit.dart';
import '../../ui/ui.dart';
import '../catalog/catalog_screen.dart';
import '../common/product_grid.dart';
import '../product/product_view.dart';

TextStyle _f(double size, FontWeight w, Color col, {double? h, double? ls}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: col, height: h, letterSpacing: ls);

/// Поиск 390 (05 Поиск.dc.html #5b + MartSearch mobile): белый экран, назад 40 + поле 48 в фокусе (розовое кольцо).
/// Пусто — «Вы искали» + «Часто ищут»; ввод — подсказки (подкатегории, товары с подсветкой, «Все результаты · N»);
/// Enter — результаты (#5d): серый фон, белая панель с запросом, чипсы категорий, сетка.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initial});
  final String? initial;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final _ctl = TextEditingController(text: widget.initial ?? '');
  final _focus = FocusNode();
  late final _results = CatalogCubit(autoload: false);
  late bool _submitted = (widget.initial ?? '').isNotEmpty;
  String? _cat;

  @override
  void initState() { super.initState(); if (_submitted) _results.search(_ctl.text); _ctl.addListener(() => setState(() {})); }
  @override
  void dispose() { _results.close(); _ctl.dispose(); _focus.dispose(); super.dispose(); }

  void _submit(String q) {
    if (q.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    _ctl.text = q;
    context.read<SearchHistoryCubit>().add(q);
    _results.search(q);
    setState(() { _submitted = true; _cat = null; });
  }

  void _edit() { setState(() => _submitted = false); _focus.requestFocus(); }

  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    final top = MediaQuery.paddingOf(context).top;
    if (_submitted) {
      return Scaffold(body: BlocProvider.value(value: _results, child: _Results(query: _ctl.text.trim(), cat: _cat, onCat: (v) => setState(() => _cat = v), onEdit: _edit, onQuery: _submit)));
    }
    final q = _ctl.text.trim();
    return Scaffold(
      backgroundColor: c.surface,
      body: Column(children: [
        Padding(padding: EdgeInsets.fromLTRB(16, top + 8, 16, 12), child: Row(children: [
          MartBackButton(onTap: () => context.pop()),
          const SizedBox(width: 8),
          Expanded(child: _Field(controller: _ctl, focus: _focus, onSubmitted: _submit)),
        ])),
        Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(12, 0, 12, 24), children: [
          if (q.isEmpty) _Start(onQuery: _submit) else _Suggest(query: q, onQuery: _submit),
        ])),
      ]),
    );
  }
}

/// Поле 48, фокус: рамка primary 1.5 + кольцо 3; × 28 (серый круг) — когда есть текст.
class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.focus, required this.onSubmitted});
  final TextEditingController controller;
  final FocusNode focus;
  final ValueChanged<String> onSubmitted;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    return Container(
      height: 48, padding: const EdgeInsets.only(left: 16, right: 10),
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999), border: Border.all(color: c.primary, width: 1.5),
          boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .18), spreadRadius: 3)]),
      child: Row(children: [
        Expanded(child: TextField(
          controller: controller, focusNode: focus, autofocus: true, textInputAction: TextInputAction.search, onSubmitted: onSubmitted,
          style: _f(16, FontWeight.w400, c.ink1), cursorColor: c.primary,
          decoration: InputDecoration.collapsed(hintText: t.searchHint, hintStyle: _f(16, FontWeight.w400, c.ink3)),
        )),
        if (controller.text.isNotEmpty) Semantics(button: true, label: 'Очистить', child: GestureDetector(
          behavior: HitTestBehavior.opaque, onTap: controller.clear,
          child: SizedBox(width: 36, height: 44, child: Center(child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c.border, shape: BoxShape.circle),
              child: Center(child: MartCross(size: 10, color: c.ink2))))),
        )),
      ]),
    );
  }
}

Widget _caps(BuildContext context, String text) => Text(text.toUpperCase(), style: _f(12, FontWeight.w600, context.mc.ink3, ls: .5));

class _Start extends StatelessWidget {
  const _Start({required this.onQuery});
  final ValueChanged<String> onQuery;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final recent = context.watch<SearchHistoryCubit>().state;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (recent.isNotEmpty) ...[
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Row(children: [
          Expanded(child: _caps(context, t.searchedBefore)),
          GestureDetector(onTap: context.read<SearchHistoryCubit>().clearHistory, child: Text(t.clearHistory, style: _f(13, FontWeight.w400, c.ink2))),
        ])),
        const SizedBox(height: 4),
        for (final r in recent) _Row(onTap: () => onQuery(r), child: Row(children: [
          CustomPaint(size: const Size.square(16), painter: _ClockPainter(c.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Text(r, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(15, FontWeight.w400, c.ink1))),
        ])),
        const SizedBox(height: 16),
      ],
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: _caps(context, t.popularQueries)),
      Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 8), child: Wrap(spacing: 8, children: [for (final p in MockData.popularQueries) MartChip(label: p, onTap: () => onQuery(p))])),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.child, required this.onTap, this.height = 44});
  final Widget child;
  final VoidCallback onTap;
  final double height;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Material(
        color: Colors.transparent, borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, highlightColor: context.mc.surface2, splashColor: Colors.transparent,
            child: SizedBox(height: height, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: child))),
      ));
}

class _Suggest extends StatelessWidget {
  const _Suggest({required this.query, required this.onQuery});
  final String query;
  final ValueChanged<String> onQuery;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final s = query.toLowerCase();
    final subs = MockData.subcategories.where((x) => x.name.toLowerCase().contains(s)).take(2).toList();
    final hits = MockData.products.where((p) => CatalogRepository.matches(p, query)).toList();
    if (subs.isEmpty && hits.isEmpty) return _Empty(query: query, onQuery: onQuery);
    Widget hl(String name) {
      final i = name.toLowerCase().indexOf(s);
      final base = _f(15, FontWeight.w400, c.ink1, h: 1.3);
      if (i < 0) return Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
      return Text.rich(TextSpan(children: [
        TextSpan(text: name.substring(0, i)),
        TextSpan(text: name.substring(i, i + s.length), style: TextStyle(fontWeight: FontWeight.w700, color: c.primary)),
        TextSpan(text: name.substring(i + s.length)),
      ]), maxLines: 1, overflow: TextOverflow.ellipsis, style: base);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (subs.isNotEmpty) ...[
        for (final sc in subs) _Row(onTap: () => context.go('/catalog/${sc.parentId}?sub=${sc.id}'), child: Row(children: [
          CustomPaint(size: const Size.square(16), painter: _GridPainter(c.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Text.rich(TextSpan(text: sc.name, children: [TextSpan(text: ' · ${MockData.category(sc.parentId)?.name ?? ''}', style: TextStyle(color: c.ink3))]),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(15, FontWeight.w400, c.ink1))),
          Text('${MockData.products.where((p) => p.subId == sc.id).length}', style: _f(13, FontWeight.w400, c.ink3)),
        ])),
        Container(height: 1, margin: const EdgeInsets.fromLTRB(12, 2, 12, 4), color: c.divider),
      ],
      for (final p in hits.take(5)) _Row(height: 60, onTap: () => openProductSheet(context, p), child: Row(children: [
        SizedBox.square(dimension: 44, child: MartImage(p.image, radius: 10, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          hl(p.name),
          const SizedBox(height: 2),
          Text(p.pack, style: _f(13, FontWeight.w400, c.ink3)),
        ])),
        const SizedBox(width: 12),
        if (p.price != null) Text('${p.hasVariants ? 'от ' : ''}${money(p.price!)}', style: _f(15, FontWeight.w700, c.ink1)),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 0), child: GestureDetector(
        onTap: () => onQuery(query),
        child: Container(height: 44, decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(t.allResults(hits.length), style: _f(14, FontWeight.w600, c.ink1)),
            const SizedBox(width: 8),
            MartChevron(color: c.ink1, size: 5),
          ])),
      )),
    ]);
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.query, required this.onQuery});
  final String query;
  final ValueChanged<String> onQuery;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28), child: Column(children: [
      Text(t.nothingFoundFor(query), textAlign: TextAlign.center, style: _f(16, FontWeight.w700, c.ink1)),
      const SizedBox(height: 8),
      Text(t.nothingFoundSearchHint, textAlign: TextAlign.center, style: _f(14, FontWeight.w400, c.ink2, h: 1.4)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, alignment: WrapAlignment.center, children: [for (final p in MockData.popularQueries.take(3)) MartChip(label: p, onTap: () => onQuery(p))]),
    ]));
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.query, required this.cat, required this.onCat, required this.onEdit, required this.onQuery});
  final String query;
  final String? cat;
  final ValueChanged<String?> onCat;
  final VoidCallback onEdit;
  final ValueChanged<String> onQuery;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final cubit = context.watch<CatalogCubit>();
    final s = cubit.state;
    final byCat = <String, int>{};
    for (final p in s.items) { byCat[p.categoryId] = (byCat[p.categoryId] ?? 0) + 1; }
    final items = cat == null ? s.items : s.items.where((p) => p.categoryId == cat).toList();
    return Column(children: [
      MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), children: [
        Row(children: [
          MartBackButton(onTap: onEdit),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(onTap: onEdit, child: Container(
            height: 48, padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(999)),
            child: Text(query, maxLines: 1, overflow: TextOverflow.ellipsis, style: _f(16, FontWeight.w400, c.ink1))))),
        ]),
        SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, clipBehavior: Clip.none, children: [
          MartActionChip(label: t.filters, count: s.filter.count, onTap: () => openFiltersSheet(context, cubit)),
          const SizedBox(width: 8),
          MartChip(label: t.chipAll, selected: cat == null, onTap: () => onCat(null)),
          for (final e in byCat.entries) Padding(padding: const EdgeInsets.only(left: 8),
              child: MartChip(label: MockData.category(e.key)?.name ?? e.key, count: e.value, selected: cat == e.key, onTap: () => onCat(e.key))),
        ])),
        Row(children: [
          Expanded(child: Text(s.loading ? '' : t.itemsCount(cat == null ? s.total : items.length), style: _f(14, FontWeight.w400, c.ink3))),
          GestureDetector(onTap: () => openSortSheet(context, cubit), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(s.sort == SortKind.popular ? t.byRelevance : sortLabel(t, s.sort), style: _f(14, FontWeight.w500, c.ink1)),
            const SizedBox(width: 6),
            MartChevron(dir: ChevronDir.down, color: c.ink2, size: 5),
          ])),
        ]),
      ]),
      Expanded(child: s.offline
          ? MartEmptyState(icon: Icons.wifi_off_rounded, title: t.noInternet, text: t.noInternetHint, action: t.retry, onAction: cubit.load)
          : s.empty
              ? ListView(children: [_Empty(query: query, onQuery: onQuery)])
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) { if (n.metrics.extentAfter < 600) cubit.more(); return false; },
                  child: CustomScrollView(slivers: [
                    SliverPadding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), sliver: ProductGridSliver(items: items, loading: s.loading, loadingMore: s.loadingMore)),
                    if (s.end) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text(t.endOfList, textAlign: TextAlign.center, style: _f(13, FontWeight.w400, c.ink3)))),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  ]),
                )),
    ]);
  }
}

/// Часы (недавние запросы): кольцо 16 (линия 2) + стрелки.
class _ClockPainter extends CustomPainter {
  _ClockPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.width / 2 - 1, p);
    canvas.drawPath(Path()..moveTo(7, 4)..lineTo(7, 8)..lineTo(10, 8), p);
  }
  @override
  bool shouldRepaint(_ClockPainter o) => o.color != color;
}

/// Сетка 2×2 (подсказка-категория).
class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const w = 7.0;
    for (final o in const [Offset(0, 0), Offset(9, 0), Offset(0, 9), Offset(9, 9)]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + .75, o.dy + .75, w - 1.5, w - 1.5), const Radius.circular(2.25)), p);
    }
  }
  @override
  bool shouldRepaint(_GridPainter o) => o.color != color;
}
