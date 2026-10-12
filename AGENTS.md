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
| `API_URL` | адрес бэкенда, например `https://api.8mart.kz/v1`. Пусто — приложение на моке |
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

Временные мосты помечены `TEMP-ADAPTER` (`grep -rn TEMP-ADAPTER lib tool`). Когда эндпоинт работает на проде, мост можно удалить.

## Что подключить (карта мока)

Экраны и кубиты пока читают `MockData` (`lib/data/mock_data.dart`) напрямую и синхронно. Порядок работы:

1. Сделать репозиторий в `lib/data/`. Образец — `DeliveryRepository`: `if (ApiClient.isMocked('имя')) мок; иначе ApiClient.instance.get(...)`.
2. Загружать данные в кубите (`loading` → данные / ошибка) и отдавать экрану из state. Скелетоны и пустые состояния уже есть в `lib/ui`.
3. Убрать обращение к `MockData` из экрана.

| `MockData.…` | Где используется | Эндпоинт |
|---|---|---|
| `categories`, `subcategories`, `subsOf`, `subName`, `category` | home, catalog, search, product | `GET /categories` |
| `products`, `byId`, `cartItem` | home, catalog, search, product, cart_cubit, order, account | `GET /products…`, `GET /products/{id}`, `POST /cart/validate` |
| `CatalogRepository.page/count` | catalog_cubit | `GET /products?…`, `GET /products/count` |
| `ProductConditions` (`product_details.dart`) | product | `conditions` в `GET /products/{id}` |
| `popularQueries` | search | `GET /search/suggest` или конфиг |
| `cities`, `pickupPoints` (`branches.g.dart`) | method_sheet, address_search, faq | `GET /cities`, `GET /pickup-points?city` |
| `cards` | account_cubit, checkout | `GET /me/cards`, `DELETE /me/cards/{id}` |
| `addresses` | account_cubit | `GET/POST/PUT/DELETE /me/addresses` |
| `orders` | account_cubit, order_status | `GET /orders`, `GET /orders/{id}`, `POST /orders/{id}/cancel` |
| `promos` | account_cubit | `GET /me/promos` |
| `bonusBalance`, `bonusMaxPart`, `bonusHistory` | account, checkout, faq | `GET /me/bonus` |
| `supportPhone`, `supportWa`, `tgLink` | faq, order, auth | `GET /app/config` |
| `AuthCubit` (код `1234`) | auth | `POST /auth/code`, `/auth/verify`, `/auth/tg`, `GET /auth/tg/{token}` |
| `OrderCubit.create`, `CheckoutCubit` | checkout | `POST /orders` → `{id, payUrl?}` |
| `PromoRules` (`cart_cubit.dart`) | cart | `POST /promo/check` |
| слоты (`lib/domain/slots.dart`) | checkout | `GET /delivery/slots?kind` |

`colorSwatch` и `flowerSizeHint` — справочники интерфейса, остаются в приложении.

**Вход.** После `POST /auth/verify` сохранить `refreshToken` во `flutter_secure_storage` и выставить `ApiClient.instance.token = () => accessToken`. Обновление по 401 (`POST /auth/refresh`) добавить в `ApiClient.send`.

**Сторис.** `cta.href` у сайта — пути сайта (`/product/f1`). Приложению нужны свои маршруты (`/p/f1`, `lib/router.dart`): либо бэкенд отдаёт `cta.appPath`, либо перевести путь в `StoryRepository.storyFromJson`.

## Границы

- Экраны строятся только из `lib/ui`. Цвета, размеры и тексты (ARB ru + kk) не менять.
- Тарифы и пороги (`ShippingConfig`), правила отправлений (`lib/domain/shipments.dart`) — предварительный расчёт. Источник правды — бэкенд; формулы должны совпадать с сайтом.
- Новые зависимости — только по необходимости. Для запросов хватает `ApiClient`.

## Проверка

```bash
flutter pub get && flutter gen-l10n
flutter analyze      # без ошибок и предупреждений
flutter test         # тест переключателя — test/api_client_test.dart
```

Затем пройти руками на симуляторе в светлой и тёмной теме: главная → каталог → товар → корзина → способ получения → оформление → заказ → профиль.
