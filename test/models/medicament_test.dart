import 'package:flutter_test/flutter_test.dart';
import 'package:sante_app/data/models/medicament.dart';

void main() {
  group('Medicament', () {
    test('should calculate days remaining correctly', () {
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

      expect(med.joursRestants, equals(5));
    });

    test('should detect low stock correctly', () {
      final med = Medicament(
        id: 1,
        nom: 'Paracetamol',
        dosage: '500mg',
        icone: '💊',
        frequenceParJour: 2,
        horaires: ['08:00', '20:00'],
        stockActuel: 5,
        seuilAlerte: 7,
        dateCreation: DateTime.now(),
      );

      expect(med.stockBas, isTrue);
    });

    test('should convert to map correctly', () {
      final med = Medicament(
        id: 1,
        nom: 'Paracetamol',
        dosage: '500mg',
        icone: '💊',
        frequenceParJour: 2,
        horaires: ['08:00', '20:00'],
        stockActuel: 10,
        dateCreation: DateTime(2023, 1, 1),
      );

      final map = med.toMap();
      expect(map['nom'], equals('Paracetamol'));
      expect(map['dosage'], equals('500mg'));
      expect(map['frequence_par_jour'], equals(2));
      expect(map['horaires'], equals('08:00,20:00'));
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'nom': 'Paracetamol',
        'dosage': '500mg',
        'icone': '💊',
        'frequence_par_jour': 2,
        'intervalle_jours': 1,
        'horaires': '08:00,20:00',
        'stock_actuel': 10,
        'seuil_alerte': 7,
        'est_actif': 1,
        'date_creation': '2023-01-01T00:00:00.000',
      };

      final med = Medicament.fromMap(map);
      expect(med.id, equals(1));
      expect(med.nom, equals('Paracetamol'));
      expect(med.dosage, equals('500mg'));
      expect(med.frequenceParJour, equals(2));
      expect(med.horaires, equals(['08:00', '20:00']));
      expect(med.stockActuel, equals(10));
      expect(med.estActif, isTrue);
    });

    test('should copy with new values correctly', () {
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

      final copy = med.copyWith(nom: 'Ibuprofen', dosage: '400mg');
      expect(copy.nom, equals('Ibuprofen'));
      expect(copy.dosage, equals('400mg'));
      expect(copy.id, equals(1));
      expect(copy.frequenceParJour, equals(2));
    });
  });
}
