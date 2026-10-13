import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import 'dart:async';

import '../../data/catalog.dart';
import '../../data/remote_config.dart';
import '../../data/catalog_repository.dart';
import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';
import '../../state/catalog_cubit.dart';
import '../common/product_grid.dart';

/// Каталог 390 (07 Каталог.dc.html #7b): корень — строки категорий → категория — плитки подкатегорий + «Все товары» → список.
TextStyle _t(double size, FontWeight w, Color c, {double? h}) => TextStyle(fontFamily: 'Onest', fontSize: size, fontWeight: w, color: c, height: h);

/// /catalog — «Каталог» 24/800, поиск 44, строки категорий: фото 72 · название 17/700 · «N разделов · N товаров» · шеврон.
class CatalogRootScreen extends StatelessWidget {
  const CatalogRootScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    return ListenableBuilder(listenable: Catalog.changes, builder: (context, _) => Scaffold(
      body: Column(children: [
        MartTopPanel(children: [
          Text(t.catalogTitle, style: _t(24, FontWeight.w800, c.ink1).copyWith(letterSpacing: -0.48)),
          MartSearchPill(hint: t.findProduct, onTap: () => context.push('/search')),
        ]),
        // С бэкендом: первый запуск без сети — «Повторить»; пока грузится — строки-скелетоны.
        if (Catalog.unavailable) Expanded(child: MartEmptyState(icon: Icons.wifi_off_rounded, title: t.noInternet, text: t.noInternetHint, action: t.retry, onAction: Catalog.init))
        else if (Catalog.loading) Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
          for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: MartSkeletonRow()),
        ]))
        else Expanded(child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: Catalog.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final cat = Catalog.categories[i];
            final subs = Catalog.subsOf(cat.id).length;
            final n = Catalog.count(cat.id);
            final meta = [if (subs > 0) t.sectionsCount(subs), if (n != null) t.itemsCount(n)].join(' · ');
            return GestureDetector(
              onTap: () => context.go('/catalog/${cat.id}'),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.card)),
                child: Row(children: [
                  SizedBox.square(dimension: 72, child: MartImage(cat.image, radius: 14, fit: BoxFit.cover)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cat.name, style: _t(17, FontWeight.w700, c.ink1)),
                    const SizedBox(height: 3),
                    Text(meta, style: _t(13, FontWeight.w400, c.ink2)),
                  ])),
                  MartChevron(color: c.ink3, size: 6),
                ]),
              ),
            );
          },
        )),
      ]),
    ));
  }
}

/// /catalog/:cat — без ?sub и есть подкатегории → плитки; ?sub=all|<id> или подкатегорий нет → список.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.categoryId, this.subId});
  final String categoryId;
  final String? subId;
  @override
  Widget build(BuildContext context) {
    final subs = Catalog.subsOf(categoryId);
    if (subId == null && subs.isNotEmpty) return ListenableBuilder(listenable: Catalog.changes, builder: (_, __) => _SubTiles(categoryId: categoryId, subs: subs));
    return BlocProvider(
      create: (_) => CatalogCubit(categoryId: categoryId, subId: subId == 'all' ? null : subId),
      child: _CategoryView(categoryId: categoryId),
    );
  }
}

/// Плитки подкатегорий 2 в ряд: фото 4:3 (радиус 12) · название 15/600 · «N товаров». Первая — «Все товары» на primary50.
class _SubTiles extends StatelessWidget {
  const _SubTiles({required this.categoryId, required this.subs});
  final String categoryId;
  final List<SubCategory> subs;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    // Счётчик и обложка раздела; с бэкендом до ответа счётчика нет, вместо обложки — полосы.
    String meta(String? sub) { final n = Catalog.count(categoryId, sub); return n == null ? '' : t.itemsCount(n); }
    Widget tile({required String name, required String meta, required Widget img, required VoidCallback onTap}) => GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(aspectRatio: 4 / 3, child: img),
              const SizedBox(height: 8),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: _t(15, FontWeight.w600, c.ink1, h: 1.25)),
                const SizedBox(height: 2),
                Text(meta, style: _t(12, FontWeight.w400, c.ink2)),
              ])),
            ]),
          ),
        );
    final tiles = <Widget>[
      tile(name: t.allProducts, meta: meta(null), onTap: () => context.go('/catalog/$categoryId?sub=all'),
          img: Container(alignment: Alignment.center, decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(12)),
              child: Text(t.allProducts, style: _t(14, FontWeight.w700, c.primary)))),
      for (final s in subs) () {
        final cover = Catalog.firstOf(categoryId, s.id)?.firstOrNull?.image ?? '';
        return tile(name: s.name, meta: meta(s.id), onTap: () => context.go('/catalog/$categoryId?sub=${s.id}'),
            img: cover.isEmpty ? const MartStripes(radius: 12) : MartImage(cover, radius: 12, fit: BoxFit.cover));
      }(),
    ];
    return Scaffold(
      body: Column(children: [
        MartTopPanel(children: [MartTitleRow(title: Catalog.category(categoryId)?.name ?? t.catalogTitle, onBack: () => context.go('/catalog'))]),
        Expanded(child: LayoutBuilder(builder: (context, cons) {
          final w = (cons.maxWidth - 32 - 8) / 2;
          return GridView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: (w - 12) * 3 / 4 + 6 + 8 + 38 + 2 + 16 + 12),
            children: tiles,
          );
        })),
      ]),
    );
  }
}

