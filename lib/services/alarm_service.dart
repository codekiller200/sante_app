import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  static const _channel = MethodChannel('com.example.sante/alarm');

  Future<bool> programmerAlarme({
    required int id,
    required String titre,
    required String message,
    required int heure,
    required int minute,
    required String soundType,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('programmerAlarme', {
        'id': id,
        'titre': titre,
        'message': message,
        'heure': heure,
        'minute': minute,
        'soundType': soundType,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] programmerAlarme error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> programmerAlarmeTimestamp({
    required int id,
    required String titre,
    required String message,
    required int triggerAtMillis,
    required String soundType,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('programmerAlarmeTimestamp', {
        'id': id,
        'titre': titre,
        'message': message,
        'triggerAtMillis': triggerAtMillis,
        'soundType': soundType,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] programmerAlarmeTimestamp error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> annulerAlarme(int id) async {
    try {
      final result = await _channel.invokeMethod<bool>('annulerAlarme', {'id': id});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] annulerAlarme error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> stopActiveAlarm() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopActiveAlarm');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] stopActiveAlarm error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> verifierAutorisation() async {
    try {
      final result = await _channel.invokeMethod<bool>('verifierAutorisation');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] verifierAutorisation error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> annulerToutesAlarmes() async {
    try {
      final result = await _channel.invokeMethod<bool>('annulerToutesAlarmes');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] annulerToutesAlarmes error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> ouvrirParametresAlarme() async {
    try {
      final result = await _channel.invokeMethod<bool>('ouvrirParametresAlarme');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] ouvrirParametresAlarme error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> demanderIgnorerOptimisationsBatterie() async {
    try {
      final result = await _channel.invokeMethod<bool>('demanderIgnorerOptimisationsBatterie');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
        '[AlarmService] demanderIgnorerOptimisationsBatterie error: ${e.code} - ${e.message}',
      );
      return false;
    }
  }

  Future<bool> ignoreOptimisationsBatterieActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('ignoreOptimisationsBatterieActive');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
        '[AlarmService] ignoreOptimisationsBatterieActive error: ${e.code} - ${e.message}',
      );
      return false;
    }
  }

  Future<bool> ouvrirParametresBatterie() async {
    try {
      final result = await _channel.invokeMethod<bool>('ouvrirParametresBatterie');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[AlarmService] ouvrirParametresBatterie error: ${e.code} - ${e.message}');
      return false;
    }
  }

  Future<bool> ouvrirParametresArrierePlan() async {
    try {
      final result = await _channel.invokeMethod<bool>('ouvrirParametresArrierePlan');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
        '[AlarmService] ouvrirParametresArrierePlan error: ${e.code} - ${e.message}',
      );
      return false;
    }
  }
}
