import 'package:flutter_test/flutter_test.dart';
import 'package:sante_app/services/notification_service.dart';
import 'package:sante_app/data/models/medicament.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;

    setUp(() {
      service = NotificationService.instance;
    });

    test('should initialize without throwing', () {
      expect(() => service.init(), returnsNormally);
    });

    test('should handle permissions correctly', () async {
      await service.init();
      expect(service.hasNotificationsPermission, isNotNull);
      expect(service.hasExactAlarmsPermission, isNotNull);
    });

    test('should plan notifications for daily medication', () async {
      await service.init();
      
      final med = Medicament(
        id: 1,
        nom: 'Paracetamol',
        dosage: '500mg',
        icone: '💊',
        frequenceParJour: 2,
        horaires: ['08:00', '20:00'],
        stockActuel: 10,
        dateCreation: DateTime.now(),
      );

      expect(() => service.planifierPourMedicament(med), returnsNormally);
    });

    test('should cancel notifications for medication', () async {
      await service.init();
      expect(() => service.annulerPourMedicament(1), returnsNormally);
    });

    test('should show immediate notification', () async {
      await service.init();
      expect(
        () => service.afficherImmediatement(
          titre: 'Test',
          corps: 'Test notification',
        ),
        returnsNormally,
      );
    });
  });
}

