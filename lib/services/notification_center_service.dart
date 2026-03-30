import 'package:flutter/material.dart';

class NotificationCenterService extends ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _medicationRemindersEnabled = true;
  bool _stockAlertsEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get medicationRemindersEnabled => _medicationRemindersEnabled;
  bool get stockAlertsEnabled => _stockAlertsEnabled;

  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    if (!value) {
      _medicationRemindersEnabled = false;
      _stockAlertsEnabled = false;
    }
    notifyListeners();
  }

  void setMedicationRemindersEnabled(bool value) {
    _medicationRemindersEnabled = value;
    if (value) {
      _notificationsEnabled = true;
    }
    notifyListeners();
  }

  void setStockAlertsEnabled(bool value) {
    _stockAlertsEnabled = value;
    if (value) {
      _notificationsEnabled = true;
    }
    notifyListeners();
  }
}
