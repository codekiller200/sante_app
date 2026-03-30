import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class SecretHasher {
  SecretHasher._();

  static const String _scheme = 'pbkdf2_sha256';
  static const int _iterations = 120000;
  static const int _saltLength = 16;
  static const int _derivedKeyLength = 32;

  static String hash(String value) {
    final normalizedValue = _normalize(value);
    final salt = _randomBytes(_saltLength);
    final derivedKey = _pbkdf2(
      normalizedValue,
      salt,
      iterations: _iterations,
      keyLength: _derivedKeyLength,
    );

    return '$_scheme\$$_iterations\$${base64Encode(salt)}\$${base64Encode(derivedKey)}';
  }

  static bool verify(String value, String storedHash) {
    if (storedHash.startsWith('$_scheme\$')) {
      return _verifyPbkdf2(value, storedHash);
    }

    return _constantTimeEquals(_legacyHash(value), storedHash);
  }

  static bool needsMigration(String storedHash) {
    return !storedHash.startsWith('$_scheme\$');
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  static String _legacyHash(String value) {
    final bytes = utf8.encode(_normalize(value));
    return sha256.convert(bytes).toString();
  }

  static bool _verifyPbkdf2(String value, String storedHash) {
    final parts = storedHash.split(r'$');
    if (parts.length != 4) {
      return false;
    }

    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) {
      return false;
    }

    try {
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final actual = _pbkdf2(
        _normalize(value),
        salt,
        iterations: iterations,
        keyLength: expected.length,
      );

      return _constantTimeBytesEquals(actual, expected);
    } catch (_) {
      return false;
    }
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _pbkdf2(
    String value,
    Uint8List salt, {
    required int iterations,
    required int keyLength,
  }) {
    final passwordBytes = Uint8List.fromList(utf8.encode(value));
    final hmac = Hmac(sha256, passwordBytes);
    const hLen = 32;
    final blockCount = (keyLength / hLen).ceil();
    final output = BytesBuilder(copy: false);

    for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
      final blockSalt = BytesBuilder(copy: false)
        ..add(salt)
        ..add(_int32(blockIndex));
      var u = Uint8List.fromList(
        hmac.convert(blockSalt.toBytes()).bytes,
      );
      final block = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < block.length; j++) {
          block[j] ^= u[j];
        }
      }

      output.add(block);
    }

    return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
  }

  static Uint8List _int32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.big);
    return data.buffer.asUint8List();
  }

  static bool _constantTimeEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    return _constantTimeBytesEquals(leftBytes, rightBytes);
  }

  static bool _constantTimeBytesEquals(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }

    var diff = 0;
    for (var i = 0; i < left.length; i++) {
      diff |= left[i] ^ right[i];
    }
    return diff == 0;
  }
}
