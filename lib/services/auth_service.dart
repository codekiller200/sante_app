import 'package:flutter/material.dart';

import 'package:sante_app/core/security/secret_hasher.dart';
import 'package:sante_app/data/database/utilisateur_dao.dart';
import 'package:sante_app/data/models/utilisateur.dart';
import 'package:sante_app/services/secure_store_service.dart';

class AuthService extends ChangeNotifier {
  final UtilisateurDao _dao = UtilisateurDao();
  final SecureStoreService _secureStore = SecureStoreService.instance;

  static const _sessionUsernameKey = 'session_username';
  static const _pinActiveKey = 'pin_actif';
  static const _pinHashKey = 'pin_hash';

  Utilisateur? _utilisateurConnecte;
  bool _sessionChargee = false;

  bool get isLoggedIn => _utilisateurConnecte != null;
  bool get sessionChargee => _sessionChargee;
  Utilisateur? get utilisateurConnecte => _utilisateurConnecte;
  Utilisateur? get user => _utilisateurConnecte;

  Future<void> restaurerSession() async {
    try {
      final username = await _readSessionUsername();
      if (username != null) {
        final user = await _dao.findByUsername(username);
        if (user != null) {
          final pinActif = await this.pinActif;
          if (!pinActif) {
            _utilisateurConnecte = user;
          }
        }
      }
    } catch (error) {
      debugPrint('Erreur restauration session: $error');
    } finally {
      _sessionChargee = true;
      notifyListeners();
    }
  }

  Future<void> _sauvegarderSession(String username) async {
    await _secureStore.writeString(_sessionUsernameKey, username);
  }

  Future<void> _supprimerSession() async {
    await _secureStore.delete(_sessionUsernameKey);
  }

  Future<bool> get pinActif async {
    return await _secureStore.migrateBoolFromPrefs(_pinActiveKey) ?? false;
  }

  Future<bool> verifierPin(String pin) async {
    final pinHash = await _secureStore.migrateStringFromPrefs(_pinHashKey);
    if (pinHash == null) {
      return false;
    }

    final matches = SecretHasher.verify(pin, pinHash);
    if (matches && SecretHasher.needsMigration(pinHash)) {
      await _secureStore.writeString(_pinHashKey, SecretHasher.hash(pin));
    }

    return matches;
  }

  Future<void> activerPin(String pin) async {
    await _secureStore.writeBool(_pinActiveKey, true);
    await _secureStore.writeString(_pinHashKey, SecretHasher.hash(pin));
    notifyListeners();
  }

  Future<void> desactiverPin() async {
    await _secureStore.writeBool(_pinActiveKey, false);
    await _secureStore.delete(_pinHashKey);
    notifyListeners();
  }

  Future<bool> deverrouillerAvecPin(String pin) async {
    final ok = await verifierPin(pin);
    if (!ok) return false;

    final username = await _readSessionUsername();
    if (username == null) return false;

    final user = await _dao.findByUsername(username);
    if (user == null) return false;

    _utilisateurConnecte = user;
    notifyListeners();
    return true;
  }

  Future<AuthResult<void>> inscrire({
    required String username,
    required String password,
    required String nomComplet,
    required String secretQuestion,
    required String secretAnswer,
  }) async {
    if (username.trim().length < 3) {
      return AuthResult.error('Le nom d\'utilisateur doit contenir au moins 3 caractères.');
    }
    if (password.length < 6) {
      return AuthResult.error('Le mot de passe doit contenir au moins 6 caractères.');
    }
    if (nomComplet.trim().isEmpty) {
      return AuthResult.error('Le nom complet est requis.');
    }
    if (secretAnswer.trim().isEmpty) {
      return AuthResult.error('La reponse secrete est réquise.');
    }

    try {
      final normalizedUsername = username.trim().toLowerCase();
      final existe = await _dao.usernameExists(normalizedUsername);
      if (existe) {
        return AuthResult.error('Ce nom d\'utilisateur est deja utilisé.');
      }

      final user = Utilisateur(
        username: normalizedUsername,
        passwordHash: SecretHasher.hash(password),
        secretQuestion: secretQuestion,
        secretAnswerHash: SecretHasher.hash(secretAnswer),
        nomComplet: nomComplet.trim(),
        dateCreation: DateTime.now(),
      );
      await _dao.insert(user);
      return AuthResult.success();
    } catch (error) {
      debugPrint('Erreur inscription: $error');
      return AuthResult.error('Impossible de créer le compte pour le moment.');
    }
  }