/// Список: назад · название · «N товаров»; чипсы Фильтры (счётчик) · сортировка ⌄ · подкатегории; активные фильтры — чипсы с ×.
class _CategoryView extends StatelessWidget {
  const _CategoryView({required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final cubit = context.watch<CatalogCubit>();
    final s = cubit.state;
    final subs = Catalog.subsOf(categoryId);
    final title = s.subId != null ? Catalog.subName(s.subId!) : (Catalog.category(categoryId)?.name ?? t.catalogTitle);
    final f = s.filter;
    final active = <(String, CatalogFilter)>[
      if (f.min != null) ('от ${money(f.min!)}', CatalogFilter(max: f.max, sale: f.sale)),
      if (f.max != null) ('до ${money(f.max!)}', CatalogFilter(min: f.min, sale: f.sale)),
      if (f.sale) (t.onlySale, CatalogFilter(min: f.min, max: f.max)),
    ];
    return Scaffold(
      body: Column(children: [
        MartTopPanel(padding: const EdgeInsets.fromLTRB(16, 8, 16, 10), gap: 8, children: [
          MartTitleRow(title: title, trailing: s.loading ? null : t.itemsCount(s.total), onBack: () => context.go(subs.isEmpty ? '/catalog' : '/catalog/$categoryId')),
          SizedBox(height: 44, child: ListView(
            scrollDirection: Axis.horizontal, clipBehavior: Clip.none,
            children: [
              MartActionChip(label: t.filters, count: active.length, onTap: () => openFiltersSheet(context, cubit)),
              const SizedBox(width: 8),
              MartActionChip(label: sortShort(t, s.sort), chevron: true, onTap: () => openSortSheet(context, cubit)),
              if (subs.isNotEmpty) ...[
                const SizedBox(width: 8),
                MartChip(label: t.chipAll, selected: s.subId == null, onTap: () => cubit.setSub(null)),
                for (final sc in subs) Padding(padding: const EdgeInsets.only(left: 8), child: MartChip(label: sc.name, selected: s.subId == sc.id, onTap: () => cubit.setSub(sc.id))),
              ],
            ],
          )),
        ]),
        Expanded(child: NotificationListener<ScrollNotification>(
          onNotification: (n) { if (n.metrics.extentAfter < 600) cubit.more(); return false; },
          child: RefreshIndicator(
            color: c.primary, onRefresh: cubit.load,
            child: CustomScrollView(slivers: [
              if (active.isNotEmpty) SliverPadding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), sliver: SliverToBoxAdapter(child: Wrap(spacing: 6, children: [
                for (final a in active) MartChip(label: a.$1, removable: true, onTap: () => cubit.setFilter(a.$2)),
              ]))),
              if (s.offline)
                SliverFillRemaining(hasScrollBody: false, child: MartEmptyState(icon: Icons.wifi_off_rounded, title: t.noInternet, text: t.noInternetHint, action: t.retry, onAction: cubit.load))
              else if (s.empty)
                SliverFillRemaining(hasScrollBody: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 64, 16, 16), child: Column(children: [
                  Text(t.nothingFound, style: _t(17, FontWeight.w700, c.ink1)),
                  const SizedBox(height: 8),
                  Text(t.nothingFoundHint, textAlign: TextAlign.center, style: _t(14, FontWeight.w400, c.ink2)),
                  if (active.isNotEmpty) ...[const SizedBox(height: 16), GestureDetector(
                    onTap: () => cubit.setFilter(const CatalogFilter()),
                    child: Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 18), alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(MartRadius.pill)),
                      child: Text(t.resetFilters, style: _t(15, FontWeight.w600, c.ink1))))],
                ])))
              else
                SliverPadding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), sliver: ProductGridSliver(items: s.items, loading: s.loading, loadingMore: s.loadingMore)),
              if (s.end) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text(t.endOfList, textAlign: TextAlign.center, style: _t(13, FontWeight.w400, c.ink3)))),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ]),
          ),
        )),
      ]),
    );
  }
}

