import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_data.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';
import '../common/product_grid.dart';
import '../method/method_sheet.dart';

/// Главная 390 (01 Главная и каталог.dc.html #1b):
/// шапка (логотип · способ получения · поиск) → чипсы категорий → баннер 140 → «Выгодная полка» 2 в ряд.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.offline = false});
  final bool offline;

  /// «Астана, Кабанбай батыра, 11» → «Кабанбай батыра, 11» (город виден в модалке).
  static String shortAddress(String a) {
    final i = a.indexOf(', ');
    return i > 0 ? a.substring(i + 2) : a;
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final c = context.mc;
    final cart = context.watch<CartCubit>().state;
    final deals = MockData.products.where((p) => p.oldPrice != null).toList();

    return Scaffold(
      body: RefreshIndicator(
        color: c.primary,
        onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 600)),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: MartHomeHeader(
            methodChosen: cart.method != null,
            methodText: cart.method == null ? t.howToGet : shortAddress(cart.address),
            onMethod: () => openMethodSheet(context),
            searchHint: t.searchHint, onSearch: () => context.push('/search'),
          )),
          if (offline) SliverPadding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), sliver: SliverToBoxAdapter(child: OfflineBanner(text: t.offline))),
          SliverToBoxAdapter(child: SizedBox(height: 44, child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
            children: [
              MartChip(label: t.chipAll, selected: true, onTap: () => context.go('/catalog')),
              for (final cat in MockData.categories) Padding(padding: const EdgeInsets.only(left: 8), child: MartChip(label: cat.name, onTap: () => context.go('/catalog/${cat.id}'))),
            ],
          ))).withTopGap(12),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: SizedBox(height: 140, child: MartStripes(a: c.primary100, b: c.primary50, step: 12, radius: MartRadius.card, label: '${t.banner} · 358×140'))),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            sliver: SliverToBoxAdapter(child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Expanded(child: Text(t.dealsShelf, style: TextStyle(fontFamily: 'Onest', fontSize: 20, fontWeight: FontWeight.w700, color: c.ink1))),
              GestureDetector(
                behavior: HitTestBehavior.opaque, onTap: () => context.go('/catalog'),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(t.seeAll, style: TextStyle(fontFamily: 'Onest', fontSize: 14, fontWeight: FontWeight.w600, color: c.primary)),
                  const SizedBox(width: 4),
                  MartChevron(color: c.primary, size: 6),
                ])),
              ),
            ])),
          ),
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), sliver: ProductGridSliver(items: deals)),
        ]),
      ),
    );
  }
}

extension on Widget {
  Widget withTopGap(double h) => SliverPadding(padding: EdgeInsets.only(top: h), sliver: this);
}
