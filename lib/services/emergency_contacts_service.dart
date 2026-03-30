import 'package:flutter/material.dart';

import 'package:sante_app/data/models/emergency_contact.dart';
import 'package:sante_app/services/secure_store_service.dart';

class EmergencyContactsService extends ChangeNotifier {
  static const _storageKey = 'emergency_contacts';

  List<EmergencyContact> _contacts = [];
  bool _loaded = false;
  final SecureStoreService _secureStore = SecureStoreService.instance;

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final values = await _secureStore.migrateStringListFromPrefs(_storageKey) ?? const [];
    _contacts = values.map(EmergencyContact.fromJson).toList();
    _loaded = true;
    notifyListeners();
  }

  Future<void> addContact(EmergencyContact contact) async {
    await load();
    _contacts = [..._contacts, contact];
    await _persist();
  }

  Future<void> removeContactAt(int index) async {
    await load();
    if (index < 0 || index >= _contacts.length) return;
    _contacts = List<EmergencyContact>.from(_contacts)..removeAt(index);
    await _persist();
  }

  Future<void> _persist() async {
    await _secureStore.writeStringList(
      _storageKey,
      _contacts.map((contact) => contact.toJson()).toList(),
    );
    notifyListeners();
  }
}

