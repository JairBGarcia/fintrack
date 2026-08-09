class Account {
  final int? id;
  final String name;
  final String type;
  final double balance;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }
}