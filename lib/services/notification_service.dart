import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

import '../data/models/medicament.dart';
import 'alarm_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialise = false;
  bool _notificationsPermission = false;
  bool _exactAlarmsPermission = false;

  bool get hasNotificationsPermission => _notificationsPermission;
  bool get hasExactAlarmsPermission => _exactAlarmsPermission;
  bool get hasAllPermissions =>
      _notificationsPermission && _exactAlarmsPermission;

  // ─── Channels Android ─────────────────────────────────────────
  static const _channelRappels = AndroidNotificationDetails(
    'mediremind_rappels',
    'Rappels médicaments',
    channelDescription: 'Notifications de prise de médicaments',
    importance: Importance.max,
    priority: Priority.max,
    enableVibration: true,
    playSound: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
  );

  static const _channelStock = AndroidNotificationDetails(
    'mediremind_stock',
    'Alertes de stock',
    channelDescription: 'Alertes de renouvellement de médicaments',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _iosDefaut = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  // ─── Initialisation ───────────────────────────────────────────
  Future<void> init() async {
    if (_initialise) return;

    tzData.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await refreshPermissions();
    _initialise = true;
  }

  // ─── Vérifier / rafraîchir les permissions ────────────────────
  // À appeler aussi au retour de l'écran de paramètres Android
  Future<void> refreshPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      _notificationsPermission =
          await androidPlugin.areNotificationsEnabled() ?? false;
      _exactAlarmsPermission =
          await AlarmService.instance.verifierAutorisation();
    } else {
      // iOS : permissions gérées à l'initialisation
      _notificationsPermission = true;
      _exactAlarmsPermission = true;
    }
  }

  // ─── Demander les permissions ─────────────────────────────────
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      _notificationsPermission = granted ?? false;

      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('requestExactAlarmsPermission non supporté: $e');
      }

      // Toujours re-vérifier après la demande car l'utilisateur
      // peut avoir accordé/refusé depuis les paramètres système
      await refreshPermissions();
    }

    return _notificationsPermission;
  }

  void _onNotificationTap(NotificationResponse response) {
    // TODO: naviguer vers la confirmation de prise si besoin
  }

  // ─── Planifier toutes les notifications d'un médicament ───────
  Future<void> planifierPourMedicament(Medicament med) async {
    await annulerPourMedicament(med.id!);

    // Re-vérifier les permissions au moment de planifier
    await refreshPermissions();

    for (int i = 0; i < med.horaires.length; i++) {
      final parts = med.horaires[i].split(':');
      final heure = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final notifId = med.id! * 100 + i;

      await _planifierQuotidienne(
        id: notifId,
        titre: '💊 ${med.nom}',
        corps: 'Il est l\'heure de prendre ${med.dosage}',
        heure: heure,
        minute: minute,
      );

      // Alarme native Android (complément, peut ne pas être supporté sur tous les appareils)
      await AlarmService.instance.programmerAlarme(
        id: notifId,
        titre: '💊 ${med.nom}',
        message: 'Il est l\'heure de prendre ${med.dosage}',
        heure: heure,
        minute: minute,
      );

      // Notification de rappel 5 minutes après
      // CORRECTION: on calcule correctement l'heure+5min
      final backupTime = _ajouterMinutes(heure, minute, 5);
      await _planifierRappelUnique(
        id: notifId + 50000,
        titre: '⏰ Rappel — ${med.nom}',
        corps: 'Avez-vous pris ${med.dosage} ?',
        heure: backupTime.$1,
        minute: backupTime.$2,
      );
    }
  }

  // ─── Planifier une notification quotidienne répétée ───────────
  Future<void> _planifierQuotidienne({
    required int id,
    required String titre,
    required String corps,
    required int heure,
    required int minute,
  }) async {
    final scheduledDate = _prochainOccurrence(heure, minute);

    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      scheduledDate,
      NotificationDetails(
        android: _channelRappels,
        iOS: _iosDefaut,
      ),
      // CORRECTION: toujours utiliser exactAllowWhileIdle si possible,
      // sinon inexactAllowWhileIdle — mais on ne tombe jamais en silencieux
      androidScheduleMode: _exactAlarmsPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // répéter chaque jour
    );
  }

  // ─── Planifier un rappel unique (pas répété) ──────────────────
  // CORRECTION: ne pas utiliser matchDateTimeComponents ici
  // pour que ce soit un one-shot et non répété chaque jour
  Future<void> _planifierRappelUnique({
    required int id,
    required String titre,
    required String corps,
    required int heure,
    required int minute,
  }) async {
    final scheduledDate = _prochainOccurrence(heure, minute);

    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      scheduledDate,
      NotificationDetails(
        android: _channelRappels.copyWith(importance: Importance.high),
        iOS: _iosDefaut,
      ),
      androidScheduleMode: _exactAlarmsPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // PAS de matchDateTimeComponents → one-shot uniquement
    );
  }

  // ─── Notification immédiate (test) ───────────────────────────
  Future<void> afficherImmediatement({
    required String titre,
    required String corps,
  }) async {
    if (!_notificationsPermission) return;

    await _plugin.show(
      999,
      titre,
      corps,
      NotificationDetails(
        android: _channelRappels,
        iOS: _iosDefaut,
      ),
    );
  }

  // ─── Notification stock bas ───────────────────────────────────
  Future<void> notifierStockBas(Medicament med) async {
    if (!_notificationsPermission) return;

    await _plugin.show(
      med.id! + 10000,
      '⚠️ Stock bas — ${med.nom}',
      'Il ne reste que ${med.joursRestants} jours de traitement. Pensez à renouveler.',
      NotificationDetails(
        android: _channelStock,
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  // ─── Snooze ──────────────────────────────────────────────────
  Future<void> planifierSnooze({
    required Medicament med,
    required int minutes,
  }) async {
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    await _plugin.zonedSchedule(
      med.id! + 60000,
      '⏰ Rappel — ${med.nom}',
      'N\'oubliez pas de prendre ${med.dosage}',
      scheduledDate,
      NotificationDetails(
        android: _channelRappels,
        iOS: _iosDefaut,
      ),
      androidScheduleMode: _exactAlarmsPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Annuler les notifications d'un médicament ───────────────
  Future<void> annulerPourMedicament(int medicamentId) async {
    for (int i = 0; i < 10; i++) {
      final baseId = medicamentId * 100 + i;
      await _plugin.cancel(baseId);
      await _plugin.cancel(baseId + 50000); // backup
      await AlarmService.instance.annulerAlarme(baseId);
    }
  }

  // ─── Annuler tout ─────────────────────────────────────────────
  Future<void> annulerTout() async {
    await _plugin.cancelAll();
    await AlarmService.instance.annulerToutesAlarmes();
  }

  // ─── Helpers privés ──────────────────────────────────────────

  /// Retourne le prochain TZDateTime correspondant à [heure]:[minute]
  /// (aujourd'hui si pas encore passé, sinon demain)
  tz.TZDateTime _prochainOccurrence(int heure, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, heure, minute);
    if (date.isBefore(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  /// Additionne [minutesAAjouter] à [heure]:[minute] sans dépasser 59min/23h
  (int, int) _ajouterMinutes(int heure, int minute, int minutesAAjouter) {
    final total = minute + minutesAAjouter;
    final nouvelleMinute = total % 60;
    final nouvelleHeure = (heure + total ~/ 60) % 24;
    return (nouvelleHeure, nouvelleMinute);
  }
}

// Extension pour copier AndroidNotificationDetails avec des valeurs modifiées
extension on AndroidNotificationDetails {
  AndroidNotificationDetails copyWith({Importance? importance}) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance ?? this.importance,
      priority: priority,
      enableVibration: enableVibration,
      playSound: playSound,
      fullScreenIntent: fullScreenIntent,
      category: category,
    );
  }
}
