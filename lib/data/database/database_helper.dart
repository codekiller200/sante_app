import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'utilisateur_dao.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;
  // CORRECTION: version 2 pour déclencher la migration des nouvelles colonnes profil
  static const int _version = 2;
  static const String _dbName = 'mediremind.db';

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      debugPrint('Database path: $path');
      return await openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table utilisateurs — avec les nouvelles colonnes dès la création
    await db.execute('''
      CREATE TABLE utilisateurs (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        username            TEXT NOT NULL UNIQUE,
        password_hash       TEXT NOT NULL,
        secret_question     TEXT NOT NULL,
        secret_answer_hash  TEXT NOT NULL,
        nom_complet         TEXT NOT NULL,
        date_creation       TEXT NOT NULL,
        avatar_path         TEXT,
        avatar_emoji        TEXT DEFAULT "🧑",
        date_naissance      TEXT,
        medecin_traitant    TEXT,
        groupe_sanguin      TEXT,
        allergies           TEXT,
        antecedents         TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE medicaments (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        nom               TEXT NOT NULL,
        dosage            TEXT NOT NULL,
        icone             TEXT NOT NULL,
        frequence_par_jour INTEGER NOT NULL,
        horaires          TEXT NOT NULL,
        stock_actuel      INTEGER NOT NULL DEFAULT 0,
        seuil_alerte      INTEGER NOT NULL DEFAULT 7,
        est_actif         INTEGER NOT NULL DEFAULT 1,
        date_creation     TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE prises (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        medicament_id     INTEGER NOT NULL,
        medicament_nom    TEXT NOT NULL,
        medicament_icone  TEXT NOT NULL,
        statut            TEXT NOT NULL,
        date_prevue       TEXT NOT NULL,
        date_prise        TEXT,
        snooze_minutes    INTEGER,
        FOREIGN KEY (medicament_id) REFERENCES medicaments(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_prises_date ON prises(date_prevue)');
    await db
        .execute('CREATE INDEX idx_prises_medicament ON prises(medicament_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration v1 → v2 : ajout des colonnes profil
    if (oldVersion < 2) {
      await UtilisateurDao.migrerV2(db);
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
