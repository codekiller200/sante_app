import '../models/prise.dart';
import 'database_helper.dart';

class PriseDao {
  final _db = DatabaseHelper.instance;

  // Enregistrer une prise
  Future<int> insert(Prise prise) async {
    final db = await _db.database;
    return await db.insert('prises', prise.toMap());
  }

  // Mettre à jour une prise (ex: confirmer, snoozer)
  Future<void> update(Prise prise) async {
    final db = await _db.database;
    await db.update(
      'prises',
      prise.toMap(),
      where: 'id = ?',
      whereArgs: [prise.id],
    );
  }

  // Prises d'un jour donné
  Future<List<Prise>> findByDate(DateTime date) async {
    final db = await _db.database;
    final debut = DateTime(date.year, date.month, date.day);
    final fin   = debut.add(const Duration(days: 1));

    final maps = await db.query(
      'prises',
      where: 'date_prevue >= ? AND date_prevue < ?',
      whereArgs: [debut.toIso8601String(), fin.toIso8601String()],
      orderBy: 'date_prevue ASC',
    );
    return maps.map((m) => Prise.fromMap(m)).toList();
  }

  // Prises d'un mois donné (pour l'observance)
  Future<List<Prise>> findByMonth(int year, int month) async {
    final db = await _db.database;
    final debut = DateTime(year, month, 1);
    final fin   = DateTime(year, month + 1, 1);

    final maps = await db.query(
      'prises',
      where: 'date_prevue >= ? AND date_prevue < ?',
      whereArgs: [debut.toIso8601String(), fin.toIso8601String()],
      orderBy: 'date_prevue DESC',
    );
    return maps.map((m) => Prise.fromMap(m)).toList();
  }

  // Prises d'un médicament donné
  Future<List<Prise>> findByMedicament(int medicamentId) async {
    final db = await _db.database;
    final maps = await db.query(
      'prises',
      where: 'medicament_id = ?',
      whereArgs: [medicamentId],
      orderBy: 'date_prevue DESC',
    );
    return maps.map((m) => Prise.fromMap(m)).toList();
  }

  // Prochaine prise prévue (pas encore confirmée)
  Future<Prise?> findProchainePrise() async {
    final db = await _db.database;
    final maintenant = DateTime.now().toIso8601String();
    final maps = await db.query(
      'prises',
      where: "date_prevue >= ? AND statut = 'snoozee'",
      whereArgs: [maintenant],
      orderBy: 'date_prevue ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Prise.fromMap(maps.first);
  }

  // Calcul taux d'observance sur un mois (%)
  Future<double> calculerObservance(int year, int month) async {
    final prises = await findByMonth(year, month);
    if (prises.isEmpty) return 0.0;

    final prisesEffectuees = prises
        .where((p) => p.statut == StatutPrise.prise)
        .length;

    return (prisesEffectuees / prises.length) * 100;
  }

  // Supprimer les prises d'un médicament (cascade)
  Future<void> deleteByMedicament(int medicamentId) async {
    final db = await _db.database;
    await db.delete(
      'prises',
      where: 'medicament_id = ?',
      whereArgs: [medicamentId],
    );
  }
}
