import '../models/utilisateur.dart';
import 'database_helper.dart';

class UtilisateurDao {
  final _db = DatabaseHelper.instance;

  // Créer un utilisateur
  Future<int> insert(Utilisateur user) async {
    final db = await _db.database;
    return await db.insert('utilisateurs', user.toMap());
  }

  // Trouver par username
  Future<Utilisateur?> findByUsername(String username) async {
    final db = await _db.database;
    final maps = await db.query(
      'utilisateurs',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Utilisateur.fromMap(maps.first);
  }

  // Vérifier si un username existe déjà
  Future<bool> usernameExists(String username) async {
    final user = await findByUsername(username);
    return user != null;
  }

  // Mettre à jour le mot de passe
  Future<void> updatePassword(int id, String newPasswordHash) async {
    final db = await _db.database;
    await db.update(
      'utilisateurs',
      {'password_hash': newPasswordHash},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mettre à jour le profil
  Future<void> updateProfil(int id, String nomComplet) async {
    final db = await _db.database;
    await db.update(
      'utilisateurs',
      {'nom_complet': nomComplet},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
