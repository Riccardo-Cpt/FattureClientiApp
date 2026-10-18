import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/models/client.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late ClientRepository repo;

  setUp(() {
    helper = DatabaseHelper(inMemory: true);
    repo = ClientRepository(helper);
  });

  tearDown(() async {
    await helper.close();
  });

  test('insertClient returns a positive id, getAllClients returns it back', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    expect(id, greaterThan(0));

    final all = await repo.getAllClients();
    expect(all.length, 1);
    expect(all.first.name, 'Mario');
    expect(all.first.surname, 'Rossi');
  });

  test('getAllClients orders by surname then name', () async {
    await repo.insertClient(Client(name: 'Zara', surname: 'Alpha'));
    await repo.insertClient(Client(name: 'Anna', surname: 'Alpha'));
    await repo.insertClient(Client(name: 'Bob', surname: 'Beta'));

    final all = await repo.getAllClients();
    expect(all.map((c) => '${c.surname}-${c.name}').toList(), [
      'Alpha-Anna',
      'Alpha-Zara',
      'Beta-Bob',
    ]);
  });

  test('updateClient persists changes', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    await repo.updateClient(Client(id: id, name: 'Mario', surname: 'Verdi'));

    final all = await repo.getAllClients();
    expect(all.first.surname, 'Verdi');
  });

  test('deleteClient removes the client', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    await repo.deleteClient(id);

    final all = await repo.getAllClients();
    expect(all, isEmpty);
  });

  test('deleteClient cascades to that client materials', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final db = await helper.database;
    await db.insert('materials', {
      'clientId': id,
      'name': 'Cement',
      'quantity': 1.0,
      'unitPrice': 10.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });

    await repo.deleteClient(id);

    final remaining = await db.query('materials');
    expect(remaining, isEmpty);
  });

  test('getTotalSpentForClient sums quantity * unitPrice, 0.0 when none', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final db = await helper.database;

    expect(await repo.getTotalSpentForClient(id), 0.0);

    await db.insert('materials', {
      'clientId': id,
      'name': 'Cement',
      'quantity': 3.0,
      'unitPrice': 15.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });
    await db.insert('materials', {
      'clientId': id,
      'name': 'Bricks',
      'quantity': 10.0,
      'unitPrice': 2.5,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });

    expect(await repo.getTotalSpentForClient(id), 70.0);
  });

  test('getTotalSpentForClient excludes paid materials', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final db = await helper.database;

    await db.insert('materials', {
      'clientId': id,
      'name': 'Cement',
      'quantity': 3.0,
      'unitPrice': 15.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
      'paid': 1,
    });
    await db.insert('materials', {
      'clientId': id,
      'name': 'Bricks',
      'quantity': 10.0,
      'unitPrice': 2.5,
      'date': DateTime(2026, 7, 20).toIso8601String(),
      'paid': 0,
    });

    expect(await repo.getTotalSpentForClient(id), 25.0);
  });

  test('year filter restricts totals and getMaterialYears lists distinct years', () async {
    final id = await repo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final db = await helper.database;
    for (final date in [DateTime(2025, 12, 31), DateTime(2026, 1, 1), DateTime(2026, 7, 20)]) {
      await db.insert('materials', {
        'clientId': id,
        'name': 'Item',
        'quantity': 1.0,
        'unitPrice': 10.0,
        'date': date.toIso8601String(),
        'paid': 0,
      });
    }

    expect(await repo.getTotalSpentForClient(id), 30.0);
    expect(await repo.getTotalSpentForClient(id, year: 2026), 20.0);
    expect(await repo.getTotalSpentForClient(id, year: 2025), 10.0);
    expect(await repo.getTotalSpentForClient(id, year: 2024), 0.0);
    expect(await repo.getMaterialYears(), [2026, 2025]);
  });
}
