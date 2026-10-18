import 'package:flutter/foundation.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/models/client.dart';

class ClientWithTotal {
  final Client client;
  final double total;

  ClientWithTotal(this.client, this.total);
}

class ClientProvider extends ChangeNotifier {
  final ClientRepository _repo;

  ClientProvider(this._repo, {int? initialYear})
      : selectedYear = initialYear ?? DateTime.now().year;

  List<ClientWithTotal> clients = [];

  /// Year the totals are restricted to; null means all years.
  int? selectedYear;

  /// Years offered in the selector, newest first (always includes the
  /// current year and the selected one).
  List<int> years = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadClients() async {
    isLoading = true;
    notifyListeners();

    try {
      final all = await _repo.getAllClients();
      final withTotals = <ClientWithTotal>[];
      for (final client in all) {
        final total = await _repo.getTotalSpentForClient(client.id!, year: selectedYear);
        withTotals.add(ClientWithTotal(client, total));
      }
      final yearSet = {
        ...await _repo.getMaterialYears(),
        DateTime.now().year,
        ?selectedYear,
      };
      years = yearSet.toList()..sort((a, b) => b.compareTo(a));
      clients = withTotals;
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectYear(int? year) async {
    selectedYear = year;
    await loadClients();
  }

  Future<void> addClient(Client client) async {
    try {
      await _repo.insertClient(client);
      errorMessage = null;
      await loadClients();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> editClient(Client client) async {
    try {
      await _repo.updateClient(client);
      errorMessage = null;
      await loadClients();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> deleteClient(int id) async {
    try {
      await _repo.deleteClient(id);
      errorMessage = null;
      await loadClients();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  /// Clears a surfaced error (e.g. after it has been shown in a SnackBar)
  /// so the same message doesn't re-trigger on the next rebuild. No
  /// listeners currently render based on the absence of an error, so this
  /// does not call notifyListeners().
  void clearError() {
    errorMessage = null;
  }
}
