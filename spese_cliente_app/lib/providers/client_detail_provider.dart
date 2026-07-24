import 'package:flutter/foundation.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/models/material_item.dart';

class ClientDetailProvider extends ChangeNotifier {
  final MaterialRepository _repo;
  final int clientId;

  ClientDetailProvider(this._repo, this.clientId);

  List<MaterialItem> materials = [];
  bool isLoading = false;
  String? errorMessage;

  double get totalSpent => materials
      .where((item) => !item.paid)
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  Future<void> loadMaterials() async {
    isLoading = true;
    notifyListeners();

    try {
      materials = await _repo.getMaterialsForClient(clientId);
      errorMessage = null;
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMaterial(MaterialItem item) async {
    try {
      await _repo.insertMaterial(item);
      errorMessage = null;
      await loadMaterials();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> editMaterial(MaterialItem item) async {
    try {
      await _repo.updateMaterial(item);
      errorMessage = null;
      await loadMaterials();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> deleteMaterial(int id) async {
    try {
      await _repo.deleteMaterial(id);
      errorMessage = null;
      await loadMaterials();
    } catch (_) {
      errorMessage = 'Something went wrong, please try again';
      notifyListeners();
    }
  }

  Future<void> togglePaid(MaterialItem item) async {
    try {
      await _repo.setPaid(item.id!, !item.paid);
      errorMessage = null;
      await loadMaterials();
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
