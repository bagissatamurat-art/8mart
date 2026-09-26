import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'features/cart/cart_screen.dart';
import 'features/catalog/catalog_screen.dart';
import 'features/checkout/checkout_screen.dart';
import 'features/home/home_screen.dart';
import 'features/order/order_status_screen.dart';
import 'features/product/product_view.dart';
import 'features/profile/account_sections.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/search/search_screen.dart';
import 'features/system/system_screens.dart';
import 'l10n/gen/app_localizations.dart';
import 'state/auth_cubit.dart';
import 'state/cart_cubit.dart';
import 'ui/ui.dart';

/// Пути = deep links (Universal Links / App Links на 8mart.kz):
/// /catalog/:cat?sub= категория · /search?q= поиск · /profile/:section раздел кабинета ·
/// /p/:id товар · /order/:id статус · /auth/tg?token=&phone= возврат из Telegram-бота · /pay/return?order= возврат из Kaspi.
GoRouter buildRouter({String initialLocation = '/splash'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/catalog', builder: (_, __) => const CatalogRootScreen(), routes: [
              GoRoute(path: ':cat', builder: (_, s) => CategoryScreen(key: ValueKey(s.uri.toString()), categoryId: s.pathParameters['cat']!, subId: s.uri.queryParameters['sub'])),
            ])]),
            StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, __) => const CartScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen(), routes: [
              GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen(), routes: [
                GoRoute(path: 'notifications', builder: (_, __) => const NotificationSettingsScreen()),
                GoRoute(path: 'documents', builder: (_, __) => const DocumentsScreen()),
              ]),
              GoRoute(path: ':section', builder: (_, s) => AccountSectionScreen(section: AccountSection.values.byName(s.pathParameters['section']!))),
            ])]),
          ],
        ),
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/update', builder: (_, __) => const ForceUpdateScreen()),
        GoRoute(path: '/search', builder: (_, s) => SearchScreen(initial: s.uri.queryParameters['q'])),
        GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
        GoRoute(path: '/order/:id', builder: (_, s) => OrderStatusScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/pay/return', redirect: (_, s) => '/order/${s.uri.queryParameters['order'] ?? ''}'),
        GoRoute(path: '/p/:id', builder: (_, s) => ProductPage(id: s.pathParameters['id']!)),
        GoRoute(
          path: '/auth/tg',
          redirect: (context, s) {
            context.read<AuthCubit>().telegramConfirmed(s.uri.queryParameters['token'] ?? '', s.uri.queryParameters['phone'] ?? '');
            return '/checkout';
          },
        ),
      ],
    );

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final count = context.select<CartCubit, int>((c) => c.state.count);
    return Scaffold(
      body: shell,
      bottomNavigationBar: MartTabBar(
        index: shell.currentIndex, cartCount: count,
        onTap: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          MartTabItem(t.tabHome, MartTabGlyph.home),
          MartTabItem(t.tabCatalog, MartTabGlyph.catalog),
          MartTabItem(t.tabCart, MartTabGlyph.cart),
          MartTabItem(t.tabProfile, MartTabGlyph.profile),
        ],
      ),
    );
  }
}
