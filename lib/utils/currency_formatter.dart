import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat(
    '#,##0',
    'es_CO',
  );

  static String format(double value) {
    return '\$${_formatter.format(value)}';
  }
}