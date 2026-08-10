String formatCurrency(double value) {
  final number = value.round().toString();

  final buffer = StringBuffer();

  for (int i = 0; i < number.length; i++) {
    final positionFromEnd = number.length - i;

    buffer.write(number[i]);

    if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
      buffer.write('.');
    }
  }

  return '\$${buffer.toString()}';
}