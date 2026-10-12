# 8mart — Flutter-приложение (iOS + Android)

Стартовый пакет: дизайн-токены, тема (светлая/тёмная), локализация ru/kk, виджеты UI Kit, блоки заказа, экраны главного сценария на Bloc/Cubit, Widgetbook.
Источник правды по дизайну — `App UI Kit.dc.html` и mobile-макеты (`01…08 *.dc.html`). Отличия сайта от приложения — `docs/APP_AUDIT.md`. Макеты — `design/`. Правила для Claude Code — `CLAUDE.md`. Вопросы к бизнесу — `docs/OPEN_QUESTIONS.md`. Push, настройки, документы, разрешения, аналитика — `docs/APP_SPEC.md`.

> Перед работой: `flutter pub get && flutter gen-l10n && flutter analyze && flutter test` (Flutter 3.44+).

## Запуск
```bash
flutter pub get
flutter gen-l10n
flutter run --dart-define-from-file=env.json   # ключи Mapbox/DaData (env.json — в .gitignore, образец env.example.json)
# браузер: flutter run -d web-server --web-port 8080 --dart-define-from-file=env.json
# галерея компонентов
cd widgetbook && flutter pub get && flutter run -d chrome
# данные 8mart.kz (букеты, филиалы) → lib/data/*.g.dart
dart run tool/import_site_data.dart
# иконка приложения (iOS + Android) из вектора
node design/app-icon/build.mjs
# скриншоты для сторов: съёмка на симуляторе, затем баннеры
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/store_screenshots_test.dart -d <симулятор> --dart-define-from-file=env.json
node design/store/build.mjs
```

## Структура
```
lib/
  ui/theme/      MartColors (ThemeExtension light/dark), MartText, шкалы MartSpace/Radius/Height/Motion, buildMartTheme()
  ui/widgets/    MartButton, KaspiPayButton, MartInput (+PhoneMaskFormatter), MartCodeInput, PasteCodeHint, MartChip,
                 MartStepper, BonusBadge, MartImage, MartProductCard, MartCartLine, MartTabBar,
                 showMartSheet, MartBottomBar, MartBackButton/CloseButton, OfflineBanner, showMartToast, MartCross/Chevron
  ui/blocks/     ShipmentHead, SplitChoice + MartRadioTile, PaymentPicker, OrderTimeline
  core/          format.dart (money «4 090 тг.»), phone_mask.dart
  domain/        models.dart, shipments.dart (planShipments — порт из data.js)
  data/          mock_data.dart — ЗАМЕНИТЬ на репозитории API, формы объектов сохранить
  state/         CartCubit (hydrated), FavoritesCubit (hydrated), SettingsCubit (hydrated), AuthCubit, CheckoutCubit, OrderCubit
  features/      home, catalog, search, product (шторка + /p/:id), method, cart, checkout, auth, order, profile (+ account_sections), system (сплэш, обновление), common (сетка, добавление в корзину)
  l10n/          app_ru.arb (шаблон), app_kk.arb — казахский ЧЕРНОВОЙ, вычитать носителем
  router.dart    go_router: таб-бар (StatefulShellRoute) + deep links
widgetbook/      галерея всех виджетов: темы, языки, размеры экрана, масштаб текста
test/            маска телефона, деньги, planShipments
```

## Правила (как в макетах)
- Одно значение — одно место: цвета только из `context.mc`, размеры из `MartHeight/MartRadius`, тарифы из `ShippingConfig`.
- Зона касания ≥ 44: чип 36 и степпер 40 визуально, но ловят нажатие на 44.
- Фото товаров всегда на белой подложке (`MartImage`), в тёмной теме тоже. Kaspi (логотип и кнопка) не перекрашивать.
- Крестики, шевроны, ± — геометрией (`MartCross`, `MartChevron`, `MartPlusMinus`).
- Основной CTA — «текст · сумма» (`MartButton(amount:)`); Kaspi — официальный SVG без суммы.
- CTA заблокирован с объяснением (`disabledReason` + `MartBottomBar(note:)`).
- Способ получения выбирается до первого добавления (`CartCubit.setQty` вернёт false → открыть `openMethodSheet`).

## Настройка платформ
**Deep links** (`8mart.kz`): `/p/:id`, `/order/:id`, `/auth/tg?token=&phone=`, `/pay/return?order=`.
- iOS: Associated Domains `applinks:8mart.kz` + `apple-app-site-association` на домене.
- Android: intent-filter `autoVerify="true"` для `https://8mart.kz` + `/.well-known/assetlinks.json`.
- go_router обрабатывает ссылку сам (Flutter deep linking включён по умолчанию с 3.27; раньше — `flutter_deeplinking_enabled` в Info.plist / AndroidManifest).

