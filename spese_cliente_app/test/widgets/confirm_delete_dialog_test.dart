import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/widgets/confirm_delete_dialog.dart';

void main() {
  testWidgets('tapping Delete resolves true', (tester) async {
    bool? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDeleteDialog(
                context,
                title: 'Delete client',
                message: 'Are you sure?',
              );
            },
            child: const Text('Trigger'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('tapping Cancel resolves false', (tester) async {
    bool? result;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showConfirmDeleteDialog(
                context,
                title: 'Delete client',
                message: 'Are you sure?',
              );
            },
            child: const Text('Trigger'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Trigger'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
