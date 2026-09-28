# Макет → Flutter

Правило: мобильные артборды 390 переносятся 1:1: порядок блоков, размеры, отступы, цвета, тексты. Допустимы только системные отличия из `APP_AUDIT.md` (safe area, шторки, системный «назад», зона касания 44). В doc-комментарии каждого виджета указан исходный `.dc.html`.

## Компоненты
| Макет | Flutter | Статус |
|---|---|---|
| MartTabBar | ui/widgets/mart_tab_bar.dart | ✅ сверено (иконки пересчитаны по CSS: дверь по центру, плечи профиля) |
| MartStepper | ui/widgets/mart_stepper.dart | ✅ |
| MartProductCard | ui/widgets/mart_product_card.dart | ✅ |
| MartChip | ui/widgets/mart_chip.dart | ✅ |
| MartHeader (mobile) | ui/blocks/mart_headers.dart → MartHomeHeader, MartTopPanel, MartTitleRow, MartSearchPill | ✅ |
| MartCartLine | ui/widgets/mart_cart_line.dart | ✅ |
| MartShipmentHead | ui/blocks/shipment_head.dart | ✅ |
| MartSplitChoice | ui/blocks/split_choice.dart (MartRadioTile — радио слева) | ✅ |
| MartPromo | ui/blocks/mart_promo.dart | ✅ новый |
| Оплата (03, блок «Оплата») | ui/blocks/payment_picker.dart (радио справа) | ✅ |
| Переключатель (подъём, бонусы) | ui/widgets/mart_switch_tile.dart | ✅ новый |
| MartButton, MartInput | ui/widgets/mart_button.dart, mart_input.dart | ⏳ сверить |
| MartProductView (mobile) | features/product/product_view.dart | ✅ |
| MartSearch | features/search/search_screen.dart | ✅ |
| MartMethodModal (mobile) | features/method/method_sheet.dart — mapbox_maps_flutter (нативный SDK), GeoRepository (DaData) | ✅ |
| MartAuth (mobile) | features/auth/auth_view.dart + ui/widgets/mart_code_input.dart | ✅ (прототип: код 1234) |
| MartAccount (mobile) | features/profile/profile_screen.dart (меню), account_sections.dart | ✅ все разделы |
| MartFilters | catalog_screen.dart → openFiltersSheet | ⏳ |

## Экраны
| Макет (390) | Flutter | Статус |
|---|---|---|
| 01 #1b Главная | features/home/home_screen.dart | ✅ |
| 07 #7b Каталог (корень / категория / список) | features/catalog/catalog_screen.dart | ✅ |
| 02 #2b Корзина | features/cart/cart_screen.dart | ✅ |
| 03 #3b Оформление | features/checkout/checkout_screen.dart | ✅ |
| 03 Статус заказа (#3b success) | features/order/order_status_screen.dart + ui/blocks/order_timeline.dart | ✅ |
| 04 Способ получения | features/method/method_sheet.dart | ✅ |
| 05 Поиск (#5b, #5d) | features/search/search_screen.dart | ✅ |
| 06 Кабинет (#6b, #6c) | features/profile/* | ✅ |
| 08 Товар | features/product/product_view.dart (ProductPage) | ✅ |
