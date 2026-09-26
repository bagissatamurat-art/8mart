// Скриншоты экранов 390×844 для сверки с макетами. Запуск: flutter test --update-goldens test_shots
// CI кладёт PNG в ветку ci-report/shots — оттуда их смотрит дизайнер (Claude) и сравнивает с артбордами 390.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:mart8/app.dart';
import 'package:mart8/ui/widgets/mart_image.dart';

class _MemStorage implements Storage {
  final _m = <String, dynamic>{};
  @override
  dynamic read(String key) => _m[key];
  @override
  Future<void> write(String key, dynamic value) async => _m[key] = value;
  @override
  Future<void> delete(String key) async => _m.remove(key);
  @override
  Future<void> clear() async => _m.clear();
  @override
  Future<void> close() async {}
}

Future<void> _font(String family, String path) async {
  final f = File(path);
  if (!f.existsSync()) return;
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  await loader.load();
}

const shots = {
  '01-home': '/',
  '02-catalog': '/catalog',
  '03-category': '/catalog/stroymaterialy',
  '04-list': '/catalog/stroymaterialy?sub=all',
  '05-flowers': '/catalog/tsvety?sub=all',
  '06-cart': '/cart',
  '07-checkout-auth': '/checkout',
  '08-search': '/search',
  '09-search-results': '/search?q=цемент',
  '10-product': '/p/b1',
  '11-product-flowers': '/p/f1',
  '12-profile': '/profile',
};

void main() {
  setUpAll(() async {
    HydratedBloc.storage = _MemStorage();
    MartImage.offline = true;
    await _font('Onest', 'assets/fonts/Onest-Variable.ttf');
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) await _font('MaterialIcons', '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  });

  for (final e in shots.entries) {
    testWidgets(e.key, timeout: const Timeout(Duration(seconds: 60)), (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MartApp(key: ValueKey(e.key), initialLocation: e.value));
      await tester.pump(const Duration(milliseconds: 100));
      // Картинки из assets декодируются вне fake-async.
      await tester.runAsync(() async {
        for (final el in find.byType(Image).evaluate()) {
          final img = (el.widget as Image).image;
          if (img is! AssetImage) continue;
          await precacheImage(img, el).timeout(const Duration(seconds: 3), onTimeout: () {}).catchError((_) {});
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
      await expectLater(find.byType(MartApp), matchesGoldenFile('goldens/${e.key}.png'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
