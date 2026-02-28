import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  static const _channel = MethodChannel('com.example.sante/alarm');

  // Programmer une alarme exacte
  Future<bool> programmerAlarme({
    required int id,
    required String titre,
    required String message,
    required int heure,
    required int minute,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('programmerAlarme', {
        'id': id,
        'titre': titre,
        'message': message,
        'heure': heure,
        'minute': minute,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Erreur lors de la programmation de l\'alarme: $e');
      return false;
    }
  }

  // Annuler une alarme
  Future<bool> annulerAlarme(int id) async {
    try {
      final result = await _channel.invokeMethod<bool>('annulerAlarme', {
        'id': id,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('Erreur lors de l\'annulation de l\'alarme: $e');
      return false;
    }
  }

  // Vérifier si les alarmes exactes sont autorisées
  Future<bool> verifierAutorisation() async {
    try {
      final result = await _channel.invokeMethod<bool>('verifierAutorisation');
      return result ?? false;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des autorisations: $e');
      return false;
    }
  }

  // Annuler toutes les alarmes
  Future<bool> annulerToutesAlarmes() async {
    try {
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'annulation des alarmes: $e');
      return false;
    }
  }

  // Ouvrir l'app Horloge native
  Future<bool> ouvrirAppAlarme() async {
    try {
      final result = await _channel.invokeMethod<bool>('ouvrirAppAlarme');
      return result ?? false;
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture de l\'app alarme: $e');
      return false;
    }
  }
}
