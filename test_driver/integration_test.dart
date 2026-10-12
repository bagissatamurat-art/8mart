import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Сохраняет кадры из integration_test/store_screenshots_test.dart в design/store/raw.
Future<void> main() => integrationDriver(onScreenshot: (name, bytes, [args]) async {
      final f = File('design/store/raw/$name.png');
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes);
      return true;
    });
