// Statut possible d'une prise
enum StatutPrise { prise, ignoree, snoozee }

class Prise {
  final int? id;
  final int medicamentId;
  final String medicamentNom;   // dénormalisé pour l'affichage
  final String medicamentIcone;
  final StatutPrise statut;
  final DateTime datePrevue;    // heure prévue
  final DateTime? datePrise;    // heure réelle de confirmation
  final int? snoozeMinutes;     // durée du snooze si applicable

  Prise({
    this.id,
    required this.medicamentId,
    required this.medicamentNom,
    required this.medicamentIcone,
    required this.statut,
    required this.datePrevue,
    this.datePrise,
    this.snoozeMinutes,
  });

  // Convertir en Map pour sqflite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicament_id': medicamentId,
      'medicament_nom': medicamentNom,
      'medicament_icone': medicamentIcone,
      'statut': statut.name,           // "prise", "ignoree", "snoozee"
      'date_prevue': datePrevue.toIso8601String(),
      'date_prise': datePrise?.toIso8601String(),
      'snooze_minutes': snoozeMinutes,
    };
  }

  // Créer depuis une Map sqflite
  factory Prise.fromMap(Map<String, dynamic> map) {
    return Prise(
      id: map['id'] as int?,
      medicamentId: map['medicament_id'] as int,
      medicamentNom: map['medicament_nom'] as String,
      medicamentIcone: map['medicament_icone'] as String,
      statut: StatutPrise.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => StatutPrise.ignoree,
      ),
      datePrevue: DateTime.parse(map['date_prevue'] as String),
      datePrise: map['date_prise'] != null
          ? DateTime.parse(map['date_prise'] as String)
          : null,
      snoozeMinutes: map['snooze_minutes'] as int?,
    );
  }

  // Copie avec modifications
  Prise copyWith({
    int? id,
    int? medicamentId,
    String? medicamentNom,
    String? medicamentIcone,
    StatutPrise? statut,
    DateTime? datePrevue,
    DateTime? datePrise,
    int? snoozeMinutes,
  }) {
    return Prise(
      id: id ?? this.id,
      medicamentId: medicamentId ?? this.medicamentId,
      medicamentNom: medicamentNom ?? this.medicamentNom,
      medicamentIcone: medicamentIcone ?? this.medicamentIcone,
      statut: statut ?? this.statut,
      datePrevue: datePrevue ?? this.datePrevue,
      datePrise: datePrise ?? this.datePrise,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}
