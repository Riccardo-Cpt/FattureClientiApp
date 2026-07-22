class MaterialItem {
  final int? id;
  final int clientId;
  final String name;
  final double quantity;
  final double unitPrice;
  final DateTime date;

  MaterialItem({
    this.id,
    required this.clientId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.date,
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'clientId': clientId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'date': date.toIso8601String(),
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
    );
  }

  MaterialItem copyWith({
    int? id,
    int? clientId,
    String? name,
    double? quantity,
    double? unitPrice,
    DateTime? date,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      date: date ?? this.date,
    );
  }
}
