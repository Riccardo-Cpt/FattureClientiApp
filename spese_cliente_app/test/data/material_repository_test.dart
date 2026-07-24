import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late ClientRepository clientRepo;
  late MaterialRepository materialRepo;
  late int clientId;

  setUp(() async {
    helper = DatabaseHelper(inMemory: true);
    clientRepo = ClientRepository(helper);
    materialRepo = MaterialRepository(helper);
    clientId = await clientRepo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
  });

  tearDown(() async {
    await helper.close();
  });

  test('insertMaterial returns a positive id', () async {
    final id = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    expect(id, greaterThan(0));
  });

  test('getMaterialsForClient returns only that client materials, newest first', () async {
    await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 1),
    ));
    await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: DateTime(2026, 7, 20),
    ));

    final otherClientId = await clientRepo.insertClient(Client(name: 'Anna', surname: 'Bianchi'));
    await materialRepo.insertMaterial(MaterialItem(
      clientId: otherClientId,
      name: 'Sand',
      quantity: 1,
      unitPrice: 5,
      date: DateTime(2026, 7, 10),
    ));

    final results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.length, 2);
    expect(results.first.name, 'Bricks');
    expect(results.last.name, 'Cement');
  });

  test('updateMaterial persists changes', () async {
    final id = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    await materialRepo.updateMaterial(MaterialItem(
      id: id,
      clientId: clientId,
      name: 'Cement',
      quantity: 5,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    final results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.first.quantity, 5.0);
    expect(results.first.totalPrice, 75.0);
  });

  test('deleteMaterial removes only that entry', () async {
    final keepId = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    final removeId = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: DateTime(2026, 7, 21),
    ));

    await materialRepo.deleteMaterial(removeId);

    final results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.length, 1);
    expect(results.first.id, keepId);
  });

  test('setPaid marks a material as paid, and can unmark it', () async {
    final id = await materialRepo.insertMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    await materialRepo.setPaid(id, true);
    var results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.first.paid, isTrue);

    await materialRepo.setPaid(id, false);
    results = await materialRepo.getMaterialsForClient(clientId);
    expect(results.first.paid, isFalse);
  });
}
