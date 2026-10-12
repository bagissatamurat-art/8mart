// Скриншоты для App Store / Google Play — настоящие экраны с фото букетов (сеть), на симуляторе:
//   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/store_screenshots_test.dart \
//     -d <симулятор> --dart-define-from-file=env.json
// Кадры пишутся в design/store/raw/*.png (сырые экраны); подписи и фон — design/store/build.mjs.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' show MapboxOptions;
import 'package:mart8/app.dart';
import 'package:mart8/core/env.dart';
import 'package:mart8/domain/models.dart';
import 'package:mart8/features/method/method_sheet.dart';
import 'package:mart8/state/account_cubit.dart';
import 'package:mart8/state/auth_cubit.dart';
import 'package:mart8/state/cart_cubit.dart';
import 'package:mart8/state/order_cubit.dart';

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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store screenshots', (tester) async {
    HydratedBloc.storage = _MemStorage();
    if (Env.mapboxToken.isNotEmpty) MapboxOptions.setAccessToken(Env.mapboxToken);
    await tester.pumpWidget(const MartApp(initialLocation: '/'));

    /// Ждём реальное время (фото из сети, карта), прокачивая кадры.
    Future<void> settle([int ms = 3500]) async {
      for (var t = 0; t < ms; t += 100) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    }
    BuildContext ctx() => tester.element(find.byType(Scaffold).last);
    Future<void> go(String path) async { GoRouter.of(ctx()).go(path); await settle(); }
    Future<void> shot(String name) async { await binding.takeScreenshot(name); }

    // Корзина с букетами, доставка, вход (мок-код 1234).
    final c = ctx();
    final cart = c.read<CartCubit>();
    cart.clearCart();
    cart.setMethod(ReceiveMethod.delivery, 'Астана, Кабанбай батыра, 11',
        quote: const DeliveryQuote(fee: 2000, eta: 30, branchName: 'ROMANTIC, Мангилик Ел 45', zone: 'Зона 1'));
    // Сумма ниже порога бесплатной доставки (порог ещё не подтверждён бизнесом) — видна обычная цена доставки.
    cart.setQty('f5-s', 1);
    cart.setQty('f3-s', 1);
    final auth = c.read<AuthCubit>();
    await auth.sendCode('+7 (700) 133-90-71');
    await auth.verify('1234');
    c.read<AccountCubit>().load();
    await settle(5000);

    await go('/');
    await shot('01-home');

    await go('/p/f1');
    await settle(2000);
    await shot('02-product');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -330));
    await settle(1200);
    await shot('03-sizes');

    await go('/');
    openMethodSheet(ctx());
    await settle(6000);
    await shot('04-method');
    Navigator.of(ctx(), rootNavigator: true).pop();
    await settle(800);

    await go('/checkout');
    await shot('05-checkout');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -470));
    await settle(1200);
    await shot('06-delivery-time');

    final cs = ctx().read<CartCubit>().state;
    ctx().read<OrderCubit>().create(id: '8M-10482', plan: cs.plan(goodsTotal: cs.afterDiscount), method: ReceiveMethod.delivery,
        total: cs.afterDiscount + 2000, bonus: cs.bonus, lines: cs.active.toList(), address: cs.address, paidWith: 'Оплачено Kaspi',
        goods: cs.goods, recipientPhone: '+7 (700) 133-90-71');
    await go('/order/8M-10482');
    // Карточку «Сообщать о статусе?» закрываем — на скриншоте статус заказа.
    if (find.text('Не сейчас').evaluate().isNotEmpty) { await tester.tap(find.text('Не сейчас')); await settle(800); }
    await shot('07-order');

    await go('/profile/bonus');
    await shot('08-bonus');
  });
}
