class Utilisateur {
  final int? id;
  final String username;
  final String passwordHash;
  final String secretQuestion;
  final String secretAnswerHash;
  final String nomComplet;
  final DateTime dateCreation;

  // ── Nouveaux champs profil ──────────────────────────────────────
  /// Chemin local vers la photo choisie dans la galerie (null = emoji)
  final String? avatarPath;

  /// Emoji avatar si pas de photo (ex: '🧑', '👩', '🧔')
  final String avatarEmoji;

  /// Date de naissance
  final DateTime? dateNaissance;

  /// Nom du médecin traitant
  final String? medecinTraitant;

  /// Informations d'urgence (groupe sanguin, allergies, antécédents…)
  final String? groupeSanguin;
  final String? allergies;
  final String? antecedents;

  Utilisateur({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.secretQuestion,
    required this.secretAnswerHash,
    required this.nomComplet,
    required this.dateCreation,
    this.avatarPath,
    this.avatarEmoji = '🧑',
    this.dateNaissance,
    this.medecinTraitant,
    this.groupeSanguin,
    this.allergies,
    this.antecedents,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'secret_question': secretQuestion,
      'secret_answer_hash': secretAnswerHash,
      'nom_complet': nomComplet,
      'date_creation': dateCreation.toIso8601String(),
      'avatar_path': avatarPath,
      'avatar_emoji': avatarEmoji,
      'date_naissance': dateNaissance?.toIso8601String(),
      'medecin_traitant': medecinTraitant,
      'groupe_sanguin': groupeSanguin,
      'allergies': allergies,
      'antecedents': antecedents,
    };
  }

  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] as int?,
      username: map['username'] as String? ?? (throw ArgumentError('Missing username')),
      passwordHash: map['password_hash'] as String,
      secretQuestion: map['secret_question'] as String,
      secretAnswerHash: map['secret_answer_hash'] as String,
      nomComplet: map['nom_complet'] as String,
      dateCreation: DateTime.parse(map['date_creation'] as String),
      avatarPath: map['avatar_path'] as String?,
      avatarEmoji: (map['avatar_emoji'] as String?) ?? '🧑',
      dateNaissance: map['date_naissance'] != null
          ? DateTime.parse(map['date_naissance'] as String)
          : null,
      medecinTraitant: map['medecin_traitant'] as String?,
      groupeSanguin: map['groupe_sanguin'] as String?,
      allergies: map['allergies'] as String?,
      antecedents: map['antecedents'] as String?,
    );
  }

  Utilisateur copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? secretQuestion,
    String? secretAnswerHash,
    String? nomComplet,
    DateTime? dateCreation,
    String? avatarPath,
    String? avatarEmoji,
    DateTime? dateNaissance,
    String? medecinTraitant,
    String? groupeSanguin,
    String? allergies,
    String? antecedents,
    // Permet de mettre avatarPath à null explicitement
    bool clearAvatarPath = false,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      secretQuestion: secretQuestion ?? this.secretQuestion,
      secretAnswerHash: secretAnswerHash ?? this.secretAnswerHash,
      nomComplet: nomComplet ?? this.nomComplet,
      dateCreation: dateCreation ?? this.dateCreation,
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      medecinTraitant: medecinTraitant ?? this.medecinTraitant,
      groupeSanguin: groupeSanguin ?? this.groupeSanguin,
      allergies: allergies ?? this.allergies,
      antecedents: antecedents ?? this.antecedents,
    );
  }

  /// Résumé des infos d'urgence pour l'affichage
  String get resumeUrgences {
    final parts = <String>[
      if (groupeSanguin != null && groupeSanguin!.isNotEmpty)
        'Groupe $groupeSanguin',
      if (allergies != null && allergies!.isNotEmpty) allergies!,
      if (antecedents != null && antecedents!.isNotEmpty) antecedents!,
    ];
    return parts.join(' · ');
  }

  bool get hasUrgences =>
      (groupeSanguin?.isNotEmpty ?? false) ||
      (allergies?.isNotEmpty ?? false) ||
      (antecedents?.isNotEmpty ?? false);
}
