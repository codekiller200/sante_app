class Medicament {
  final int? id;
  final String nom;
  final String dosage;
  final String icone;           // ex: "💊"
  final int frequenceParJour;   // 1, 2, 3...
  final List<String> horaires;  // ex: ["08:00", "12:00", "20:00"]
  final int stockActuel;        // nombre de comprimés restants
  final int seuilAlerte;        // alerte si stock <= seuilAlerte jours
  final bool estActif;
  final DateTime dateCreation;

  Medicament({
    this.id,
    required this.nom,
    required this.dosage,
    required this.icone,
    required this.frequenceParJour,
    required this.horaires,
    required this.stockActuel,
    this.seuilAlerte = 7,
    this.estActif = true,
    required this.dateCreation,
  });

  // Jours restants selon stock et fréquence
  int get joursRestants {
    if (frequenceParJour <= 0) return 0;
    return (stockActuel / frequenceParJour).floor();
  }

  // Vrai si le stock est bas
  bool get stockBas => joursRestants <= seuilAlerte;

  // Convertir en Map pour sqflite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'dosage': dosage,
      'icone': icone,
      'frequence_par_jour': frequenceParJour,
      'horaires': horaires.join(','),  // "08:00,12:00,20:00"
      'stock_actuel': stockActuel,
      'seuil_alerte': seuilAlerte,
      'est_actif': estActif ? 1 : 0,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  // Créer depuis une Map sqflite
  factory Medicament.fromMap(Map<String, dynamic> map) {
    return Medicament(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      dosage: map['dosage'] as String,
      icone: map['icone'] as String,
      frequenceParJour: map['frequence_par_jour'] as int,
      horaires: (map['horaires'] as String).split(','),
      stockActuel: map['stock_actuel'] as int,
      seuilAlerte: map['seuil_alerte'] as int,
      estActif: (map['est_actif'] as int) == 1,
      dateCreation: DateTime.parse(map['date_creation'] as String),
    );
  }

  // Copie avec modifications
  Medicament copyWith({
    int? id,
    String? nom,
    String? dosage,
    String? icone,
    int? frequenceParJour,
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
      horaires: horaires ?? this.horaires,
      stockActuel: stockActuel ?? this.stockActuel,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      estActif: estActif ?? this.estActif,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
