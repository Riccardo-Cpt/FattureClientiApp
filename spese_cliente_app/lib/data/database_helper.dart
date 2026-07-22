import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  final bool inMemory;
  Database? _db;

  DatabaseHelper({this.inMemory = false});

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = inMemory ? inMemoryDatabasePath : join(await getDatabasesPath(), 'spese_cliente.db');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
