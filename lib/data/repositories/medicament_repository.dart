import 'package:flutter/material.dart';

import '../models/medicament.dart';
import '../database/medicament_dao.dart';

class MedicamentRepository extends ChangeNotifier {
  final _dao = MedicamentDao();

  List<Medicament> _medicaments = [];
  List<Medicament> get medicaments => _medicaments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Charger tous les médicaments actifs
  Future<void> charger() async {
    _isLoading = true;
    notifyListeners();

    _medicaments = await _dao.findAllActifs();

    _isLoading = false;
    notifyListeners();
  }

  // Ajouter un médicament
  Future<void> ajouter(Medicament med) async {
    await _dao.insert(med);
    await charger();
  }

  // Modifier un médicament
  Future<void> modifier(Medicament med) async {
    await _dao.update(med);
    await charger();
  }

  // Supprimer (désactiver)
  Future<void> supprimer(int id) async {
    await _dao.desactiver(id);
    await charger();
  }

  // Mettre à jour le stock
  Future<void> mettreAJourStock(int id, int nouveauStock) async {
    await _dao.updateStock(id, nouveauStock);
    await charger();
  }

  // Décrémenter le stock après prise confirmée
  Future<void> decrementerStock(int id) async {
    await _dao.decrementerStock(id);
    await charger();
  }

  // Médicaments avec stock bas
  Future<List<Medicament>> getStockBas() async {
    return await _dao.findStockBas();
  }

  // Trouver par ID
  Medicament? findById(int id) {
    try {
      return _medicaments.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
