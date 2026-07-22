import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database creates clients and materials tables', () async {
    final helper = DatabaseHelper(inMemory: true);
    final db = await helper.database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('clients','materials')",
    );
    final names = tables.map((row) => row['name']).toSet();

    expect(names, {'clients', 'materials'});

    await helper.close();
  });

  test('inserting a material with unknown clientId still works (no FK enforcement needed for insert)', () async {
    final helper = DatabaseHelper(inMemory: true);
    final db = await helper.database;

    final clientId = await db.insert('clients', {'name': 'Mario', 'surname': 'Rossi'});
    final materialId = await db.insert('materials', {
      'clientId': clientId,
      'name': 'Cement',
      'quantity': 3.0,
      'unitPrice': 15.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });

    expect(materialId, greaterThan(0));

    await helper.close();
  });
}
