import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStoreService {
  SecureStoreService._();

  static final SecureStoreService instance = SecureStoreService._();

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  Future<String?> readString(String key) async {
    return _withFallback(
      secureAction: () => _storage.read(key: key),
      fallbackAction: (prefs) async => prefs.getString(key),
    );
  }

  Future<void> writeString(String key, String value) async {
    await _withFallback(
      secureAction: () => _storage.write(key: key, value: value),
      fallbackAction: (prefs) async {
        await prefs.setString(key, value);
      },
    );
  }

  Future<bool?> readBool(String key) async {
    final value = await _withFallback(
      secureAction: () => _storage.read(key: key),
      fallbackAction: (prefs) async {
        final boolValue = prefs.getBool(key);
        return boolValue?.toString();
      },
    );

    if (value == null) {
      return null;
    }
    return value.toLowerCase() == 'true';
  }

  Future<void> writeBool(String key, bool value) async {
    await writeString(key, value.toString());
  }

  Future<List<String>?> readStringList(String key) async {
    final value = await readString(key);
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> writeStringList(String key, List<String> values) async {
    await writeString(key, jsonEncode(values));
  }

  Future<void> delete(String key) async {
    await _withFallback(
      secureAction: () => _storage.delete(key: key),
      fallbackAction: (prefs) async {
        await prefs.remove(key);
      },
    );
  }

  Future<String?> migrateStringFromPrefs(String key) async {
    final secureValue = await readString(key);
    if (secureValue != null) {
      return secureValue;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(key);
    if (legacyValue == null) {
      return null;
    }

    await writeString(key, legacyValue);
    await prefs.remove(key);
    return legacyValue;
  }

  Future<bool?> migrateBoolFromPrefs(String key) async {
    final secureValue = await readBool(key);
    if (secureValue != null) {
      return secureValue;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getBool(key);
    if (legacyValue == null) {
      return null;
    }

    await writeBool(key, legacyValue);
    await prefs.remove(key);
    return legacyValue;
  }

  Future<List<String>?> migrateStringListFromPrefs(String key) async {
    final secureValue = await readStringList(key);
    if (secureValue != null) {
      return secureValue;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getStringList(key);
    if (legacyValue == null) {
      return null;
    }

    await writeStringList(key, legacyValue);
    await prefs.remove(key);
    return legacyValue;
  }

  Future<T> _withFallback<T>({
    required Future<T> Function() secureAction,
    required Future<T> Function(SharedPreferences prefs) fallbackAction,
  }) async {
    try {
      return await secureAction();
    } catch (error) {
      debugPrint('Secure storage unavailable, fallback applied: $error');
      final prefs = await SharedPreferences.getInstance();
      return fallbackAction(prefs);
    }
  }
}
