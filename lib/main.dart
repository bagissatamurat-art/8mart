import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Корзина, способ получения, избранное и настройки переживают перезапуск и работают офлайн.
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb ? HydratedStorage.webStorageDirectory : await getApplicationDocumentsDirectory(),
  );
  // TODO: await Firebase.initializeApp(); FirebaseMessaging.onMessageOpenedApp → router.go('/order/<id>')
  runApp(const MartApp());
}
