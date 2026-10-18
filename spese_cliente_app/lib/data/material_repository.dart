import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/models/material_item.dart';

class MaterialRepository {
  final DatabaseHelper _helper;

  MaterialRepository(this._helper);

  Future<int> insertMaterial(MaterialItem item) async {
    final db = await _helper.database;
    return db.insert('materials', item.toMap());
  }

  Future<List<MaterialItem>> getMaterialsForClient(int clientId) async {
    final db = await _helper.database;
    final rows = await db.query(
      'materials',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    return rows.map(MaterialItem.fromMap).toList();
  }

  Future<List<MaterialItem>> getAllMaterials() async {
    final db = await _helper.database;
    final rows = await db.query('materials', orderBy: 'date DESC');
    return rows.map(MaterialItem.fromMap).toList();
  }

  Future<void> updateMaterial(MaterialItem item) async {
    final db = await _helper.database;
    await db.update(
      'materials',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteMaterial(int id) async {
    final db = await _helper.database;
    await db.delete('materials', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setPaid(int id, bool paid) async {
    final db = await _helper.database;
    await db.update(
      'materials',
      {'paid': paid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
