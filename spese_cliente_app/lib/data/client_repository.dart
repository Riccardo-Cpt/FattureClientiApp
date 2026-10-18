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

  /// Unpaid total for a client, optionally restricted to a calendar [year].
  Future<double> getTotalSpentForClient(int clientId, {int? year}) async {
    final db = await _helper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity * unitPrice) as total FROM materials '
      'WHERE clientId = ? AND paid = 0'
      '${year == null ? '' : " AND substr(date, 1, 4) = ?"}',
      [clientId, if (year != null) year.toString().padLeft(4, '0')],
    );
    final total = result.first['total'] as double?;
    return total ?? 0.0;
  }

  /// Distinct years that have at least one material, newest first.
  Future<List<int>> getMaterialYears() async {
    final db = await _helper.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT substr(date, 1, 4) as year FROM materials ORDER BY year DESC',
    );
    return rows
        .map((r) => int.tryParse(r['year'] as String? ?? ''))
        .whereType<int>()
        .toList();
  }
}
