import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/client.dart';

void main() {
  test('Client toMap/fromMap round-trip', () {
    final client = Client(id: 1, name: 'Mario', surname: 'Rossi');

    final map = client.toMap();
    expect(map, {'id': 1, 'name': 'Mario', 'surname': 'Rossi'});

    final rebuilt = Client.fromMap(map);
    expect(rebuilt.id, 1);
    expect(rebuilt.name, 'Mario');
    expect(rebuilt.surname, 'Rossi');
  });

  test('Client toMap omits id when null (for insert)', () {
    final client = Client(name: 'Anna', surname: 'Bianchi');
    final map = client.toMap();
    expect(map.containsKey('id'), isFalse);
  });
}
