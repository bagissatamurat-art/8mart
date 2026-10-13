# AGENTS.md — для разработчика бэкенда и его ИИ-агента (приложение 8mart, Flutter)

Приложение готово на моках и согласовано с владельцем. Задача — подключить бэкенд, **не меняя экраны и поведение**. Сайт (`bagissatamurat-art/8mart-site`) уже подготовлен так же — у него тот же API.

## Прочитай сначала

1. `BACKEND_HANDOFF.md` в репозитории сайта — все эндпоинты, формы ответов, оплата, открытые вопросы. Формы общие для сайта и приложения.
2. `lib/domain/models.dart` — модели приложения. Формы не менять без согласования.
3. `lib/core/api_client.dart` — HTTP-клиент и переключатель мок / API.
4. `CLAUDE.md` и `README.md` — правила дизайна и бизнес-правила.

## Ключи и сборка

Ключи в репозиторий не коммитятся. Их передают при сборке из `env.json` (он в `.gitignore`):

```bash
cp env.example.json env.json      # вписать значения
flutter run --dart-define-from-file=env.json
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist --dart-define-from-file=env.json
flutter build appbundle --release --dart-define-from-file=env.json
```

| Ключ | Что это |
|---|---|
| `API_URL` | адрес бэкенда. Прод — `https://dukenfy-api.8mart.kz/api/v1/store` (слой витрины в core, описан в `STOREFRONT_API.md` репозитория бэкенда). Пусто — приложение на моке |
| `API_MOCK` | что пока остаётся на моке, через запятую: `stories,geo,deliveryQuote`; `*` — всё |
| `MAPBOX_ACCESS_TOKEN` | публичный `pk.*` Mapbox — карта выбора адреса. Ограничить по bundle id в кабинете Mapbox |
| `DADATA_API_KEY` | временно: подсказки адресов из клиента, пока нет `GET /geo/*`. С бэкендом — убрать |

Секретные ключи (DaData secret, Mapbox `sk.*`, ключи платёжного шлюза, Firebase server key) — только на бэкенде, в приложение не класть.

Подпись iOS — команда A874LGAK3L, bundle id `com.dukenfy.app`. Firebase (`GoogleService-Info.plist`, `google-services.json`) ещё не подключён.

## Что уже переключается

| Имя в `API_MOCK` | Репозиторий | Эндпоинт | Без бэкенда |
|---|---|---|---|
| `deliveryQuote` | `lib/data/delivery_repository.dart` | `GET /delivery/quote?lat&lng` | TEMP-ADAPTER: зоны 8mart.kz |
| `stories` | `lib/data/story_repository.dart` | `GET /stories` | TEMP-ADAPTER: сторис 8mart.kz + свои |
| `geo` | `lib/data/geo_repository.dart` | `GET /geo/suggest?q&city`, `GET /geo/reverse?lat&lng` | TEMP-ADAPTER: DaData из клиента |
| `catalog` | `lib/data/catalog.dart` (кеш для экранов), `lib/data/catalog_repository.dart` | `GET /categories`, `GET /products?category&sub&q&sort&page&min&max&sale`, `GET /products?ids=`, `GET /products/{id}`, `GET /search/suggest?q` | `MockData` (категории, товары, описания) |
| `places` | `lib/data/places.dart` | `GET /cities`, `GET /pickup-points` | снимок филиалов `lib/data/branches.g.dart` |
| `config` | `lib/data/remote_config.dart` | `GET /app/config` — контакты поддержки, способы оплаты, порог бесплатной доставки, включённые функции | значения мока |
| `cart` | `lib/data/cart_repository.dart` → `CartCubit.validate()` | `POST /cart/validate` — раскупленное и цены своего филиала | проверки нет |
| `slots` | `lib/data/slots_repository.dart` → `CheckoutCubit.loadSlots()` | `GET /delivery/slots?kind` | расчёт на устройстве (`lib/domain/slots.dart`) |
| `orders` | `lib/data/order_repository.dart` → `CheckoutCubit.place`, `OrderCubit`, `AccountCubit` | `POST /orders`, `GET /orders/{id}`, `GET /orders?ids=`, `POST /orders/{id}/cancel` | демо-заказ и демо-кабинет |
| `auth` | `lib/data/auth_repository.dart` (`AuthRepository`, `AuthSession`) → `AuthCubit` | `POST /auth/tg`, `GET /auth/tg/{token}`, `POST /auth/logout`, `GET/PATCH/DELETE /me` | вход из макета: телефон → код `1234` |

Временные мосты помечены `TEMP-ADAPTER` (`grep -rn TEMP-ADAPTER lib tool`). Когда эндпоинт работает на проде, мост можно удалить.

`Catalog` и `Places` — хранилища с синхронным доступом: экраны читают `Catalog.categories`, `Catalog.byId(id)`, `Catalog.cartItem(key)`, `Places.cities` и перерисовываются по `Catalog.changes` / `Places.changes`. С бэкендом кеш прогревается при запуске (`main.dart`, сплэш ждёт его не дольше 4 с), карточки корзины и избранного, дерево категорий и филиалы хранятся на диске; на моке те же вызовы отдают `MockData`. Счётчик «Показать N» — `total` из `GET /products` с теми же фильтрами.

