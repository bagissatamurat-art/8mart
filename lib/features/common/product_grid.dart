import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../state/cart_cubit.dart';
import '../../ui/ui.dart';
import '../../state/favorites_cubit.dart';
import '../method/method_sheet.dart';
import '../product/product_view.dart';

/// Добавление в корзину с общими правилами: нет способа получения → шторка выбора; первое добавление → тост.
void setCartQty(BuildContext context, Product p, int q) {
  final t = L10n.of(context);
  final cart = context.read<CartCubit>();
  final prev = cart.state.qtyOf(p.id);
  if (!cart.setQty(p.id, q)) { openMethodSheet(context); return; }
  if (prev == 0 && q > 0) showMartToast(context, t.addedToCart, action: t.open, onAction: () => context.go('/cart'));
}

/// Сетка карточек 2 в ряд (sliver). loading → скелетоны, loadingMore → 2 скелетона снизу.
class ProductGridSliver extends StatelessWidget {
  const ProductGridSliver({super.key, required this.items, this.loading = false, this.loadingMore = false});
  final List<Product> items;
  final bool loading, loadingMore;
  static SliverGridDelegate delegateFor(double cross) =>
      SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: MartProductCard.extentFor((cross - 8) / 2));

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(builder: (context, cons) => _grid(context, delegateFor(cons.crossAxisExtent)));

  Widget _grid(BuildContext context, SliverGridDelegate delegate) {
    final t = L10n.of(context);
    if (loading) return SliverGrid(gridDelegate: delegate, delegate: SliverChildBuilderDelegate((_, __) => const MartSkeletonCard(), childCount: 4));
    final cart = context.watch<CartCubit>().state;
    final favs = context.watch<FavoritesCubit>().state;
    return SliverGrid(
      gridDelegate: delegate,
      delegate: SliverChildBuilderDelegate(childCount: items.length + (loadingMore ? 2 : 0), (context, i) {
        if (i >= items.length) return const MartSkeletonCard();
        final p = items[i];
        return MartProductCard(
          product: p, qty: cart.qtyOf(p.id), addLabel: t.toCart, favorite: favs.contains(p.id),
          onFavorite: () => context.read<FavoritesCubit>().toggle(p.id),
          onQty: (q) => setCartQty(context, p, q), onTap: () => openProductSheet(context, p),
        );
      }),
    );
  }
}
