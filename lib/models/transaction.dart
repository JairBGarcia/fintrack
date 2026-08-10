class TransactionModel {
  final int? id;
  final String type;
  final double amount;
  final int? accountId;
  final int? destinationAccountId;
  final String category;
  final String description;
  final DateTime date;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    this.accountId,
    this.destinationAccountId,
    required this.category,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'account_id': accountId,
      'destination_account_id': destinationAccountId,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      accountId: map['account_id'],
      destinationAccountId: map['destination_account_id'],
      category: map['category'],
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
    );
  }
}