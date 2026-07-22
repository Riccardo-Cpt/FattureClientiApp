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

  ClientProvider(this._repo);

  List<ClientWithTotal> clients = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadClients() async {
    isLoading = true;
    notifyListeners();

    try {
      final all = await _repo.getAllClients();
      final withTotals = <ClientWithTotal>[];
      for (final client in all) {
        final total = await _repo.getTotalSpentForClient(client.id!);
        withTotals.add(ClientWithTotal(client, total));
      }
      clients = withTotals;
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
    } finally {
      isLoading = false;
      notifyListeners();
    }
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
}
