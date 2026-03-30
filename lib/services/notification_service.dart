import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:mediremind/models/medicament.dart';
import 'package:mediremind/services/alarm_preferences_service.dart';
import 'package:mediremind/services/alarm_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialise = false;
  bool _notificationsPermission = false;
  bool _exactAlarmsPermission = false;

  bool get hasNotificationsPermission => _notificationsPermission;
  bool get hasExactAlarmsPermission => _exactAlarmsPermission;
  bool get hasAllPermissions => _notificationsPermission && _exactAlarmsPermission;

  static const _channelRappels = AndroidNotificationDetails(
    'mediremind_rappels',
    'Rappels medicaments',
    channelDescription: 'Notifications de prise de medicaments',
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
    channelDescription: 'Alertes de renouvellement de medicaments',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const _iosDefaut = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  Future<void> init() async {
    if (_initialise) return;

    tz_data.initializeTimeZones();

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

  Future<void> refreshPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      _notificationsPermission = await androidPlugin.areNotificationsEnabled() ?? false;
      _exactAlarmsPermission = await AlarmService.instance.verifierAutorisation();
    } else {
      _notificationsPermission = true;
      _exactAlarmsPermission = true;
    }
  }

  Future<bool> requestPermissions() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      _notificationsPermission = granted ?? false;

      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('requestExactAlarmsPermission not supported: $e');
      }

      await refreshPermissions();
    }

    return _notificationsPermission;
  }

  void _onNotificationTap(NotificationResponse response) {}

  Future<void> planifierPourMedicament(Medicament med) async {
    await annulerPourMedicament(med.id!);
    await refreshPermissions();

    final soundType = (await AlarmPreferencesService.loadSoundType()).name;

    for (int i = 0; i < med.horaires.length; i++) {
      final parts = med.horaires[i].split(':');
      final heure = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final notifId = med.id! * 100 + i;

      if (med.intervalleJours <= 1) {
        await _planifierQuotidienne(
          id: notifId,
          titre: '💊 ${med.nom}',
          corps: 'Il est l\'heure de prendre ${med.dosage}',
          heure: heure,
          minute: minute,
        );

        await AlarmService.instance.programmerAlarme(
          id: notifId,
          titre: '💊 ${med.nom}',
          message: 'Il est l\'heure de prendre ${med.dosage}',
          heure: heure,
          minute: minute,
          soundType: soundType,
        );

        final backupTime = _ajouterMinutes(heure, minute, 5);
        await _planifierRappelUnique(
          id: notifId + 50000,
          titre: '⏰ Rappel - ${med.nom}',
          corps: 'Avez-vous pris ${med.dosage} ?',
          heure: backupTime.$1,
          minute: backupTime.$2,
        );
      } else {
        await _planifierIntervalle(
          med: med,
          baseId: notifId,
          heure: heure,
          minute: minute,
          soundType: soundType,
        );
      }
    }
  }

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
      const NotificationDetails(android: _channelRappels, iOS: _iosDefaut),
      androidScheduleMode: _exactAlarmsPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

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
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: _exactAlarmsPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _planifierIntervalle({
    required Medicament med,
    required int baseId,
    required int heure,
    required int minute,
    required String soundType,
  }) async {
    const horizonDays = 60;
    final start = _prochainOccurrence(heure, minute, intervalleJours: med.intervalleJours);

    for (int offset = 0; offset < horizonDays; offset += med.intervalleJours) {
      final scheduledDate = start.add(Duration(days: offset));
      final instanceId = baseId + 1000 + offset;

      await _plugin.zonedSchedule(
        instanceId,
        '💊 ${med.nom}',
        'Il est l\'heure de prendre ${med.dosage}',
        scheduledDate,
        const NotificationDetails(android: _channelRappels, iOS: _iosDefaut),
        androidScheduleMode: _exactAlarmsPermission
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      await AlarmService.instance.programmerAlarmeTimestamp(
        id: instanceId,
        titre: '💊 ${med.nom}',
        message: 'Il est l\'heure de prendre ${med.dosage}',
        triggerAtMillis: scheduledDate.millisecondsSinceEpoch,
        soundType: soundType,
      );

      final backupDate = scheduledDate.add(const Duration(minutes: 5));
      await _plugin.zonedSchedule(
        instanceId + 50000,
        '⏰ Rappel - ${med.nom}',
        'Avez-vous pris ${med.dosage} ?',
        backupDate,
        NotificationDetails(
          android: _channelRappels.copyWith(importance: Importance.high),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: _exactAlarmsPermission
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> afficherImmediatement({
    required String titre,
    required String corps,
  }) async {
    if (!_notificationsPermission) return;

    await _plugin.show(
      999,
      titre,
      corps,
      const NotificationDetails(
        android: _channelRappels,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> notifierStockBas(Medicament med) async {
    if (!_notificationsPermission) return;

    await _plugin.show(
      med.id! + 10000,
      '⚠️ Stock bas - ${med.nom}',
      'Il ne reste que ${med.joursRestants} jours de traitement.',
      const NotificationDetails(
        android: _channelStock,
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  Future<void> planifierSnooze({
    required Medicament med,
    required int minutes,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));

    await _plugin.zonedSchedule(
      med.id! + 60000,
      '⏰ Rappel - ${med.nom}',
      'N\'oubliez pas de prendre ${med.dosage}',
      scheduledDate,
      const NotificationDetails(
        android: _channelRappels,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: _exactAlarmsPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> annulerPourMedicament(int medicamentId) async {
    for (int i = 0; i < 80; i++) {
      final baseId = medicamentId * 100 + i;
      await _plugin.cancel(baseId);
      await _plugin.cancel(baseId + 50000);
      await AlarmService.instance.annulerAlarme(baseId);

      final intervalId = baseId + 1000;
      await _plugin.cancel(intervalId);
      await _plugin.cancel(intervalId + 50000);
      await AlarmService.instance.annulerAlarme(intervalId);
    }
  }

  Future<void> annulerTout() async {
    await _plugin.cancelAll();
    await AlarmService.instance.annulerToutesAlarmes();
  }

  tz.TZDateTime _prochainOccurrence(
    int heure,
    int minute, {
    int intervalleJours = 1,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(tz.local, now.year, now.month, now.day, heure, minute);
    if (date.isBefore(now)) {
      date = date.add(Duration(days: intervalleJours));
    }
    return date;
  }

  (int, int) _ajouterMinutes(int heure, int minute, int minutesAAjouter) {
    final total = minute + minutesAAjouter;
    final nouvelleMinute = total % 60;
    final nouvelleHeure = (heure + total ~/ 60) % 24;
    return (nouvelleHeure, nouvelleMinute);
  }
}

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
