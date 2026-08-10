class CreditCard {
  final int? id;

  final String name;
  final String bank;

  final double creditLimit;
  final double usedAmount;

  final int? cutoffDay;
  final int? paymentDueDay;

  final double minimumPayment;

  CreditCard({
    this.id,
    required this.name,
    required this.bank,
    required this.creditLimit,
    required this.usedAmount,
    this.cutoffDay,
    this.paymentDueDay,
    required this.minimumPayment,
  });

  // ============================================================
  // CUPO DISPONIBLE
  // ============================================================

  double get availableCredit {
    final available =
        creditLimit - usedAmount;

    if (available < 0) {
      return 0;
    }

    return available;
  }

  // ============================================================
  // PORCENTAJE DE UTILIZACIÓN
  // ============================================================

  double get usagePercentage {
    if (creditLimit <= 0) {
      return 0;
    }

    return (usedAmount / creditLimit) * 100;
  }

  // ============================================================
  // MAP PARA SQLITE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bank': bank,
      'credit_limit': creditLimit,
      'used_amount': usedAmount,
      'cutoff_day': cutoffDay,
      'payment_due_day': paymentDueDay,
      'minimum_payment': minimumPayment,
    };
  }

  // ============================================================
  // CREAR DESDE SQLITE
  // ============================================================

  factory CreditCard.fromMap(
    Map<String, dynamic> map,
  ) {
    return CreditCard(
      id: map['id'] as int?,
      name: map['name'] as String,
      bank: map['bank'] as String,
      creditLimit:
          (map['credit_limit'] as num).toDouble(),
      usedAmount:
          (map['used_amount'] as num).toDouble(),
      cutoffDay:
          map['cutoff_day'] as int?,
      paymentDueDay:
          map['payment_due_day'] as int?,
      minimumPayment:
          (map['minimum_payment'] as num).toDouble(),
    );
  }
}