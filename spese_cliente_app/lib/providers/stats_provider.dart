import 'package:flutter/foundation.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/expense_stats.dart';
import 'package:spese_cliente_app/models/material_item.dart';

class StatsProvider extends ChangeNotifier {
  final MaterialRepository _materials;
  final ClientRepository _clients;

  StatsProvider(this._materials, this._clients, {int? initialYear})
      : selectedYear = initialYear ?? DateTime.now().year;

  List<MaterialItem> _all = [];
  Map<int, String> _clientNames = {};

  /// Null means all years.
  int? selectedYear;

  /// 1-based month highlighted in the chart; only meaningful for a single year.
  int? selectedMonth;

  bool isLoading = false;
  bool hasError = false;

  List<int> get years {
    final set = {for (final i in _all) i.date.year, DateTime.now().year, ?selectedYear};
    return set.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Statistics over the selected year (or everything).
  ExpenseStats get stats {
    final items = selectedYear == null
        ? _all
        : _all.where((i) => i.date.year == selectedYear).toList();
    return ExpenseStats(items, _clientNames, monthsCount: _monthsCount(items));
  }

  /// Per-year totals across all data, for the "all years" chart.
  Map<int, double> get yearlyTotals => ExpenseStats(_all, _clientNames).yearlyTotals;

  /// Items of the selected month within the selected year.
  List<MaterialItem> get monthItems =>
      selectedMonth == null ? const [] : stats.itemsForMonth(selectedMonth!);

  String clientName(int clientId) => _clientNames[clientId] ?? '?';

  int _monthsCount(List<MaterialItem> items) {
    final now = DateTime.now();
    if (selectedYear != null) {
      if (selectedYear == now.year) return now.month;
      return 12;
    }
    if (items.isEmpty) return 0;
    final first = items.map((i) => i.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final months = (now.year - first.year) * 12 + now.month - first.month + 1;
    return months < 1 ? 1 : months;
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      _all = await _materials.getAllMaterials();
      final clients = await _clients.getAllClients();
      _clientNames = {for (final c in clients) c.id!: '${c.name} ${c.surname}'};
      hasError = false;
    } catch (_) {
      hasError = true;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectYear(int? year) {
    selectedYear = year;
    selectedMonth = null;
    notifyListeners();
  }

  void selectMonth(int? month) {
    selectedMonth = selectedMonth == month ? null : month;
    notifyListeners();
  }
}
