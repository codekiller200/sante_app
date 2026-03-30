import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlarmSoundType { alarm, ringtone, notification }

class AlarmPreferencesService extends ChangeNotifier {
  AlarmPreferencesService() {
    _load();
  }

  static const _soundKey = 'alarm_sound_type';

  AlarmSoundType _soundType = AlarmSoundType.alarm;

  AlarmSoundType get soundType => _soundType;

  static Future<AlarmSoundType> loadSoundType() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_soundKey);
    return AlarmSoundType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => AlarmSoundType.alarm,
    );
  }

  Future<void> _load() async {
    _soundType = await loadSoundType();
    notifyListeners();
  }

  Future<void> setSoundType(AlarmSoundType value) async {
    _soundType = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundKey, value.name);
    notifyListeners();
  }

  String get label {
    switch (_soundType) {
      case AlarmSoundType.alarm:
        return 'Alarme systeme';
      case AlarmSoundType.ringtone:
        return 'Sonnerie telephone';
      case AlarmSoundType.notification:
        return 'Notification';
    }
  }
}
