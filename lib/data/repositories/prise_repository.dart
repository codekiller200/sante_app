import 'package:flutter/material.dart';

import '../models/prise.dart';
import '../database/prise_dao.dart';

class PriseRepository extends ChangeNotifier {
  final _dao = PriseDao();

  List<Prise> _prisesAujourdhui = [];
  List<Prise> get prisesAujourdhui => _prisesAujourdhui;

  List<Prise> _prisesDuMois = [];
  List<Prise> get prisesDuMois => _prisesDuMois;

  double _observance = 0.0;
  double get observance => _observance;

  // Charger les prises d'aujourd'hui
  Future<void> chargerAujourdhui() async {
    _prisesAujourdhui = await _dao.findByDate(DateTime.now());
    notifyListeners();
  }

  // Charger les prises du mois
  Future<void> chargerMois(int year, int month) async {
    _prisesDuMois = await _dao.findByMonth(year, month);
    _observance   = await _dao.calculerObservance(year, month);
    notifyListeners();
  }

  // Enregistrer une prise
  Future<void> enregistrer(Prise prise) async {
    await _dao.insert(prise);
    await chargerAujourdhui();
  }

  // Confirmer une prise (marquer comme "prise")
  Future<void> confirmer(Prise prise) async {
    final updated = prise.copyWith(
      statut: StatutPrise.prise,
      datePrise: DateTime.now(),
    );
    await _dao.update(updated);
    await chargerAujourdhui();
  }

  // Ignorer une prise
  Future<void> ignorer(Prise prise) async {
    final updated = prise.copyWith(statut: StatutPrise.ignoree);
    await _dao.update(updated);
    await chargerAujourdhui();
  }

  // Snoozer une prise
  Future<void> snoozer(Prise prise, int minutes) async {
    final updated = prise.copyWith(
      statut: StatutPrise.snoozee,
      snoozeMinutes: minutes,
      datePrevue: prise.datePrevue.add(Duration(minutes: minutes)),
    );
    await _dao.update(updated);
    await chargerAujourdhui();
  }

  // Prochaine prise
  Future<Prise?> getProchainePrise() async {
    return await _dao.findProchainePrise();
  }

  // Taux d'observance en %
  String get observanceFormatee => '${_observance.toStringAsFixed(0)}%';
}
