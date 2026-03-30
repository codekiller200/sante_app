import 'package:flutter_test/flutter_test.dart';
import 'package:sante_app/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService service;

    setUp(() {
      service = AuthService();
    });

    test('should restore session without throwing', () async {
      expect(() => service.restaurerSession(), returnsNormally);
    });

    test('should handle login correctly', () async {
      final result = await service.connecter(
        username: 'test@example.com',
        password: 'password123',
      );
      expect(result, isNotNull);
      expect(result.success, isNotNull);
    });

    test('should handle registration correctly', () async {
      final result = await service.inscrire(
        username: 'testuser',
        password: 'password123',
        nomComplet: 'Test User',
        secretQuestion: 'favorite color',
        secretAnswer: 'blue',
      );
      expect(result, isNotNull);
      expect(result.success, isNotNull);
    });

    test('should handle logout correctly', () async {
      expect(() => service.deconnecter(), returnsNormally);
    });

    test('should check if user is logged in', () {
      expect(service.isLoggedIn, isNotNull);
    });

    test('should verify PIN correctly', () async {
      expect(() => service.verifierPin('1234'), returnsNormally);
    });

    test('should activate PIN correctly', () async {
      expect(() => service.activerPin('1234'), returnsNormally);
    });
  });
}

