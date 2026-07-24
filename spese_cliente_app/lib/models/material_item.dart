class MaterialItem {
  final int? id;
  final int clientId;
  final String name;
  final double quantity;
  final double unitPrice;
  final DateTime date;
  final bool paid;

  MaterialItem({
    this.id,
    required this.clientId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.date,
    this.paid = false,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'clientId': clientId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'date': date.toIso8601String(),
      'paid': paid ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory MaterialItem.fromMap(Map<String, Object?> map) {
    return MaterialItem(
      id: map['id'] as int?,
      clientId: map['clientId'] as int,
      name: map['name'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      paid: (map['paid'] as int? ?? 0) == 1,
    );
  }

  MaterialItem copyWith({
    int? id,
    int? clientId,
    String? name,
    double? quantity,
    double? unitPrice,
    DateTime? date,
    bool? paid,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      date: date ?? this.date,
      paid: paid ?? this.paid,
    );
  }
}
