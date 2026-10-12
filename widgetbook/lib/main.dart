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
            uc('Courier', (c) => const ShipmentHead(tag: 'Курьер', cargo: false, label: 'Доставка 1 из 2', when: 'Сегодня, за 30–70 минут', meta: 'Курьер · 2 товара', feeText: '1 000 тг.')),
            uc('Cargo', (c) => const ShipmentHead(tag: 'Грузовой', cargo: true, label: 'Доставка 2 из 2', when: 'Завтра, 9:00–21:00', meta: 'Грузовой · 125 кг', feeText: '3 000 тг.')),
          ]),
          WidgetbookComponent(name: 'MartStoryThumb', useCases: [
            uc('Новая / просмотренная', (c) => Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              MartStoryThumb(cover: 'assets/images/st-flowers.jpg', title: 'Букеты', seen: false, onTap: () {}),
              const SizedBox(width: 8),
              MartStoryThumb(cover: 'assets/images/st-gifts.jpg', title: 'Гортензии', seen: true, onTap: () {}),
            ]))),
          ]),
          WidgetbookComponent(name: 'MartSelect', useCases: [
            uc('Время доставки', (c) => const _SelectDemo()),
          ]),
          WidgetbookComponent(name: 'SlotPicker', useCases: [
            uc('Курьер: дни + время', (c) => const _SlotDemo()),
          ]),
          WidgetbookComponent(name: 'SplitChoice', useCases: [
            // Только самовывоз: в доставке курьер и грузовой — всегда две доставки, выбора нет.
            uc('Pickup', (c) => SplitChoice(title: 'Как забрать заказ', sub: 'Тяжёлые товары выдаём только со склада, с завтрашнего дня',
                together: c.knobs.boolean(label: 'together'), onChanged: (_) {}, options: const [
                  SplitOption(together: false, title: 'Забрать в два приёма', sub: 'Сегодня, через 30 минут + Завтра с 9:00', feeText: 'Бесплатно'),
                  SplitOption(together: true, title: 'Всё завтра со склада', sub: 'Завтра с 9:00', feeText: 'Бесплатно'),
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

const _slotOptions = [MartSelectOption('asap', 'Ближайшее', '~30 мин'), MartSelectOption('12', '12:00–15:00'), MartSelectOption('15', '15:00–18:00'), MartSelectOption('18', '18:00–21:00')];

class _SelectDemo extends StatefulWidget {
  const _SelectDemo();
  @override
  State<_SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<_SelectDemo> {
  String v = 'asap';
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16),
      child: MartSelect(label: 'Время', options: _slotOptions, value: v, onChanged: (x) => setState(() => v = x)));
}

class _SlotDemo extends StatefulWidget {
  const _SlotDemo();
  @override
  State<_SlotDemo> createState() => _SlotDemoState();
}

class _SlotDemoState extends State<_SlotDemo> {
  String v = 'asap';
  static const days = [
    SlotPickerDay(id: 'd0', title: 'Сегодня', date: '13 окт', options: _slotOptions),
    SlotPickerDay(id: 'd1', title: 'Завтра', date: '14 окт', options: [MartSelectOption('d1-9', '09:00–12:00'), MartSelectOption('d1-12', '12:00–15:00')]),
    SlotPickerDay(id: 'd2', title: 'Чт', date: '15 окт', options: [MartSelectOption('d2-9', '09:00–12:00'), MartSelectOption('d2-12', '12:00–15:00')]),
  ];
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16),
      child: SlotPicker(timeLabel: 'Время', days: days, value: v, onChanged: (x) => setState(() => v = x)));
}
