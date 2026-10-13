import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MapboxOptions;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/env.dart';
import 'data/auth_repository.dart';
import 'data/catalog.dart';
import 'data/places.dart';
import 'data/remote_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mapbox: публичный токен pk.* из --dart-define(-from-file). Без него карта не загрузится.
  if (Env.mapboxToken.isNotEmpty) MapboxOptions.setAccessToken(Env.mapboxToken);
  // Корзина, способ получения, избранное и настройки переживают перезапуск и работают офлайн.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb ? HydratedStorage.webStorageDirectory : await getApplicationDocumentsDirectory(),
  );
  // С бэкендом: сохранённые категории, карточки корзины/избранного и филиалы — до первого кадра (на моке — ничего не делает).
  Catalog.restore();
  Places.restore();
  RemoteConfig.restore();
  // Вход с прошлого запуска (Keychain / Keystore): приложение открывается уже в аккаунте.
  await AuthSession.restore();
  // Свежий каталог и филиалы — сразу, с какого бы экрана ни открылось приложение (сплэш или ссылка на товар).
  unawaited(Catalog.init());
  unawaited(Places.refresh());
  unawaited(RemoteConfig.refresh());
  // TODO: await Firebase.initializeApp(); FirebaseMessaging.onMessageOpenedApp → router.go('/order/<id>')
  runApp(const MartApp());
}