  Future<AuthResult<void>> connecter({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return AuthResult.error('Veuillez remplir tous les champs.');
    }

    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null || !SecretHasher.verify(password, user.passwordHash)) {
        return AuthResult.error('Nom d\'utilisateur ou mot de passe incorrect.');
      }

      if (user.id != null && SecretHasher.needsMigration(user.passwordHash)) {
        await _dao.updatePassword(user.id!, SecretHasher.hash(password));
      }

      _utilisateurConnecte = user;
      await _sauvegarderSession(user.username);
      notifyListeners();
      return AuthResult.success();
    } catch (error) {
      debugPrint('Erreur connexion: $error');
      return AuthResult.error('Erreur de connexion. Veuillez réessayer.');
    }
  }

  Future<void> deconnecter() async {
    _utilisateurConnecte = null;
    await _supprimerSession();
    notifyListeners();
  }

  Future<AuthResult<Utilisateur>> mettreAJourProfil(Utilisateur updatedUser) async {
    try {
      await _dao.updateProfil(updatedUser);
      _utilisateurConnecte = updatedUser;
      notifyListeners();
      return AuthResult.success(data: updatedUser);
    } catch (error) {
      debugPrint('Erreur mise a jour profil: $error');
      return AuthResult.error('Impossible de mettre a jour le profil.');
    }
  }

  Future<AuthResult<Utilisateur>> verifierUsername(String username) async {
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null) {
        return AuthResult.error('Aucun compte trouve avec ce nom d utilisateur.');
      }
      return AuthResult.success(data: user);
    } catch (_) {
      return AuthResult.error('Erreur de verification.');
    }
  }

  Future<AuthResult<Utilisateur>> verifierReponseSecrete({
    required String username,
    required String reponse,
  }) async {
    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user == null) {
        return AuthResult.error('Compte introuvable.');
      }
      if (!SecretHasher.verify(reponse, user.secretAnswerHash)) {
        return AuthResult.error('Reponse incorrecte.');
      }
      if (user.id != null && SecretHasher.needsMigration(user.secretAnswerHash)) {
        await _dao.updateSecretAnswerHash(user.id!, SecretHasher.hash(reponse));
      }
      return AuthResult.success(data: user);
    } catch (_) {
      return AuthResult.error('Erreur de verification.');
    }
  }

  Future<AuthResult<void>> reinitialiserMotDePasse({
    required String username,
    required String nouveauPassword,
  }) async {
    if (nouveauPassword.length < 6) {
      return AuthResult.error('Le mot de passe doit contenir au moins 6 caractères.');
    }

    try {
      final user = await _dao.findByUsername(username.trim().toLowerCase());
      if (user?.id == null) {
        return AuthResult.error('Compte introuvable.');
      }
      await _dao.updatePassword(user!.id!, SecretHasher.hash(nouveauPassword));
      return AuthResult.success();
    } catch (_) {
      return AuthResult.error('Impossible de reinitialiser le mot de passe.');
    }
  }

  Future<String?> getSecretQuestion(String username) async {
    final user = await _dao.findByUsername(username.trim().toLowerCase());
    return user?.secretQuestion;
  }

  Future<String?> _readSessionUsername() async {
    return _secureStore.migrateStringFromPrefs(_sessionUsernameKey);
  }
}

class AuthResult<T> {
  const AuthResult._({
    required this.success,
    this.errorMessage,
    this.data,
  });

  final bool success;
  final String? errorMessage;
  final T? data;

  factory AuthResult.success({T? data}) => AuthResult._(success: true, data: data);

  factory AuthResult.error(String message) =>
      AuthResult._(success: false, errorMessage: message);
}

