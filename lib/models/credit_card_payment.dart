class CreditCardPayment {
  final int? id;

  // Tarjeta a la que se le hace el pago
  final int creditCardId;

  // Cuenta desde donde sale el dinero
  final int accountId;

  // Compra específica que se está pagando.
  // Puede ser null si posteriormente hacemos
  // pagos generales a la tarjeta.
  final int? purchaseId;

  // Valor del pago
  final double amount;

  // Fecha del pago
  final DateTime paymentDate;

  // Descripción opcional
  final String description;

  CreditCardPayment({
    this.id,
    required this.creditCardId,
    required this.accountId,
    this.purchaseId,
    required this.amount,
    required this.paymentDate,
    this.description = '',
  });

  // ============================================================
  // MAP PARA SQLITE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'credit_card_id': creditCardId,
      'account_id': accountId,
      'purchase_id': purchaseId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
      'description': description,
    };
  }

  // ============================================================
  // CREAR DESDE SQLITE
  // ============================================================

  factory CreditCardPayment.fromMap(
    Map<String, dynamic> map,
  ) {
    return CreditCardPayment(
      id: map['id'] as int?,
      creditCardId:
          map['credit_card_id'] as int,
      accountId:
          map['account_id'] as int,
      purchaseId:
          map['purchase_id'] as int?,
      amount:
          (map['amount'] as num).toDouble(),
      paymentDate:
          DateTime.parse(
        map['payment_date'] as String,
      ),
      description:
          map['description'] as String? ?? '',
    );
  }
}