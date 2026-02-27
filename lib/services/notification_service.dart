import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../data/models/medicament.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialise = false;

  // ─── Initialisation ───────────────────────────────────────────
  Future<void> init() async {
    if (_initialise) return;

    tz.initializeTimeZones();

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

    // Demander les permissions Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Demander les permissions de notification
      await androidPlugin.requestNotificationsPermission();

      // Pour Android 12+, la permission d'alarme exacte doit être activée manuellement par l'utilisateur
      // dans les paramètres système. On essaie quand même de la demander.
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        // Cette permission nécessite souvent une action manuelle de l'utilisateur
        debugPrint(
            'Note: Exact alarm permission may require manual enablement in settings');
      }
    }

    _initialise = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation possible ici si besoin
  }

  // ─── Planifier toutes les notifications d'un médicament ───────
  Future<void> planifierPourMedicament(Medicament med) async {
    // D'abord annuler les anciennes notifications de ce médicament
    await annulerPourMedicament(med.id!);

    for (int i = 0; i < med.horaires.length; i++) {
      final horaire = med.horaires[i];
      final parts = horaire.split(':');
      final heure = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // ID unique = medicamentId * 100 + index horaire
      final notifId = med.id! * 100 + i;

      await _planifierQuotidienne(
        id: notifId,
        titre: '💊 ${med.nom}',
        corps: 'Il est l\'heure de prendre ${med.dosage}',
        heure: heure,
        minute: minute,
      );
    }
  }

  // ─── Planifier une notification quotidienne ───────────────────
  Future<void> _planifierQuotidienne({
    required int id,
    required String titre,
    required String corps,
    required int heure,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Calculer la prochaine occurrence
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      heure,
      minute,
    );

    // Si l'heure est déjà passée aujourd'hui, planifier pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      titre,
      corps,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mediremind_rappels',
          'Rappels médicaments',
          channelDescription: 'Notifications de prise de médicaments',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true, // Afficher même en veille
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Répéter chaque jour
    );
  }

  // ─── Notification immédiate (test) ───────────────────────────
  Future<void> afficherImmediatement({
    required String titre,
    required String corps,
  }) async {
    await _plugin.show(
      999,
      titre,
      corps,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mediremind_rappels',
          'Rappels médicaments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── Notification de stock bas ───────────────────────────────
  Future<void> notifierStockBas(Medicament med) async {
    await _plugin.show(
      med.id! + 10000,
      '⚠️ Stock bas — ${med.nom}',
      'Il ne reste que ${med.joursRestants} jours de traitement. Pensez à renouvellement.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mediremind_stock',
          'Alertes de stock',
          channelDescription: 'Alertes de renouvellement de médicaments',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  // ─── Annuler les notifications d'un médicament ───────────────
  Future<void> annulerPourMedicament(int medicamentId) async {
    // Annuler jusqu'à 10 horaires par médicament
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(medicamentId * 100 + i);
    }
  }

  // ─── Annuler toutes les notifications ────────────────────────
  Future<void> annulerTout() async {
    await _plugin.cancelAll();
  }

  // ─── Notification snooze ─────────────────────────────────────
  Future<void> planifierSnooze({
    required Medicament med,
    required int minutes,
  }) async {
    final scheduledDate =
        tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    await _plugin.zonedSchedule(
      med.id! + 50000, // ID unique pour le snooze
      '⏰ Rappel — ${med.nom}',
      'N\'oubliez pas de prendre ${med.dosage}',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mediremind_rappels',
          'Rappels médicaments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
