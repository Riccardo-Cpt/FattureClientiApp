import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
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
      'paid': 0,
    });

    expect(materialId, greaterThan(0));

    await helper.close();
  });

  test('materials table has a paid column defaulting to 0', () async {
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

    final rows = await db.query('materials', where: 'id = ?', whereArgs: [materialId]);
    expect(rows.first['paid'], 0);

    await helper.close();
  });

  test('upgrading from version 1 adds the paid column defaulting to 0', () async {
    final dir = await Directory.systemTemp.createTemp('db_upgrade_test');
    final path = join(dir.path, 'test.db');
    addTearDown(() => dir.delete(recursive: true));

    final v1Db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE clients (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              surname TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE materials (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              clientId INTEGER NOT NULL,
              name TEXT NOT NULL,
              quantity REAL NOT NULL,
              unitPrice REAL NOT NULL,
              date TEXT NOT NULL,
              FOREIGN KEY (clientId) REFERENCES clients (id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );
    final clientId = await v1Db.insert('clients', {'name': 'Mario', 'surname': 'Rossi'});
    final materialId = await v1Db.insert('materials', {
      'clientId': clientId,
      'name': 'Cement',
      'quantity': 3.0,
      'unitPrice': 15.0,
      'date': DateTime(2026, 7, 20).toIso8601String(),
    });
    await v1Db.close();

    final upgraded = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute(
              'ALTER TABLE materials ADD COLUMN paid INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      ),
    );

    final rows = await upgraded.query('materials', where: 'id = ?', whereArgs: [materialId]);
    expect(rows.first['paid'], 0);
    expect(rows.first['name'], 'Cement');

    await upgraded.close();
  });
}
