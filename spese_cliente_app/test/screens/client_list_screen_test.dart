import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spese_cliente_app/data/database_helper.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/providers/client_provider.dart';
import 'package:spese_cliente_app/screens/client_list_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    // Use the no-isolate factory: the isolate-based factory's real async I/O
    // never resolves inside flutter_test's FakeAsync zone, which would hang
    // pumpAndSettle() indefinitely in these widget tests.
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  Widget buildTestable(ClientProvider provider) {
    return ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(home: ClientListScreen()),
    );
  }

  testWidgets('shows empty state when there are no clients', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final provider = ClientProvider(ClientRepository(helper));

    await tester.pumpWidget(buildTestable(provider));
    await tester.pumpAndSettle();

    expect(find.text('No clients yet — tap + to add one.'), findsOneWidget);

    await helper.close();
  });

  testWidgets('adding a client through the FAB dialog shows it in the list', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final provider = ClientProvider(ClientRepository(helper));

    await tester.pumpWidget(buildTestable(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('client_name_field')), 'Mario');
    await tester.enterText(find.byKey(const Key('client_surname_field')), 'Rossi');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Mario Rossi'), findsOneWidget);

    await helper.close();
  });

  testWidgets('deleting a client requires confirmation', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final provider = ClientProvider(ClientRepository(helper));
    await provider.addClient(Client(name: 'Mario', surname: 'Rossi'));

    await tester.pumpWidget(buildTestable(provider));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Mario Rossi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('Mario Rossi'), findsNothing);
    expect(find.text('No clients yet — tap + to add one.'), findsOneWidget);

    await helper.close();
  });

  testWidgets('a failed add shows the generic error snackbar', (tester) async {
    final helper = DatabaseHelper(inMemory: true);
    final provider = ClientProvider(ClientRepository(helper));

    await tester.pumpWidget(buildTestable(provider));
    await tester.pumpAndSettle();

    // Force the next database operation to fail by dropping the underlying
    // table out from under the repository.
    final db = await helper.database;
    await db.execute('DROP TABLE clients');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('client_name_field')), 'Mario');
    await tester.enterText(find.byKey(const Key('client_surname_field')), 'Rossi');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong, please try again'), findsOneWidget);

    await helper.close();
  });
}
