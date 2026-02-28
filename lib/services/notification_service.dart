import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../data/models/medicament.dart';
import 'alarm_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialise = false;

  // Permissions accordées
  bool _notificationsPermission = false;
  bool _exactAlarmsPermission = false;

  bool get hasNotificationsPermission => _notificationsPermission;
  bool get hasExactAlarmsPermission => _exactAlarmsPermission;
  bool get hasAllPermissions =>
      _notificationsPermission && _exactAlarmsPermission;

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

    // Vérifier les permissions
    await _checkPermissions();

    _initialise = true;
  }

  // ─── Vérifier les permissions ─────────────────────────────────
  Future<void> _checkPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Vérifier la permission de notification
      final notif = await androidPlugin.areNotificationsEnabled();
      _notificationsPermission = notif ?? false;

      // Vérifier la permission d'alarme exacte via AlarmService
      _exactAlarmsPermission =
          await AlarmService.instance.verifierAutorisation();
    } else {
      // Pour iOS, on suppose que les permissions sont accordées si initialisé
      _notificationsPermission = true;
      _exactAlarmsPermission = true;
    }
  }

  // ─── Demander les permissions ─────────────────────────────────
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Demander les permissions de notification
      final granted = await androidPlugin.requestNotificationsPermission();
      _notificationsPermission = granted ?? false;

      // Pour les alarmes exactes sur Android 12+, ça doit être accordé dans les paramètres
      // On essaie quand même de demander
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        // Sur certaines versions, cette méthode n'existe pas
        debugPrint('Note: Exact alarms permission request failed: $e');
      }

      // Re-vérifier après la demande
      await _checkPermissions();
    }

    return _notificationsPermission;
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

      // 1. Programmer la notification via flutter_local_notifications
      await _planifierQuotidienne(
        id: notifId,
        titre: '💊 ${med.nom}',
        corps: 'Il est l\'heure de prendre ${med.dosage}',
        heure: heure,
        minute: minute,
      );

      // 2. Programmer une alarme dans l'app Horloge native Android
      // Cela permet d'avoir une alarme réelle qui sonne même si l'app est fermée
      await AlarmService.instance.programmerAlarme(
        id: notifId,
        titre: '💊 ${med.nom}',
        message: 'Il est l\'heure de prendre ${med.dosage}',
        heure: heure,
        minute: minute,
      );

      // 3. Planifier aussi une notification de backup (sera affichée 5 min après l'alarme)
      await _planifierNotificationBackup(
        id: notifId + 50000, // ID différent pour la backup
        titre: '⏰ Rappel - ${med.nom}',
        corps:
            'Vous n\'avez pas confirmé la prise de ${med.dosage}. Cliquez pour confirmer.',
        heure: heure,
        minute: minute + 5, // 5 minutes après l'alarme originale
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

    // Utiliser scheduleExact si permission accordée, sinon zonedSchedule standard
    if (_exactAlarmsPermission) {
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
            category: AndroidNotificationCategory.alarm,
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
    } else {
      // Sans permission d'alarme exacte, on utilise inexactAllowWhileIdle
      // qui fonctionnera mais pourrait ne pas être précis à la seconde près
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
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  // ─── Planifier notification backup (5 min après) ──────────────
  Future<void> _planifierNotificationBackup({
    required int id,
    required String titre,
    required String corps,
    required int heure,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Calculer pour 5 minutes après l'alarme
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
          'mediremind_backup',
          'Rappels backup',
          channelDescription: 'Notifications de rappel backup',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
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
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
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
    // Annuler jusqu'à 10 horaires par médicament + les backup
    for (int i = 0; i < 10; i++) {
      await _plugin.cancel(medicamentId * 100 + i);
      await _plugin.cancel(medicamentId * 100 + i + 50000); // backup
      // Annuler aussi l'alarme dans l'app Horloge
      await AlarmService.instance.annulerAlarme(medicamentId * 100 + i);
    }
  }

  // ─── Annuler toutes les notifications ──────────────────────────
  Future<void> annulerTout() async {
    await _plugin.cancelAll();
    await AlarmService.instance.annulerToutesAlarmes();
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
