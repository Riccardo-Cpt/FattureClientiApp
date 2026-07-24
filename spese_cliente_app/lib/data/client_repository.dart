import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/models/client.dart';

class ClientRepository {
  final DatabaseHelper _helper;

  ClientRepository(this._helper);

  Future<int> insertClient(Client client) async {
    final db = await _helper.database;
    return db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await _helper.database;
    final rows = await db.query('clients', orderBy: 'surname, name');
    return rows.map(Client.fromMap).toList();
  }

  Future<void> updateClient(Client client) async {
    final db = await _helper.database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(int id) async {
    final db = await _helper.database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getTotalSpentForClient(int clientId) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity * unitPrice) as total FROM materials WHERE clientId = ? AND paid = 0',
      [clientId],
    );
    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }
}
