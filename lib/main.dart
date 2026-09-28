import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MapboxOptions;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mapbox: публичный токен pk.* из --dart-define(-from-file). Без него карта не загрузится.
  if (Env.mapboxToken.isNotEmpty) MapboxOptions.setAccessToken(Env.mapboxToken);
  // Корзина, способ получения, избранное и настройки переживают перезапуск и работают офлайн.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb ? HydratedStorage.webStorageDirectory : await getApplicationDocumentsDirectory(),
  );
  // TODO: await Firebase.initializeApp(); FirebaseMessaging.onMessageOpenedApp → router.go('/order/<id>')
  runApp(const MartApp());
}
