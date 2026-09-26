import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'l10n/gen/app_localizations.dart';
import 'router.dart';
import 'state/account_cubit.dart';
import 'state/auth_cubit.dart';
import 'state/cart_cubit.dart';
import 'state/checkout_cubit.dart';
import 'state/favorites_cubit.dart';
import 'state/order_cubit.dart';
import 'state/search_history_cubit.dart';
import 'state/settings_cubit.dart';
import 'ui/ui.dart';

class MartApp extends StatefulWidget {
  const MartApp({super.key, this.initialLocation = '/splash'});
  /// Для скриншот-тестов: открыть сразу нужный экран.
  final String initialLocation;
  @override
  State<MartApp> createState() => _MartAppState();
}

class _MartAppState extends State<MartApp> {
  late final _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => FavoritesCubit()),
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => CheckoutCubit()),
        BlocProvider(create: (_) => OrderCubit()),
        BlocProvider(create: (_) => AccountCubit()),
        BlocProvider(create: (_) => SearchHistoryCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, s) => MaterialApp.router(
          title: '8mart',
          debugShowCheckedModeBanner: false,
          theme: buildMartTheme(Brightness.light),
          darkTheme: buildMartTheme(Brightness.dark),
          themeMode: s.themeMode,
          locale: Locale(s.lang),
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: L10n.localizationsDelegates,
          routerConfig: _router,
        ),
      ),
    );
  }
}
