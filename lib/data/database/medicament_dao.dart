import '../models/medicament.dart';
import 'database_helper.dart';

class MedicamentDao {
  final _db = DatabaseHelper.instance;

  // Créer un médicament
  Future<int> insert(Medicament med) async {
    final db = await _db.database;
    return await db.insert('medicaments', med.toMap());
  }

  // Lire tous les médicaments actifs
  Future<List<Medicament>> findAllActifs() async {
    final db = await _db.database;
    final maps = await db.query(
      'medicaments',
      where: 'est_actif = ?',
      whereArgs: [1],
      orderBy: 'nom ASC',
    );
    return maps.map((m) => Medicament.fromMap(m)).toList();
  }

  // Lire un médicament par ID
  Future<Medicament?> findById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'medicaments',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Medicament.fromMap(maps.first);
  }

  // Mettre à jour un médicament
  Future<void> update(Medicament med) async {
    final db = await _db.database;
    await db.update(
      'medicaments',
      med.toMap(),
      where: 'id = ?',
      whereArgs: [med.id],
    );
  }

  // Mettre à jour uniquement le stock
  Future<void> updateStock(int id, int nouveauStock) async {
    final db = await _db.database;
    await db.update(
      'medicaments',
      {'stock_actuel': nouveauStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Décrémenter le stock de 1 après une prise confirmée
  Future<void> decrementerStock(int id) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE medicaments SET stock_actuel = MAX(0, stock_actuel - 1) WHERE id = ?',
      [id],
    );
  }

  // Désactiver (suppression douce)
  Future<void> desactiver(int id) async {
    final db = await _db.database;
    await db.update(
      'medicaments',
      {'est_actif': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Supprimer définitivement
  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      'medicaments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Médicaments avec stock bas
  Future<List<Medicament>> findStockBas() async {
    final db = await _db.database;
    // stock_actuel / frequence_par_jour <= seuil_alerte
    final maps = await db.rawQuery('''
      SELECT * FROM medicaments
      WHERE est_actif = 1
        AND (stock_actuel * 1.0 / frequence_par_jour) <= seuil_alerte
      ORDER BY stock_actuel ASC
    ''');
    return maps.map((m) => Medicament.fromMap(m)).toList();
  }
}