**Код из SMS / WhatsApp**
- iOS: `AutofillHints.oneTimeCode` уже стоит (работает для SMS). Для WhatsApp автоподстановки нет → `PasteCodeHint`.
- Android: SMS Retriever (пакет `smart_auth` / `sms_autofill`) — хэш приложения в конце SMS. WhatsApp one-tap autofill — через шаблон WhatsApp Business с `package_name` + `signature_hash`.

**Face ID / отпечаток** (`local_auth`)
- iOS Info.plist: `NSFaceIDUsageDescription` = «Входить в 8mart без кода».
- Android: `MainActivity` extends `FlutterFragmentActivity`, разрешение `USE_BIOMETRIC`.
- Биометрия открывает refresh-токен из `flutter_secure_storage`, вход по телефону не заменяет.

**Push** (FCM + APNs): раскомментировать firebase_* в pubspec, `flutterfire configure`. Разрешение просим на экране статуса после первого заказа (карточка уже есть — `OrderStatusScreen`). `onMessageOpenedApp` → `router.go('/order/<id>')`.

**Карта**: `mapbox_maps_flutter`. Публичный токен (pk.…) передаём при сборке: `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.…`, в коде `const String.fromEnvironment('MAPBOX_ACCESS_TOKEN')` → `MapboxOptions.setAccessToken()`. Секретный токен `sk.…` для mapbox_maps_flutter 2.x не нужен. Подключено в `method_sheet.dart` (MapWidget, пин по центру — Flutter-оверлей, точки самовывоза — PointAnnotation). Адреса — только через бэкенд (`/geo/suggest`, `/geo/reverse` → DaData), ключи DaData в приложение не кладём.

**Офлайн**: корзина/избранное/настройки — hydrated_bloc; фото — `cached_network_image`; каталог — кешировать ответы API (например, `dio_cache_interceptor` + Hive). Без сети — `OfflineBanner`, оплата недоступна, цены перепроверять `POST /cart/validate` перед оплатой.

## API-контракт (что нужно приложению)
Полная передача бэкенду (эндпоинты сайта и приложения, временные адаптеры, оплата, открытые вопросы) — `BACKEND_HANDOFF.md` в репозитории сайта (8mart-site).

| Метод | Ответ |
|---|---|
| `GET /categories` | `[{id, name, image, sub:[{id,name}]}]` |
| `GET /products?category&sub&q&sort&page&min&max&sale` · `GET /products/count` (для «Показать N») | `{items:[Product], total}` — Product: `{id, name, pack, price, oldPrice?, images[], bonus?, delivery:'express'\|'cargo'\|'flowers', weightKg, group?, variants?, colors?, conditions?}` |
| `GET /products/{id}` | Product + `description, specs[]` |
| `POST /cart/validate` | `{lines:[{id, qty, soldOut}], plan:{shipments:[…]}}` — сервер пересчитывает цены, наличие и отправления |
| `GET /geo/suggest?q&city`, `GET /geo/reverse?lat&lng` | DaData через бэкенд |
| `GET /pickup-points?city` | `[{id, name, hours, lat, lng, acceptsCargo}]` |
| `POST /auth/code {phone, channel}` · `POST /auth/verify {phone, code}` | `{accessToken, refreshToken, user:{name?}}` |
| `POST /auth/tg` → `{token}` · `GET /auth/tg/{token}` | `{status:'pending'\|'ok', phone?, tokens?}` |
| `POST /orders` | `{id, payUrl?}` — payUrl для Kaspi / страницы шлюза |
| `GET /orders/{id}` | `{id, status, shipments:[{kind, status, eta, courier?}], total, bonus}` |
| `POST /orders/{id}/cancel` | `{refund:{amount, to}}` |
| `GET/PUT /favorites`, `GET /me/cards`, `GET /me/addresses`, `GET /me/bonus` | как в макетах кабинета |
| `POST /devices {fcmToken, platform}` | регистрация push |
| `GET /search/suggest?q` | `{categories:[…], products:[…], total}` |
| `GET /app/config` | `{minVersion, storeUrl, legal:{offer, privacy, personalData, delivery, bonus}}` |
| `PUT /me/notifications` | `{orders, bonus, promo, cart}` — каналы push |
| `PATCH /me {name}` · `POST /me/phone {phone}` → код → `POST /me/phone/verify` · `DELETE /me` | личные данные |
| `POST/PUT/DELETE /me/addresses/{id}` · `DELETE /me/cards/{id}` | адреса, карты |