/// «Сначала дешевле» → «Дешевле»; популярные — «Популярные».
String sortShort(L10n t, SortKind s) {
  final l = sortLabel(t, s);
  if (s == SortKind.popular) return 'Популярные';
  final r = l.replaceFirst('Сначала ', '');
  return r.isEmpty ? l : r[0].toUpperCase() + r.substring(1);
}

String sortLabel(L10n t, SortKind s) => switch (s) {
      SortKind.popular => t.sortPopular, SortKind.cheap => t.sortCheap, SortKind.expensive => t.sortExpensive, SortKind.sale => t.sortSale, SortKind.bonus => t.sortBonus,
    };

void openSortSheet(BuildContext context, CatalogCubit cubit) {
  final t = L10n.of(context);
  showMartSheet(context, title: t.sort, builder: (ctx) => Column(children: [
    for (final k in SortKind.values) if (k != SortKind.bonus || RemoteConfig.bonus) Padding(padding: const EdgeInsets.only(bottom: 8), child: MartRadioTile(
      selected: cubit.state.sort == k, title: sortLabel(t, k), onTap: () { cubit.setSort(k); Navigator.of(ctx).pop(); })),
  ]));
}

/// Фильтры: цена от–до + «со скидкой». Кнопка «Показать N» пересчитывается по мере ввода: счётчик — total выдачи с этими фильтрами.
void openFiltersSheet(BuildContext context, CatalogCubit cubit) {
  showMartSheet(context, title: L10n.of(context).filters, builder: (_) => _FiltersBody(cubit: cubit));
}

class _FiltersBody extends StatefulWidget {
  const _FiltersBody({required this.cubit});
  final CatalogCubit cubit;
  @override
  State<_FiltersBody> createState() => _FiltersBodyState();
}

class _FiltersBodyState extends State<_FiltersBody> {
  late var _f = widget.cubit.state.filter;
  late final _minC = TextEditingController(text: _f.min?.toString() ?? ''), _maxC = TextEditingController(text: _f.max?.toString() ?? '');
  /// Сколько товаров найдётся; пока считаем заново — на кнопке индикатор.
  late int _n = widget.cubit.state.total;
  bool _counting = false;
  Timer? _debounce;
  int _req = 0;

  @override
  void initState() { super.initState(); _count(wait: false); }
  @override
  void dispose() { _debounce?.cancel(); _minC.dispose(); _maxC.dispose(); super.dispose(); }

  CatalogFilter _read() => CatalogFilter(min: int.tryParse(_minC.text), max: int.tryParse(_maxC.text), sale: _f.sale);

  /// Мок отвечает сразу; с бэкендом ждём паузу в наборе, устаревший ответ отбрасываем.
  void _count({bool wait = true}) {
    _debounce?.cancel();
    final req = ++_req;
    Future<void> run() async {
      try {
        final n = await widget.cubit.countWith(_read());
        if (mounted && req == _req) setState(() { _n = n; _counting = false; });
      } on CatalogOffline {
        if (mounted && req == _req) setState(() => _counting = false);
      }
    }
    if (Catalog.mocked || !wait) { run(); return; }
    setState(() => _counting = true);
    _debounce = Timer(const Duration(milliseconds: 300), run);
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final cubit = widget.cubit;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: MartInput(label: t.priceFrom, type: MartInputType.number, controller: _minC, onChanged: (_) => _count())),
        const SizedBox(width: 8),
        Expanded(child: MartInput(label: t.priceTo, type: MartInputType.number, controller: _maxC, onChanged: (_) => _count())),
      ]),
      const SizedBox(height: 12),
      Wrap(children: [MartChip(label: t.onlySale, selected: _f.sale, onTap: () { setState(() => _f = CatalogFilter(min: _f.min, max: _f.max, sale: !_f.sale)); _count(wait: false); })]),
      const SizedBox(height: 20),
      MartButton(label: t.showN(_n), expanded: true, loading: _counting, disabledReason: _n == 0 && !_counting ? t.nothingFound : null,
          onPressed: () { cubit.setFilter(_read()); Navigator.of(context).pop(); }),
      const SizedBox(height: 8),
      MartButton(label: t.reset, variant: MartButtonVariant.ghost, expanded: true, onPressed: () { cubit.setFilter(const CatalogFilter()); Navigator.of(context).pop(); }),
    ]);
  }
}

