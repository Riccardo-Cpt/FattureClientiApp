import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/screens/client_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/material_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    // Use the no-isolate factory: the isolate-based factory's real async I/O
    // never resolves inside flutter_test's FakeAsync zone, which would hang
    // pumpAndSettle() indefinitely in these widget tests.
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  testWidgets('shows empty state, then an added material with running total', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final clientRepo = ClientRepository(helper);
    final materialRepo = MaterialRepository(helper);
    final clientId = await clientRepo.insertClient(Client(name: 'Mario', surname: 'Rossi'));
    final client = Client(id: clientId, name: 'Mario', surname: 'Rossi');

    await tester.pumpWidget(
      Provider<MaterialRepository>.value(
        value: materialRepo,
        child: MaterialApp(home: ClientDetailScreen(client: client)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No materials yet for this client.'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('material_name_field')), 'Cement');
    await tester.enterText(find.byKey(const Key('material_quantity_field')), '3');
    await tester.enterText(find.byKey(const Key('material_unit_price_field')), '15');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Cement'), findsOneWidget);
    expect(find.textContaining('45.00'), findsWidgets);

    await helper.close();
  });
}
