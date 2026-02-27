import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

import '../data/models/utilisateur.dart';
import '../data/database/utilisateur_dao.dart';

class AuthService extends ChangeNotifier {
  final _dao = UtilisateurDao();

  Utilisateur? _utilisateurConnecte;
  bool get isLoggedIn => _utilisateurConnecte != null;
  Utilisateur? get utilisateurConnecte => _utilisateurConnecte;

  // ─── Hashage SHA-256 ───────────────────────────────────────────
  String _hash(String value) {
    final bytes = utf8.encode(value.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  // ─── Inscription ───────────────────────────────────────────────
  Future<AuthResult> inscrire({
    required String username,
    required String password,
    required String nomComplet,
    required String secretQuestion,
    required String secretAnswer,
  }) async {
    // Validation
    if (username.trim().isEmpty)
      return AuthResult.error('Le nom d\'utilisateur est requis.');
    if (username.trim().length < 3)
      return AuthResult.error(
          'Le nom d\'utilisateur doit faire au moins 3 caractères.');
    if (password.length < 6)
      return AuthResult.error(
          'Le mot de passe doit faire au moins 6 caractères.');
    if (nomComplet.trim().isEmpty)
      return AuthResult.error('Le nom complet est requis.');
    if (secretAnswer.trim().isEmpty)
      return AuthResult.error('La réponse secrète est requise.');

    try {
      // Vérifier si username déjà pris
      final existe = await _dao.usernameExists(username.trim().toLowerCase());
      if (existe)
        return AuthResult.error('Ce nom d\'utilisateur est déjà pris.');

      // Créer l'utilisateur avec mots de passe hashés
      final user = Utilisateur(
        username: username.trim().toLowerCase(),
        passwordHash: _hash(password),
        secretQuestion: secretQuestion,
        secretAnswerHash: _hash(secretAnswer),
        nomComplet: nomComplet.trim(),
        dateCreation: DateTime.now(),
      );

      await _dao.insert(user);
      return AuthResult.success();
    } catch (e) {
      // Erreur de base de données - retourne un message clair
      debugPrint('Erreur inscription: $e');
      return AuthResult.error(
          'Erreur lors de la création du compte. Veuillez réessayer.');
    }
  }

  // ─── Connexion ─────────────────────────────────────────────────
  Future<AuthResult> connecter({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return AuthResult.error('Veuillez remplir tous les champs.');
    }

    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null)
        return AuthResult.error(
            'Nom d\'utilisateur ou mot de passe incorrect.');

      if (user.passwordHash != _hash(password)) {
        return AuthResult.error(
            'Nom d\'utilisateur ou mot de passe incorrect.');
      }

      _utilisateurConnecte = user;
      notifyListeners();
      return AuthResult.success();
    } catch (e) {
      debugPrint('Erreur connexion: $e');
      return AuthResult.error('Erreur de connexion. Veuillez réessayer.');
    }
  }

  // ─── Déconnexion ───────────────────────────────────────────────
  void deconnecter() {
    _utilisateurConnecte = null;
    notifyListeners();
  }

  // ─── Récupération mot de passe ─────────────────────────────────

  // Étape 1 : vérifier que le username existe
  Future<AuthResult> verifierUsername(String username) async {
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null)
        return AuthResult.error(
            'Aucun compte trouvé avec ce nom d\'utilisateur.');
      return AuthResult.success(data: user);
    } catch (e) {
      return AuthResult.error('Erreur. Veuillez réessayer.');
    }
  }

  // Étape 2 : vérifier la réponse secrète
  Future<AuthResult> verifierReponseSecrete({
    required String username,
    required String reponse,
  }) async {
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null) return AuthResult.error('Compte introuvable.');

      if (user.secretAnswerHash != _hash(reponse)) {
        return AuthResult.error('Réponse incorrecte.');
      }

      return AuthResult.success(data: user);
    } catch (e) {
      return AuthResult.error('Erreur. Veuillez réessayer.');
    }
  }

  // Étape 3 : enregistrer le nouveau mot de passe
  Future<AuthResult> reinitialiserMotDePasse({
    required String username,
    required String nouveauPassword,
  }) async {
    if (nouveauPassword.length < 6) {
      return AuthResult.error(
          'Le mot de passe doit faire au moins 6 caractères.');
    }

    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null) return AuthResult.error('Compte introuvable.');

      await _dao.updatePassword(user.id!, _hash(nouveauPassword));
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Erreur. Veuillez réessayer.');
    }
  }

  // ─── Récupérer la question secrète d'un utilisateur ────────────
  Future<String?> getSecretQuestion(String username) async {
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      return user?.secretQuestion;
    } catch (e) {
      return null;
    }
  }
}

// ─── Classe résultat ───────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String? errorMessage;
  final dynamic data;

  AuthResult._({required this.success, this.errorMessage, this.data});

  factory AuthResult.success({dynamic data}) =>
      AuthResult._(success: true, data: data);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, errorMessage: message);
}
