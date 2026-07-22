import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late ClientProvider provider;
  late MaterialRepository materialRepo;

  setUp(() {
    helper = DatabaseHelper(inMemory: true);
    provider = ClientProvider(ClientRepository(helper));
    materialRepo = MaterialRepository(helper);
  });

  tearDown(() async {
    await helper.close();
  });

  test('loadClients starts empty, then populates after addClient', () async {
    await provider.loadClients();
    expect(provider.clients, isEmpty);

    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));

    expect(provider.clients.length, 1);
    expect(provider.clients.first.client.name, 'Mario');
    expect(provider.clients.first.total, 0.0);
  });

  test('addClient total reflects that client materials sum', () async {
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));
    final clientId = provider.clients.first.client.id!;

    await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    await provider.loadClients();

    expect(provider.clients.first.total, 45.0);
  });

  test('editClient updates the stored client', () async {
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));
    final client = provider.clients.first.client;

    await provider.editClient(Client(id: client.id, name: 'Mario', surname: 'Verdi'));

    expect(provider.clients.first.client.surname, 'Verdi');
  });

  test('deleteClient removes it from the list', () async {
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));
    final id = provider.clients.first.client.id!;

    await provider.deleteClient(id);

    expect(provider.clients, isEmpty);
  });
}
