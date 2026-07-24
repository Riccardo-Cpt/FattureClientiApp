import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/client.dart';
import 'package:spese_cliente_app/widgets/client_form.dart';

void main() {
  testWidgets('submitting blank name shows validation error and does not call onSubmit', (tester) async {
    Client? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClientForm(onSubmit: (c) => submitted = c),
      ),
    ));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('submitting valid name and surname calls onSubmit with trimmed values', (tester) async {
    Client? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClientForm(onSubmit: (c) => submitted = c),
      ),
    ));

    await tester.enterText(find.byKey(const Key('client_name_field')), ' Mario ');
    await tester.enterText(find.byKey(const Key('client_surname_field')), ' Rossi ');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.name, 'Mario');
    expect(submitted?.surname, 'Rossi');
  });

  testWidgets('pre-fills fields and preserves id when editing', (tester) async {
    Client? submitted;
    final initial = Client(id: 7, name: 'Anna', surname: 'Bianchi');

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ClientForm(initial: initial, onSubmit: (c) => submitted = c),
      ),
    ));

    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Bianchi'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.id, 7);
  });
}
