import 'package:spese_cliente_app/models/material_item.dart';

/// Aggregated figures over a set of expenses (material entries).
class ExpenseStats {
  final List<MaterialItem> items;
  final Map<int, String> clientNames;

  /// Months over which [averagePerMonth] is computed.
  final int monthsCount;

  ExpenseStats(this.items, this.clientNames, {this.monthsCount = 12});

  double get total => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get paid => items.where((i) => i.paid).fold(0.0, (sum, i) => sum + i.totalPrice);
  double get unpaid => total - paid;
  int get count => items.length;
  double get averagePerMonth => monthsCount <= 0 ? 0 : total / monthsCount;

  /// Totals for months 1..12 (index 0 = January), summed across years.
  List<double> get monthlyTotals {
    final totals = List<double>.filled(12, 0);
    for (final item in items) {
      totals[item.date.month - 1] += item.totalPrice;
    }
    return totals;
  }

  /// 1-based month with the highest total, or null if there are no expenses.
  int? get bestMonth {
    final totals = monthlyTotals;
    var best = -1;
    for (var i = 0; i < 12; i++) {
      if (totals[i] > 0 && (best == -1 || totals[i] > totals[best])) best = i;
    }
    return best == -1 ? null : best + 1;
  }

  /// Items of the given 1-based [month], newest first.
  List<MaterialItem> itemsForMonth(int month) =>
      items.where((i) => i.date.month == month).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Clients ranked by total spent, highest first.
  List<MapEntry<String, double>> topClients([int limit = 5]) {
    final byClient = <int, double>{};
    for (final item in items) {
      byClient[item.clientId] = (byClient[item.clientId] ?? 0) + item.totalPrice;
    }
    final entries = byClient.entries
        .map((e) => MapEntry(clientNames[e.key] ?? '?', e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Totals per year across [items].
  Map<int, double> get yearlyTotals {
    final totals = <int, double>{};
    for (final item in items) {
      totals[item.date.year] = (totals[item.date.year] ?? 0) + item.totalPrice;
    }
    return totals;
  }
}
