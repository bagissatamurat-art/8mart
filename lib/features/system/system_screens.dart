import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/catalog.dart';
import '../../data/places.dart';
import '../../data/remote_config.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/ui.dart';

/// Мок конфигурации: в проде — GET /app/config {minVersion, storeUrl}. Сравнить с package_info_plus.
abstract final class AppConfig {
  static bool forceUpdate = false;
  static const storeUrlIos = 'https://apps.apple.com/app/id0000000000';
  static const storeUrlAndroid = 'https://play.google.com/store/apps/details?id=kz.mart8.mart8';
}

/// Сплэш (после нативного launch screen): логотип, прогрев кеша, проверка версии.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Сколько сплэш ждёт каталог с бэкенда; не успел — главная покажет скелетоны и догрузит сама.
  static const _warmUpLimit = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _warmUp();
  }

  /// Прогрев: категории, первые страницы разделов, товары корзины и избранного, филиалы (загрузка начата в main).
  /// На моке — только пауза 700 мс, как раньше.
  Future<void> _warmUp() async {
    await Future.wait<void>([
      Future<void>.delayed(const Duration(milliseconds: 700)),
      Future.wait<void>([Catalog.init(), Places.refresh(), RemoteConfig.refresh()]).timeout(_warmUpLimit, onTimeout: () => const []),
    ]);
    if (mounted) context.go(AppConfig.forceUpdate ? '/update' : '/');
  }
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(body: Center(child: SvgPicture.asset('assets/images/logo.svg', package: MartAssets.package, height: 40,
        colorFilter: dark ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null)));
  }
}

/// Обязательное обновление: закрыть нельзя, только «Обновить».
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    return PopScope(canPop: false, child: Scaffold(
      body: SafeArea(child: MartEmptyState(icon: Icons.system_update_rounded, title: t.updateTitle, text: t.updateText)),
      bottomNavigationBar: MartBottomBar(child: MartButton(label: t.update, expanded: true,
          onPressed: () => launchUrl(Uri.parse(ios ? RemoteConfig.appStoreUrl ?? AppConfig.storeUrlIos : RemoteConfig.googlePlayUrl ?? AppConfig.storeUrlAndroid), mode: LaunchMode.externalApplication))),
    ));
  }
}
