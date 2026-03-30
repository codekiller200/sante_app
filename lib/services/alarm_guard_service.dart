import 'package:mediremind/services/alarm_service.dart';
import 'package:mediremind/services/notification_service.dart';

class AlarmGuardStatus {
  const AlarmGuardStatus({
    required this.notificationsGranted,
    required this.exactAlarmGranted,
    required this.ignoringBatteryOptimizations,
  });

  final bool notificationsGranted;
  final bool exactAlarmGranted;
  final bool ignoringBatteryOptimizations;

  bool get fullyReady =>
      notificationsGranted &&
      exactAlarmGranted &&
      ignoringBatteryOptimizations;
}

class AlarmGuardService {
  AlarmGuardService._();

  static Future<AlarmGuardStatus> loadStatus() async {
    await NotificationService.instance.refreshPermissions();
    final ignoringBatteryOptimizations =
        await AlarmService.instance.ignoreOptimisationsBatterieActive();

    return AlarmGuardStatus(
      notificationsGranted: NotificationService.instance.hasNotificationsPermission,
      exactAlarmGranted: NotificationService.instance.hasExactAlarmsPermission,
      ignoringBatteryOptimizations: ignoringBatteryOptimizations,
    );
  }

  static Future<void> requestRecommendedPermissions() async {
    await NotificationService.instance.requestPermissions();
    await AlarmService.instance.demanderIgnorerOptimisationsBatterie();
  }
}
