import 'package:flutter/material.dart';

import '../../domain/models.dart';

/// ORDER_STATUS из data.js: подпись, тон (active / ok / bad) и шкала из 4 этапов.
String orderStatusLabel(OrderSummary o) => switch (o.status) {
      OrderStatus.accepted => 'Принят', OrderStatus.assembling => 'Собираем', OrderStatus.onway => 'Курьер в пути',
      OrderStatus.ready => 'Готов к выдаче', OrderStatus.done => o.method == ReceiveMethod.pickup ? 'Выдан' : 'Доставлен', OrderStatus.cancelled => 'Отменён',
    };
(Color, Color) orderTone(OrderStatus s) => switch (s) {
      OrderStatus.done => (const Color(0xFFEAF7F0), const Color(0xFF1DA765)),
      OrderStatus.cancelled => (const Color(0xFFFDEDED), const Color(0xFFE23D3D)),
      _ => (const Color(0xFFFDF0F6), const Color(0xFFEE1D74)),
    };
List<String> orderSteps(OrderSummary o) => o.method == ReceiveMethod.pickup ? const ['Принят', 'Собираем', 'Готов', 'Выдан'] : const ['Принят', 'Собираем', 'В пути', 'Доставлен'];
/// Текущий этап 0..3 (ready = 2 у самовывоза, onway = 2 у доставки).
int orderStep(OrderSummary o) => switch (o.status) {
      OrderStatus.accepted => 0, OrderStatus.assembling => 1, OrderStatus.onway || OrderStatus.ready => 2, _ => 3,
    };
