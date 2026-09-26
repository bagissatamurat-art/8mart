import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../data/mock_data.dart';
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
    return Scaffold(
      body: Column(children: [
        MartTopPanel(children: [
          Text(t.catalogTitle, style: _t(24, FontWeight.w800, c.ink1).copyWith(letterSpacing: -0.48)),
          MartSearchPill(hint: t.findProduct, onTap: () => context.push('/search')),
        ]),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: MockData.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final cat = MockData.categories[i];
            final subs = MockData.subsOf(cat.id).length;
            final n = MockData.products.where((p) => p.categoryId == cat.id).length;
            final meta = [if (subs > 0) t.sectionsCount(subs), t.itemsCount(n)].join(' · ');
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
    );
  }
}

/// /catalog/:cat — без ?sub и есть подкатегории → плитки; ?sub=all|<id> или подкатегорий нет → список.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.categoryId, this.subId});
  final String categoryId;
  final String? subId;
  @override
  Widget build(BuildContext context) {
    final subs = MockData.subsOf(categoryId);
    if (subId == null && subs.isNotEmpty) return _SubTiles(categoryId: categoryId, subs: subs);
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
    final inCat = MockData.products.where((p) => p.categoryId == categoryId).toList();
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
      tile(name: t.allProducts, meta: t.itemsCount(inCat.length), onTap: () => context.go('/catalog/$categoryId?sub=all'),
          img: Container(alignment: Alignment.center, decoration: BoxDecoration(color: c.primary50, borderRadius: BorderRadius.circular(12)),
              child: Text(t.allProducts, style: _t(14, FontWeight.w700, c.primary)))),
      for (final s in subs) () {
        final items = inCat.where((p) => p.subId == s.id).toList();
        return tile(name: s.name, meta: t.itemsCount(items.length), onTap: () => context.go('/catalog/$categoryId?sub=${s.id}'),
            img: items.isEmpty ? const MartStripes(radius: 12) : MartImage(items.first.image, radius: 12, fit: BoxFit.cover));
      }(),
    ];
    return Scaffold(
      body: Column(children: [
        MartTopPanel(children: [MartTitleRow(title: MockData.category(categoryId)?.name ?? t.catalogTitle, onBack: () => context.go('/catalog'))]),
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
    final subs = MockData.subsOf(categoryId);
    final title = s.subId != null ? MockData.subName(s.subId!) : (MockData.category(categoryId)?.name ?? t.catalogTitle);
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
    for (final k in SortKind.values) Padding(padding: const EdgeInsets.only(bottom: 8), child: MartRadioTile(
      selected: cubit.state.sort == k, title: sortLabel(t, k), onTap: () { cubit.setSort(k); Navigator.of(ctx).pop(); })),
  ]));
}

/// Фильтры: цена от–до + «со скидкой». Кнопка «Показать N» пересчитывается сразу (в проде — GET /products/count).
void openFiltersSheet(BuildContext context, CatalogCubit cubit) {
  final t = L10n.of(context);
  var f = cubit.state.filter;
  final minC = TextEditingController(text: f.min?.toString() ?? ''), maxC = TextEditingController(text: f.max?.toString() ?? '');
  showMartSheet(context, title: t.filters, builder: (ctx) => StatefulBuilder(builder: (ctx, set) {
    CatalogFilter read() => CatalogFilter(min: int.tryParse(minC.text), max: int.tryParse(maxC.text), sale: f.sale);
    final n = cubit.countWith(read());
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: MartInput(label: t.priceFrom, type: MartInputType.number, controller: minC, onChanged: (_) => set(() {}))),
        const SizedBox(width: 8),
        Expanded(child: MartInput(label: t.priceTo, type: MartInputType.number, controller: maxC, onChanged: (_) => set(() {}))),
      ]),
      const SizedBox(height: 12),
      Wrap(children: [MartChip(label: t.onlySale, selected: f.sale, onTap: () => set(() => f = CatalogFilter(min: f.min, max: f.max, sale: !f.sale)))]),
      const SizedBox(height: 20),
      MartButton(label: t.showN(n), expanded: true, disabledReason: n == 0 ? t.nothingFound : null, onPressed: () { cubit.setFilter(read()); Navigator.of(ctx).pop(); }),
      const SizedBox(height: 8),
      MartButton(label: t.reset, variant: MartButtonVariant.ghost, expanded: true, onPressed: () { cubit.setFilter(const CatalogFilter()); Navigator.of(ctx).pop(); }),
    ]);
  }));
}