## Что подключено и что осталось

С `API_URL` на бэкенде работает всё: вход, каталог, поиск, карточка, корзина (цены и наличие филиала), способ получения, слоты, оформление, оплата, статус и отмена заказа, «Мои заказы», профиль, контакты поддержки. Экраны `MockData` напрямую не читают — только репозитории в своих мок-ветках.

Как это устроено:

- **Вход — только через Telegram-бота**, кода из WhatsApp нет. «Войти через Telegram» → сервер даёт ссылку `t.me/<бот>?start=<токен>` → покупатель нажимает в боте «Старт» и «Поделиться номером» → приложение опрашивает `GET /auth/tg/{token}` раз в 2 с (и сразу при возврате из Telegram) и получает сессию. Номер подтверждает Telegram, поэтому вводить его не нужно. Ссылка живёт 10 минут; устарела — экран предлагает новую.
- **Сессия** (`AuthSession`) — токен и профиль в Keychain / Keystore (`flutter_secure_storage`), читается до `runApp`: приложение открывается уже в аккаунте. Токен уходит в каждый запрос; ответ 401 сессию закрывает, и приложение выходит из аккаунта. Отдельного токена обновления нет: сервер продлевает сессию обращениями.
- **Профиль**: имя — `PATCH /me`, удаление аккаунта — `DELETE /me`, выход — `POST /auth/logout`. Номер телефона — тот, что подтвердил Telegram; сменить его можно только новым входом, поэтому кнопки «Изменить» с бэкендом нет.
- **Заказ** создаётся с телефоном получателя из оформления; сервер сам определяет филиал, цены и стоимость доставки и привязывает заказ к вошедшему покупателю. В корзине лежат место получения для сервера: `cityId`, `pointId` (самовывоз) или `lat`/`lng` (доставка).
- **«Мои заказы»** — заказы покупателя с сервера (`GET /orders` с токеном) плюс те, чьи id помнит устройство (`PlacedOrdersCubit`). Заказ вошедшего покупателя виден только ему. Заказ открывается по своему id (длинный ключ), человеку показываем `number`.
- **Адреса и избранное** хранятся на устройстве; на сервер (`/me/addresses`, `/favorites`) пока не переехали.
- **Промокоды, бонусы, сохранённые карты** на сервере не заведены. С бэкендом их поля и разделы скрыты (`RemoteConfig.promo` / `.bonus`), чтобы не показывать выдуманные числа; включатся, когда сервер пришлёт `features` в `/app/config`.
- **Порог бесплатной доставки** приходит с сервера (`delivery.freeFrom`). Сейчас его нет: платится стоимость зоны, и приложение не пишет «бесплатно от…» (`ShippingConfig.current`).
- **Перед оплатой** корзина проверяется ещё раз: если цены или наличие изменились, заказ не создаётся — покупатель сначала видит новую сумму.

Что остаётся на моке:

| Что | Где | Что нужно |
|---|---|---|
| Адреса и избранное на сервере | `AccountCubit`, `FavoritesCubit` | `/me/addresses`, `/favorites` — на сервере ещё нет |
| Вход по Face ID | `auth_view.dart` (`offerBiometrics`) | сейчас это только настройка: сессия и так хранится в Keychain и открывается без кода |
| Условия получения в карточке («Через 30 минут», «Храним 24 часа») | `product_details.dart` | тексты от бизнеса; сервер `conditions` не отдаёт |
| Обязательное обновление | `system_screens.dart` (`AppConfig.forceUpdate`) | `package_info_plus` + `minVersion` из `/app/config` |
| Push | `lib/core/push.dart` | проект Firebase, `POST /devices` |

`colorSwatch` и `flowerSizeHint` — справочники интерфейса, остаются в приложении.

**Вход.** После `POST /auth/verify` сохранить `refreshToken` во `flutter_secure_storage` и выставить `ApiClient.instance.token = () => accessToken`. Обновление по 401 (`POST /auth/refresh`) добавить в `ApiClient.send`.

**Сторис.** С бэкендом показываются только сторис сервера; свои слайды приложения собраны на товарах мока и остаются только в мок-режиме.

## Границы

- Экраны строятся только из `lib/ui`. Цвета, размеры и тексты (ARB ru + kk) не менять.
- Тарифы и пороги (`ShippingConfig`), правила отправлений (`lib/domain/shipments.dart`) — предварительный расчёт. Источник правды — бэкенд; формулы должны совпадать с сайтом.
- Новые зависимости — только по необходимости. Для запросов хватает `ApiClient`.

## Проверка

```bash
flutter pub get && flutter gen-l10n
flutter analyze      # без ошибок и предупреждений
flutter test         # переключатель — test/api_client_test.dart; каталог — test/catalog_api_test.dart; заказы, корзина, слоты, настройки — test/orders_api_test.dart; экран статуса — test/order_screen_test.dart; вход — test/auth_api_test.dart
```

Затем пройти руками на симуляторе в светлой и тёмной теме: главная → каталог → товар → корзина → способ получения → оформление → заказ → профиль.
