import 'models.dart';

/// Тон статуса филиала — цветом подсказываем «открыто / не принимает заказы / закрыто» (как на сайте).
enum StoreTone { open, soon, closed }

/// Статус точки самовывоза по живому статусу филиала из API (графика работы в API нет).
StoreTone storeTone(PickupPoint p) => !p.isOpen ? StoreTone.closed : !p.acceptingOrders ? StoreTone.soon : StoreTone.open;
