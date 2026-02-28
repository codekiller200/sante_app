import 'package:sqflite/sqflite.dart';
import '../models/utilisateur.dart';
import 'database_helper.dart';

class UtilisateurDao {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ─── Migration : ajouter les nouvelles colonnes si elles n'existent pas ──
  // À appeler depuis AppDatabase lors de l'upgrade de version
  static Future<void> migrerV2(Database db) async {
    final colonnes = <String>[
      'avatar_path TEXT',
      'avatar_emoji TEXT DEFAULT "🧑"',
      'date_naissance TEXT',
      'medecin_traitant TEXT',
      'groupe_sanguin TEXT',
      'allergies TEXT',
      'antecedents TEXT',
    ];
    for (final col in colonnes) {
      try {
        await db.execute('ALTER TABLE utilisateurs ADD COLUMN $col');
      } catch (_) {
        // Colonne déjà existante → on ignore
      }
    }
  }

  Future<int> insert(Utilisateur user) async {
    final db = await _db;
    return db.insert('utilisateurs', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Utilisateur?> findByUsername(String username) async {
    final db = await _db;
    final maps = await db.query(
      'utilisateurs',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return Utilisateur.fromMap(maps.first);
  }

  Future<bool> usernameExists(String username) async {
    final db = await _db;
    final result = await db.query(
      'utilisateurs',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> updatePassword(int id, String newHash) async {
    final db = await _db;
    await db.update(
      'utilisateurs',
      {'password_hash': newHash},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Met à jour tous les champs profil modifiables
  Future<void> updateProfil(Utilisateur user) async {
    final db = await _db;
    await db.update(
      'utilisateurs',
      {
        'nom_complet': user.nomComplet,
        'avatar_path': user.avatarPath,
        'avatar_emoji': user.avatarEmoji,
        'date_naissance': user.dateNaissance?.toIso8601String(),
        'medecin_traitant': user.medecinTraitant,
        'groupe_sanguin': user.groupeSanguin,
        'allergies': user.allergies,
        'antecedents': user.antecedents,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
