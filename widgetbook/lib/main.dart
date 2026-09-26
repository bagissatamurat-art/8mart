import 'package:flutter/material.dart';
import 'package:mart8/data/demo.dart';
import 'package:mart8/data/mock_data.dart';
import 'package:mart8/l10n/gen/app_localizations.dart';
import 'package:mart8/ui/ui.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  MartAssets.package = 'mart8';
  runApp(const Gallery());
}

/// Запуск: cd widgetbook && flutter run -d chrome (или macos). Ассеты и шрифт берутся из пакета mart8.
class Gallery extends StatelessWidget {
  const Gallery({super.key});

  @override
  Widget build(BuildContext context) {
    Widget pad(Widget w) => Center(child: Padding(padding: const EdgeInsets.all(16), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 390), child: w)));
    UseCase uc(String name, Widget Function(BuildContext) b) => WidgetbookUseCase(name: name, builder: (c) => pad(b(c)));
    final p = MockData.products.first;
    return Widgetbook.material(
      addons: [
        MaterialThemeAddon(themes: [
          WidgetbookTheme(name: 'Светлая', data: buildMartTheme(Brightness.light)),
          WidgetbookTheme(name: 'Тёмная', data: buildMartTheme(Brightness.dark)),
        ]),
        LocalizationAddon(locales: L10n.supportedLocales, localizationsDelegates: L10n.localizationsDelegates),
        ViewportAddon([IosViewports.iPhone13, AndroidViewports.samsungGalaxyS20]),
        TextScaleAddon(min: 1, max: 2),
      ],
      directories: [
        WidgetbookFolder(name: 'Base', children: [
          WidgetbookComponent(name: 'MartButton', useCases: [
            uc('Playground', (c) => MartButton(
              label: c.knobs.string(label: 'label', initialValue: 'Оформить'),
              amount: c.knobs.stringOrNull(label: 'amount', initialValue: '24 070 тг.'),
              variant: c.knobs.list(label: 'variant', options: MartButtonVariant.values, labelBuilder: (v) => v.name),
              size: c.knobs.list(label: 'size', options: MartButtonSize.values.reversed.toList(), labelBuilder: (v) => v.name),
              loading: c.knobs.boolean(label: 'loading'),
              expanded: c.knobs.boolean(label: 'expanded', initialValue: true),
              disabledReason: c.knobs.boolean(label: 'disabled') ? 'Примите условия оферты' : null,
              onPressed: () {},
            )),
            uc('Kaspi Pay', (c) => KaspiPayButton(onPressed: () {}, loading: c.knobs.boolean(label: 'loading'))),
          ]),
          WidgetbookComponent(name: 'MartInput', useCases: [
            uc('Text', (c) => MartInput(label: 'Имя', required: c.knobs.boolean(label: 'required', initialValue: true),
                error: c.knobs.boolean(label: 'error') ? 'Обязательное поле' : null, enabled: !c.knobs.boolean(label: 'disabled'))),
            uc('Phone', (c) => const MartInput(label: 'Телефон', type: MartInputType.phone, required: true)),
            uc('Multiline', (c) => const MartInput(label: 'Комментарий', type: MartInputType.multiline)),
          ]),
          WidgetbookComponent(name: 'MartCodeInput', useCases: [
            uc('States', (c) => MartCodeInput(autofocus: false, onCompleted: (_) {},
                state: c.knobs.list(label: 'state', options: CodeState.values, labelBuilder: (v) => v.name))),
            uc('Paste hint', (c) => PasteCodeHint(label: 'Скопировали код?', action: 'Вставить', onCode: (_) {})),
          ]),
          WidgetbookComponent(name: 'MartChip', useCases: [
            uc('Playground', (c) => Wrap(spacing: 8, children: [
              MartChip(label: 'Розы', selected: c.knobs.boolean(label: 'selected', initialValue: true), onTap: () {}),
              const MartChip(label: 'Гортензии', count: 12),
              const MartChip(label: 'от 5 000 тг', removable: true),
              const MartChip(label: 'Нет в наличии', enabled: false),
            ])),
          ]),
          WidgetbookComponent(name: 'MartStepper', useCases: [uc('Default', (c) => MartStepper(qty: c.knobs.int.slider(label: 'qty', initialValue: 2, min: 0, max: 10), onChanged: (_) {}))]),
          WidgetbookComponent(name: 'MartSearchField', useCases: [uc('Default', (c) => const MartSearchField(hint: 'Искать в 8mart'))]),
          WidgetbookComponent(name: 'MartListRow', useCases: [uc('Default', (c) => const MartListRow(title: 'Бонусы', value: '1240', onTap: _noop))]),
          WidgetbookComponent(name: 'MartSkeleton', useCases: [
            uc('Card', (c) => const SizedBox(width: 175, height: 352, child: MartSkeletonCard())),
            uc('Row', (c) => const MartSkeletonRow()),
          ]),
          WidgetbookComponent(name: 'MartEmptyState', useCases: [
            uc('Nothing found', (c) => const MartEmptyState(title: 'Ничего не нашли', text: 'Ослабьте фильтры или поищите иначе', action: 'Сбросить', onAction: _noop)),
            uc('Offline', (c) => const MartEmptyState(icon: Icons.wifi_off_rounded, title: 'Нет интернета', text: 'Каталог появится, как только сеть вернётся', action: 'Повторить попытку', onAction: _noop)),
            uc('Empty cart', (c) => const MartEmptyState(image: 'assets/images/empty-cart.png', title: 'В корзине пусто', action: 'В каталог', onAction: _noop)),
          ]),
          WidgetbookComponent(name: 'BonusBadge', useCases: [uc('Default', (c) => const Row(mainAxisSize: MainAxisSize.min, children: [BonusBadge(amount: 87), SizedBox(width: 8), BonusBadge(amount: 87, compact: true)]))]),
        ]),
        WidgetbookFolder(name: 'Commerce', children: [
          WidgetbookComponent(name: 'MartProductCard', useCases: [
            uc('Default', (c) => SizedBox(width: 175, height: 352, child: MartProductCard(product: p, addLabel: 'В корзину', onQty: (_) {},
                qty: c.knobs.int.slider(label: 'qty', initialValue: 0, min: 0, max: 5), favorite: c.knobs.boolean(label: 'favorite'), soldOut: c.knobs.boolean(label: 'soldOut')))),
          ]),
          WidgetbookComponent(name: 'MartCartLine', useCases: [
            uc('Default', (c) => MartCartLine(line: CartLineX.demo(soldOut: c.knobs.boolean(label: 'soldOut')), onQty: (_) {}, soldOutLabel: 'Раскупили', notCountedLabel: 'не учитывается', notInStockLabel: 'Нет в наличии в вашем филиале',
                removeLabel: 'Удалить из корзины', perPieceLabel: 'за шт', bonusText: (n) => '+$n бонусов')),
          ]),
          WidgetbookComponent(name: 'ShipmentHead', useCases: [
            uc('Courier', (c) => const ShipmentHead(tag: 'Курьер', cargo: false, label: 'Доставка 1 из 2', when: 'Сегодня, за 60–90 минут', meta: 'Курьер · 2 товара', feeText: '1 000 тг.')),
            uc('Cargo', (c) => const ShipmentHead(tag: 'Газель', cargo: true, label: 'Доставка 2 из 2', when: 'Завтра, 9:00–21:00', meta: 'Газель · 125 кг', feeText: '3 000 тг.')),
          ]),
          WidgetbookComponent(name: 'SplitChoice', useCases: [
            uc('Default', (c) => SplitChoice(title: 'Как привезти заказ', sub: 'Тяжёлые товары возим Газелью — только на следующий день',
                together: c.knobs.boolean(label: 'together'), onChanged: (_) {}, options: const [
                  SplitOption(together: false, title: 'Двумя доставками', sub: 'Сегодня курьером + завтра Газелью', feeText: '1 000 + 3 000 тг.'),
                  SplitOption(together: true, title: 'Всё вместе завтра', sub: 'Одной Газелью, 9:00–21:00', feeText: '3 000 тг.'),
                ])),
          ]),
          WidgetbookComponent(name: 'PaymentPicker', useCases: [
            uc('Logged in', (c) => PaymentPicker(
              value: c.knobs.list(label: 'value', options: const ['kaspi', 'c1', 'c2', 'new']), cards: MockData.cards, onChanged: (_) {},
              labels: const PaymentLabels(kaspiSub: 'Оплата в приложении Kaspi', cardOnline: 'Картой онлайн', savedCards: 'Сохранённые карты', newCard: 'Новой картой', newCardSub: 'На защищённой странице банка'))),
          ]),
          WidgetbookComponent(name: 'OrderTimeline', useCases: [
            uc('Courier', (c) => OrderTimeline(current: c.knobs.int.slider(label: 'current', initialValue: 1, min: 0, max: 3), cancelled: c.knobs.boolean(label: 'cancelled'), stages: const [
              TimelineStage('Заказ принят', time: '14:05'), TimelineStage('Собираем заказ', sub: 'Проверяем наличие и упаковываем', time: '14:07'),
              TimelineStage('Курьер в пути', sub: 'Позвоним за 10–15 минут'), TimelineStage('Доставлен'),
            ])),
          ]),
        ]),
        WidgetbookFolder(name: 'Navigation', children: [
          WidgetbookComponent(name: 'MartTabBar', useCases: [
            uc('Default', (c) => MartTabBar(index: 0, cartCount: c.knobs.int.slider(label: 'cart', initialValue: 3, min: 0, max: 20), onTap: (_) {}, items: const [
              MartTabItem('Главная', MartTabGlyph.home), MartTabItem('Каталог', MartTabGlyph.catalog),
              MartTabItem('Корзина', MartTabGlyph.cart), MartTabItem('Профиль', MartTabGlyph.profile),
            ])),
          ]),
          WidgetbookComponent(name: 'Bars', useCases: [
            uc('Bottom CTA', (c) => MartBottomBar(note: 'Примите условия оферты', child: MartButton(label: 'Оплатить', amount: '24 070 тг.', expanded: true, disabledReason: 'x', onPressed: () {}))),
            uc('Offline', (c) => const OfflineBanner(text: 'Нет интернета — показываем сохранённый каталог')),
          ]),
        ]),
      ],
    );
  }
}

typedef UseCase = WidgetbookUseCase;
void _noop() {}
