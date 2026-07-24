import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/material_item.dart';

void main() {
  test('totalPrice is computed from quantity and unitPrice', () {
    final item = MaterialItem(
      clientId: 1,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    );

    expect(item.totalPrice, 45.0);
  });

  test('toMap/fromMap round-trip preserves fields, date, and paid', () {
    final date = DateTime(2026, 7, 20);
    final item = MaterialItem(
      id: 5,
      clientId: 2,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: date,
      paid: true,
    );

    final map = item.toMap();
    expect(map['id'], 5);
    expect(map['clientId'], 2);
    expect(map['name'], 'Bricks');
    expect(map['quantity'], 10.0);
    expect(map['unitPrice'], 2.5);
    expect(map['date'], date.toIso8601String());
    expect(map['paid'], 1);

    final rebuilt = MaterialItem.fromMap(map);
    expect(rebuilt.id, 5);
    expect(rebuilt.clientId, 2);
    expect(rebuilt.name, 'Bricks');
    expect(rebuilt.quantity, 10.0);
    expect(rebuilt.unitPrice, 2.5);
    expect(rebuilt.date, date);
    expect(rebuilt.totalPrice, 25.0);
    expect(rebuilt.paid, isTrue);
  });

  test('paid defaults to false when not provided', () {
    final item = MaterialItem(
      clientId: 1,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    );
    expect(item.paid, isFalse);
    expect(item.toMap()['paid'], 0);
  });

  test('toMap omits id when null (for insert)', () {
    final item = MaterialItem(
      clientId: 1,
      name: 'Sand',
      quantity: 1,
      unitPrice: 5,
      date: DateTime(2026, 7, 20),
    );
    expect(item.toMap().containsKey('id'), isFalse);
  });
}
