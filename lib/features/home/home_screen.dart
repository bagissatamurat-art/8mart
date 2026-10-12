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
/// шапка (логотип · способ получения · поиск) → чипсы категорий → баннер 140 → полки цветов по подкатегориям, 2 в ряд (как на сайте).
/// Основная категория главной — цветы.
const _mainCategory = 'tsvety';

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
            sliver: SliverToBoxAdapter(child: MartBanner(image: 'assets/images/banner-flowers.jpg', title: t.homeBannerTitle, text: t.homeBannerText,
                onTap: () => context.go('/catalog/tsvety'))),
          ),
          // Полки — подкатегории цветов (основной товар): «Гортензии», «Розы», «Хризантемы», по 4 букета.
          for (final sub in MockData.subsOf(_mainCategory)) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              sliver: SliverToBoxAdapter(child: _ShelfHead(title: sub.name, all: t.seeAll, onAll: () => context.go('/catalog/$_mainCategory?sub=${sub.id}'))),
            ),
            SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: ProductGridSliver(items: MockData.products.where((p) => p.subId == sub.id).take(4).toList())),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }
}

/// Заголовок полки: название · «Все →».
class _ShelfHead extends StatelessWidget {
  const _ShelfHead({required this.title, required this.all, required this.onAll});
  final String title, all;
  final VoidCallback onAll;
  @override
  Widget build(BuildContext context) {
    final c = context.mc;
    return Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
      Expanded(child: Text(title, style: TextStyle(fontFamily: 'Onest', fontSize: 20, fontWeight: FontWeight.w700, color: c.ink1))),
      GestureDetector(
        behavior: HitTestBehavior.opaque, onTap: onAll,
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(all, style: TextStyle(fontFamily: 'Onest', fontSize: 14, fontWeight: FontWeight.w600, color: c.primary)),
          const SizedBox(width: 4),
          MartChevron(color: c.primary, size: 6),
        ])),
      ),
    ]);
  }
}

extension on Widget {
  Widget withTopGap(double h) => SliverPadding(padding: EdgeInsets.only(top: h), sliver: this);
}
