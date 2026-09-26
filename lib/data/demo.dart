import '../domain/models.dart';
import 'mock_data.dart';

/// Демо-данные для Widgetbook и тестов.
extension CartLineX on CartLine {
  static CartLine demo({bool soldOut = false}) => CartLine(MockData.products.first, 2, soldOut: soldOut);
}
