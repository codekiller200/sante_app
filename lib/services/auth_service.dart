import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/utilisateur.dart';
import '../data/database/utilisateur_dao.dart';

class AuthService extends ChangeNotifier {
  final _dao = UtilisateurDao();

  Utilisateur? _utilisateurConnecte;
  bool _sessionChargee = false;

  bool get isLoggedIn => _utilisateurConnecte != null;
  bool get sessionChargee => _sessionChargee;
  Utilisateur? get utilisateurConnecte => _utilisateurConnecte;

  String _hash(String value) {
    final bytes = utf8.encode(value.trim().toLowerCase());
    return sha256.convert(bytes).toString();
  }

  // ── Session persistante ────────────────────────────────────────

  Future<void> restaurerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('session_username');
      if (username != null) {
        final user = await _dao.findByUsername(username);
        if (user != null) {
          final pinActif = prefs.getBool('pin_actif') ?? false;
          if (!pinActif) {
            _utilisateurConnecte = user;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur restauration session: $e');
    } finally {
      _sessionChargee = true;
      notifyListeners();
    }
  }

  Future<void> _sauvegarderSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_username', username);
  }

  Future<void> _supprimerSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_username');
  }

  // ── PIN optionnel ──────────────────────────────────────────────

  Future<bool> get pinActif async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('pin_actif') ?? false;
  }

  Future<bool> verifierPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = prefs.getString('pin_hash');
    return pinHash != null && pinHash == _hash(pin);
  }

  Future<void> activerPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_actif', true);
    await prefs.setString('pin_hash', _hash(pin));
    notifyListeners();
  }

  Future<void> desactiverPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pin_actif', false);
    await prefs.remove('pin_hash');
    notifyListeners();
  }

  Future<bool> deverrouillerAvecPin(String pin) async {
    final ok = await verifierPin(pin);
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('session_username');
      if (username != null) {
        final user = await _dao.findByUsername(username);
        if (user != null) {
          _utilisateurConnecte = user;
          notifyListeners();
          return true;
        }
      }
    }
    return false;
  }

  // ── Inscription ────────────────────────────────────────────────

  Future<AuthResult> inscrire({
    required String username,
    required String password,
    required String nomComplet,
    required String secretQuestion,
    required String secretAnswer,
  }) async {
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
      final existe = await _dao.usernameExists(username.trim().toLowerCase());
      if (existe)
        return AuthResult.error('Ce nom d\'utilisateur est déjà pris.');

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
      debugPrint('Erreur inscription: $e');
      return AuthResult.error('Erreur lors de la création du compte.');
    }
  }

  // ── Connexion ──────────────────────────────────────────────────

  Future<AuthResult> connecter({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty)
      return AuthResult.error('Veuillez remplir tous les champs.');

    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null || user.passwordHash != _hash(password))
        return AuthResult.error(
            'Nom d\'utilisateur ou mot de passe incorrect.');

      _utilisateurConnecte = user;
      await _sauvegarderSession(user.username);
      notifyListeners();
      return AuthResult.success();
    } catch (e) {
      debugPrint('Erreur connexion: $e');
      return AuthResult.error('Erreur de connexion. Veuillez réessayer.');
    }
  }

  // ── Déconnexion ────────────────────────────────────────────────

  Future<void> deconnecter() async {
    _utilisateurConnecte = null;
    await _supprimerSession();
    await desactiverPin();
    notifyListeners();
  }

  // ── Profil ─────────────────────────────────────────────────────

  Future<AuthResult> mettreAJourProfil(Utilisateur updatedUser) async {
    try {
      await _dao.updateProfil(updatedUser);
      _utilisateurConnecte = updatedUser;
      notifyListeners();
      return AuthResult.success();
    } catch (e) {
      debugPrint('Erreur mise à jour profil: $e');
      return AuthResult.error('Erreur lors de la mise à jour.');
    }
  }

  // ── Récupération mot de passe ──────────────────────────────────

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

  Future<AuthResult> verifierReponseSecrete({
    required String username,
    required String reponse,
  }) async {
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null) return AuthResult.error('Compte introuvable.');
      if (user.secretAnswerHash != _hash(reponse))
        return AuthResult.error('Réponse incorrecte.');
      return AuthResult.success(data: user);
    } catch (e) {
      return AuthResult.error('Erreur. Veuillez réessayer.');
    }
  }

  Future<AuthResult> reinitialiserMotDePasse({
    required String username,
    required String nouveauPassword,
  }) async {
    if (nouveauPassword.length < 6)
      return AuthResult.error(
          'Le mot de passe doit faire au moins 6 caractères.');
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null) return AuthResult.error('Compte introuvable.');
      await _dao.updatePassword(user.id!, _hash(nouveauPassword));
      return AuthResult.success();
    } catch (e) {
      return AuthResult.error('Erreur. Veuillez réessayer.');
    }
  }

  Future<String?> getSecretQuestion(String username) async {
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      return user?.secretQuestion;
    } catch (e) {
      return null;
    }
  }
}

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
