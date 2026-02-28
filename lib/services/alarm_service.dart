import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service de communication avec le code natif Android (AlarmManager).
/// Le MethodChannel correspond à celui déclaré dans MainActivity.kt.
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  static const _channel = MethodChannel('com.example.sante/alarm');

  /// Programme une alarme exacte via AlarmManager côté Android.
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
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] programmerAlarme error: ${e.code} — ${e.message}');
      return false;
    }
  }

  /// Annule une alarme par son identifiant.
  Future<bool> annulerAlarme(int id) async {
    try {
      final result = await _channel.invokeMethod<bool>('annulerAlarme', {'id': id});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] annulerAlarme error: ${e.code} — ${e.message}');
      return false;
    }
  }

  /// Vérifie si la permission SCHEDULE_EXACT_ALARM est accordée (Android 12+).
  Future<bool> verifierAutorisation() async {
    try {
      final result = await _channel.invokeMethod<bool>('verifierAutorisation');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] verifierAutorisation error: ${e.code} — ${e.message}');
      return false;
    }
  }

  /// Annule toutes les alarmes programmées.
  /// CORRECTION: appelle le code natif au lieu de retourner true sans rien faire.
  Future<bool> annulerToutesAlarmes() async {
    try {
      final result = await _channel.invokeMethod<bool>('annulerToutesAlarmes');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] annulerToutesAlarmes error: ${e.code} — ${e.message}');
      return false;
    }
  }

  /// Ouvre les paramètres système pour autoriser les alarmes exactes.
  Future<bool> ouvrirParametresAlarme() async {
    try {
      final result = await _channel.invokeMethod<bool>('ouvrirParametresAlarme');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] ouvrirParametresAlarme error: ${e.code} — ${e.message}');
      return false;
    }
  }
}