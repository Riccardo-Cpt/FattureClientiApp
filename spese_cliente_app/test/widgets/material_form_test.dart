import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/material_item.dart';
import 'package:spese_cliente_app/widgets/material_form.dart';

void main() {
  testWidgets('submitting blank name shows validation error and does not call onSubmit', (tester) async {
    MaterialItem? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, onSubmit: (m) => submitted = m),
      ),
    ));

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('Required'), findsWidgets);
  });

  testWidgets('non-positive quantity is rejected', (tester) async {
    MaterialItem? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, onSubmit: (m) => submitted = m),
      ),
    ));

    await tester.enterText(find.byKey(const Key('material_name_field')), 'Cement');
    await tester.enterText(find.byKey(const Key('material_quantity_field')), '0');
    await tester.enterText(find.byKey(const Key('material_unit_price_field')), '15');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted, isNull);
    expect(find.text('Must be greater than 0'), findsOneWidget);
  });

  testWidgets('valid input computes live total and calls onSubmit', (tester) async {
    MaterialItem? submitted;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, onSubmit: (m) => submitted = m),
      ),
    ));

    await tester.enterText(find.byKey(const Key('material_name_field')), 'Cement');
    await tester.enterText(find.byKey(const Key('material_quantity_field')), '3');
    await tester.enterText(find.byKey(const Key('material_unit_price_field')), '15');
    await tester.pump();

    expect(find.text('Total: 45.00'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.name, 'Cement');
    expect(submitted?.quantity, 3.0);
    expect(submitted?.unitPrice, 15.0);
    expect(submitted?.clientId, 1);
    expect(submitted?.totalPrice, 45.0);
  });

  testWidgets('pre-fills fields and preserves id when editing', (tester) async {
    MaterialItem? submitted;
    final initial = MaterialItem(
      id: 9,
      clientId: 1,
      name: 'Bricks',
      quantity: 10,
      unitPrice: 2.5,
      date: DateTime(2026, 7, 20),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MaterialForm(clientId: 1, initial: initial, onSubmit: (m) => submitted = m),
      ),
    ));

    expect(find.text('Bricks'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submitted?.id, 9);
  });
}
