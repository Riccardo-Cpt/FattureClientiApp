import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/providers/client_detail_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper helper;
  late int clientId;
  late ClientDetailProvider provider;

  setUp(() async {
    helper = DatabaseHelper(inMemory: true);
    final clientId0 = await ClientRepository(helper).insertClient(
      Client(name: 'Mario', surname: 'Rossi'),
    );
    clientId = clientId0;
    provider = ClientDetailProvider(MaterialRepository(helper), clientId);
  });

  tearDown(() async {
    await helper.close();
  });

  test('loadMaterials starts empty, totalSpent is 0.0', () async {
    await provider.loadMaterials();
    expect(provider.materials, isEmpty);
    expect(provider.totalSpent, 0.0);
  });

  test('addMaterial adds it and updates totalSpent', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));

    expect(provider.materials.length, 1);
    expect(provider.totalSpent, 45.0);
  });

  test('editMaterial updates quantity and totalSpent', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    final item = provider.materials.first;

    await provider.editMaterial(item.copyWith(quantity: 5));

    expect(provider.materials.first.quantity, 5.0);
    expect(provider.totalSpent, 75.0);
  });

  test('deleteMaterial removes it and updates totalSpent', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    final id = provider.materials.first.id!;

    await provider.deleteMaterial(id);

    expect(provider.materials, isEmpty);
    expect(provider.totalSpent, 0.0);
  });

  test('togglePaid marks a material paid and excludes it from totalSpent', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: DateTime(2026, 7, 21),
    ));
    expect(provider.totalSpent, 70.0);

    final cement = provider.materials.firstWhere((m) => m.name == 'Cement');
    await provider.togglePaid(cement);

    expect(provider.materials.firstWhere((m) => m.name == 'Cement').paid, isTrue);
    expect(provider.totalSpent, 25.0);
  });

  test('togglePaid can unmark a material as paid', () async {
    await provider.addMaterial(MaterialItem(
      clientId: clientId,
      name: 'Cement',
      quantity: 3,
      unitPrice: 15,
      date: DateTime(2026, 7, 20),
    ));
    final item = provider.materials.first;

    await provider.togglePaid(item);
    expect(provider.materials.first.paid, isTrue);

    await provider.togglePaid(provider.materials.first);
    expect(provider.materials.first.paid, isFalse);
    expect(provider.totalSpent, 45.0);
  });
}