## Что сделано / что осталось
Сделано (на моках): сплэш → главная; каталог (категории → подкатегории, фильтры цена/скидка, 5 сортировок, бесконечная прокрутка, скелетоны, «ничего не нашли», «нет сети»); поиск (недавние, «часто ищут», подсказки категорий и товаров, результаты с фильтрами); карточка товара; способ получения; корзина с отправлениями; вход WhatsApp/Telegram + Face ID; оформление с сохранёнными картами; статус с отменой и push-запросом; профиль и 7 разделов кабинета (заказы с «Повторить», избранное, адреса, способы оплаты, промокоды, бонусы, личные данные со сменой телефона и удалением аккаунта); обязательное обновление; тёмная тема; ru/kk.

Осталось подключить (нужны ключи/бэкенд): API вместо MockData, Mapbox в `method_sheet.dart` и `openAddressSheet`, Firebase push, реальная оплата Kaspi/шлюза, connectivity_plus для «нет сети» (сейчас флаг `CatalogRepository.offline`), `AppConfig.forceUpdate` из `GET /app/config`.
Не сделано в дизайне и коде: онбординг.
Мок: тарифы грузовой доставки, бонусы, слоты доставки (`lib/domain/slots.dart`), порог бесплатной доставки. Казахские строки — черновые.

## Сверено с сайтом (8mart-site, октябрь 2026)
Сайт — источник продуктовых решений; приложение приведено к нему:
- **Данные** — настоящие букеты и филиалы 8mart.kz: `dart run tool/import_site_data.dart` → `lib/data/flowers.g.dart` (9 букетов, S/M/L — своя цена и фото, состав по размерам; цена — самая частая по филиалам) и `lib/data/branches.g.dart` (7 филиалов, 5 городов, вывеска, живой статус, Kaspi). Цветы — первая категория, главная — баннер и полки букетов.
- **Доставка** — курьер «от 2 000 тг, 30–70 минут»; с адресом — зона доставки 8mart.kz (`DeliveryRepository`: стоимость и время; вне зон «Доставить сюда» недоступна). Грузовая доставка — «Грузовой» (не «Газель»); смешанная корзина в доставке — всегда двумя доставками, выбор «вместе / раздельно» только в самовывозе.
- **Выбор способа** — на весь экран; поиск адреса — отдельный экран (город списком, подсветка совпадений); подъезда и квартиры нет (они в оформлении); на карте зум «+ / −» и «Моё местоположение» (geolocator); пин без подписи, с лоадером; филиалы — компактные строки со статусом цветом.
- **Оформление** — без блока «Получатель»: телефон получателя, комментарий и «Оставить у двери» — в блоке доставки; отдельный блок «Способ доставки» / «Когда забрать»; время — дни карточками + время списком (`SlotPicker`, `MartSelect`) от текущего времени Казахстана; номер для счёта Kaspi, если филиал без интеграции; оферта включена по умолчанию.
- **Сторис** — ряд на главной (как на сайте): видео-сторис 8mart.kz первыми (`StoryRepository`, video_player; без звука по умолчанию, кнопка звука, прогресс по времени ролика), затем свои — букеты, промокод, доставка; просмотр на весь экран: тап назад/вперёд, удержание — пауза, свайп вбок — соседняя, вниз — закрыть; просмотренные — серой рамкой.
- **Вход** — без шага «имя» (имя по желанию в «Личных данных»). **Бонусы** — зелёная карточка, «Как это работает», история «+ / −». **Профиль → «Вопросы и ответы»** — как на сайте.
- ⚠ Временные адаптеры к публичному API 8mart.kz (`DeliveryRepository`, генератор данных) и к DaData (`GeoRepository`) — заменить эндпоинтами бэкенда, формы ответов те же.

## Промпт для Claude Code
> Это Flutter-проект 8mart (Bloc/Cubit, go_router). Дизайн-система — `lib/ui`, токены — `MartColors`/`MartText`/`MartHeight`, не вводи новых цветов и размеров. Экраны строй только из виджетов `lib/ui`; если нужен новый элемент — сначала добавь его в `lib/ui` и Widgetbook. Замени `MockData` репозиториями по API-контракту из README, сохранив формы моделей. Все строки — в ARB (ru и kk). Проверяй `flutter analyze` и `flutter test` после каждого шага.
