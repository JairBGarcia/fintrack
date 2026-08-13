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

  // ============================================================
  // CONVERTIR A MAPA
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
    };
  }

  // ============================================================
  // CREAR DESDE MAPA
  // ============================================================

  factory Account.fromMap(
    Map<String, dynamic> map,
  ) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
    );
  }

  // ============================================================
  // COPIAR CUENTA CON CAMBIOS
  // ============================================================

  Account copyWith({
    int? id,
    String? name,
    String? type,
    double? balance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
    );
  }
}