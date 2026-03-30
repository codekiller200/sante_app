class Medicament {
  final int? id;
  final String nom;
  final String dosage;
  final String icone;
  final int frequenceParJour;
  final int intervalleJours;
  final List<String> horaires;
  final int stockActuel;
  final int seuilAlerte;
  final bool estActif;
  final DateTime dateCreation;

  Medicament({
    this.id,
    required this.nom,
    required this.dosage,
    required this.icone,
    required this.frequenceParJour,
    this.intervalleJours = 1,
    required this.horaires,
    required this.stockActuel,
    this.seuilAlerte = 7,
    this.estActif = true,
    required this.dateCreation,
  });

  int get joursRestants {
    if (frequenceParJour <= 0) return 0;
    return (stockActuel / frequenceParJour).floor();
  }

  bool get stockBas => joursRestants <= seuilAlerte;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'dosage': dosage,
      'icone': icone,
      'frequence_par_jour': frequenceParJour,
      'intervalle_jours': intervalleJours,
      'horaires': horaires.join(','),
      'stock_actuel': stockActuel,
      'seuil_alerte': seuilAlerte,
      'est_actif': estActif ? 1 : 0,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  factory Medicament.fromMap(Map<String, dynamic> map) {
    return Medicament(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      dosage: map['dosage'] as String,
      icone: map['icone'] as String,
      frequenceParJour: map['frequence_par_jour'] as int,
      intervalleJours: (map['intervalle_jours'] as int?) ?? 1,
      horaires: (map['horaires'] as String).split(','),
      stockActuel: map['stock_actuel'] as int,
      seuilAlerte: map['seuil_alerte'] as int,
      estActif: (map['est_actif'] as int) == 1,
      dateCreation: DateTime.parse(map['date_creation'] as String),
    );
  }

  Medicament copyWith({
    int? id,
    String? nom,
    String? dosage,
    String? icone,
    int? frequenceParJour,
    int? intervalleJours,
    List<String>? horaires,
    int? stockActuel,
    int? seuilAlerte,
    bool? estActif,
    DateTime? dateCreation,
  }) {
    return Medicament(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      dosage: dosage ?? this.dosage,
      icone: icone ?? this.icone,
      frequenceParJour: frequenceParJour ?? this.frequenceParJour,
      intervalleJours: intervalleJours ?? this.intervalleJours,
      horaires: horaires ?? this.horaires,
      stockActuel: stockActuel ?? this.stockActuel,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      estActif: estActif ?? this.estActif,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
