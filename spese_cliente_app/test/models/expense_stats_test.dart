import 'package:flutter_test/flutter_test.dart';
import 'package:spese_cliente_app/models/expense_stats.dart';
import 'package:spese_cliente_app/models/material_item.dart';

MaterialItem item(int clientId, DateTime date, double qty, double price, {bool paid = false}) =>
    MaterialItem(
      clientId: clientId,
      name: 'x',
      quantity: qty,
      unitPrice: price,
      date: date,
      paid: paid,
    );

void main() {
  final stats = ExpenseStats(
    [
      item(1, DateTime(2026, 1, 5), 2, 10),
      item(1, DateTime(2026, 3, 5), 1, 50, paid: true),
      item(2, DateTime(2026, 3, 20), 1, 5),
    ],
    {1: 'Mario Rossi', 2: 'Anna Bianchi'},
    monthsCount: 3,
  );

  test('totals', () {
    expect(stats.total, 75);
    expect(stats.paid, 50);
    expect(stats.unpaid, 25);
    expect(stats.averagePerMonth, 25);
  });

  test('monthly totals and best month', () {
    expect(stats.monthlyTotals[0], 20);
    expect(stats.monthlyTotals[2], 55);
    expect(stats.bestMonth, 3);
    expect(stats.itemsForMonth(3).length, 2);
  });

  test('top clients ranked by total', () {
    expect(stats.topClients().first.key, 'Mario Rossi');
    expect(stats.topClients().first.value, 70);
  });

  test('yearly totals', () {
    expect(stats.yearlyTotals, {2026: 75});
  });
}
