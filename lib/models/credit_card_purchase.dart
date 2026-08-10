class CreditCardPurchase {
  final int? id;

  final int creditCardId;

  final String description;
  final String category;

  // Valor ORIGINAL de la compra.
  // Este valor NO cambia cuando se registra un pago.
  final double amount;

  final DateTime purchaseDate;

  final int installments;

  final double annualEffectiveRate;

  // Total pagado hasta el momento.
  final double paidAmount;

  const CreditCardPurchase({
    this.id,
    required this.creditCardId,
    required this.description,
    required this.category,
    required this.amount,
    required this.purchaseDate,
    required this.installments,
    required this.annualEffectiveRate,
    required this.paidAmount,
  });

  // ============================================================
  // SALDO PENDIENTE
  // ============================================================

  double get remainingAmount {
    if (amount <= 0) {
      return 0;
    }

    final remaining = amount - paidAmount;

    if (remaining <= 0) {
      return 0;
    }

    return remaining;
  }

  // ============================================================
  // PORCENTAJE PAGADO
  // ============================================================

  double get paidPercentage {
    if (amount <= 0) {
      return 0;
    }

    final percentage = (paidAmount / amount) * 100;

    if (percentage <= 0) {
      return 0;
    }

    if (percentage >= 100) {
      return 100;
    }

    return percentage;
  }

  // ============================================================
  // PORCENTAJE PENDIENTE
  // ============================================================

  double get remainingPercentage {
    return 100 - paidPercentage;
  }

  // ============================================================
  // VALOR BASE DE CADA CUOTA
  // ============================================================

  double get installmentAmount {
    if (installments <= 0) {
      return amount;
    }

    return amount / installments;
  }

  // ============================================================
  // ESTADO DE LA COMPRA
  // ============================================================

  bool get isPaid {
    return remainingAmount <= 0;
  }

  // ============================================================
  // TIENE CUOTAS
  // ============================================================

  bool get hasInstallments {
    return installments > 1;
  }

  // ============================================================
  // ESTADO COMO TEXTO
  // ============================================================

  String get status {
    if (isPaid) {
      return 'Pagada';
    }

    if (paidAmount > 0) {
      return 'En pago';
    }

    return 'Pendiente';
  }

  // ============================================================
  // MAP PARA SQLITE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'credit_card_id': creditCardId,
      'description': description,
      'category': category,
      'amount': amount,
      'purchase_date': purchaseDate.toIso8601String(),
      'installments': installments,
      'annual_effective_rate': annualEffectiveRate,
      'paid_amount': paidAmount,
    };
  }

  // ============================================================
  // CREAR DESDE SQLITE
  // ============================================================

  factory CreditCardPurchase.fromMap(
    Map<String, dynamic> map,
  ) {
    return CreditCardPurchase(
      id: map['id'] == null
          ? null
          : (map['id'] as num).toInt(),

      creditCardId:
          (map['credit_card_id'] as num).toInt(),

      description:
          map['description']?.toString() ?? '',

      category:
          map['category']?.toString() ?? 'Otros',

      amount:
          (map['amount'] as num?)?.toDouble() ?? 0,

      purchaseDate:
          DateTime.parse(
        map['purchase_date'].toString(),
      ),

      installments:
          (map['installments'] as num?)?.toInt() ?? 1,

      annualEffectiveRate:
          (map['annual_effective_rate'] as num?)
                  ?.toDouble() ??
              0,

      paidAmount:
          (map['paid_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}