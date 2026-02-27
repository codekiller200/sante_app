class Utilisateur {
  final int? id;
  final String username;
  final String passwordHash;
  final String secretQuestion;
  final String secretAnswerHash;
  final String nomComplet;
  final DateTime dateCreation;

  Utilisateur({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.secretQuestion,
    required this.secretAnswerHash,
    required this.nomComplet,
    required this.dateCreation,
  });

  // Convertir en Map pour sqflite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'secret_question': secretQuestion,
      'secret_answer_hash': secretAnswerHash,
      'nom_complet': nomComplet,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  // Créer depuis une Map sqflite
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      secretQuestion: map['secret_question'] as String,
      secretAnswerHash: map['secret_answer_hash'] as String,
      nomComplet: map['nom_complet'] as String,
      dateCreation: DateTime.parse(map['date_creation'] as String),
    );
  }

  // Copie avec modifications
  Utilisateur copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? secretQuestion,
    String? secretAnswerHash,
    String? nomComplet,
    DateTime? dateCreation,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      secretQuestion: secretQuestion ?? this.secretQuestion,
      secretAnswerHash: secretAnswerHash ?? this.secretAnswerHash,
      nomComplet: nomComplet ?? this.nomComplet,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}
