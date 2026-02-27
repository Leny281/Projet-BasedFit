import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // Utilitaire : hash SHA-256 d'un mot de passe
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'basedfit.db');

    return openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        // Table des programmes d'entraînement
        await db.execute('''
          CREATE TABLE programs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            duration REAL NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');

        // Table des exercices dans les programmes
        await db.execute('''
          CREATE TABLE program_exercises (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            program_id INTEGER NOT NULL,
            exercise_id TEXT NOT NULL,
            name TEXT NOT NULL,
            image TEXT,
            muscle_group TEXT,
            equipment TEXT,
            is_favorite INTEGER NOT NULL,
            sets INTEGER NOT NULL,
            reps INTEGER NOT NULL,
            weight REAL NOT NULL,
            rest INTEGER NOT NULL,
            notes TEXT,
            FOREIGN KEY(program_id) REFERENCES programs(id) ON DELETE CASCADE
          );
        ''');

        // Table des utilisateurs
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            phone_number TEXT NOT NULL,
            birth_date TEXT NOT NULL,
            height REAL NOT NULL,
            weight REAL NOT NULL,
            goal TEXT NOT NULL,
            is_admin INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
          );
        ''');

        // Table pour l'utilisateur connecté (stocke l'ID)
        await db.execute('''
          CREATE TABLE current_session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            user_id INTEGER,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
          );
        ''');

        // Table des statistiques utilisateur
        await db.execute('''
          CREATE TABLE user_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE,
            workouts_completed INTEGER DEFAULT 0,
            total_days INTEGER DEFAULT 0,
            current_streak INTEGER DEFAULT 0,
            last_workout_date TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');

        // Table des forums
        await db.execute('''
          CREATE TABLE forums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            created_by_user_id INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            message_count INTEGER DEFAULT 0,
            FOREIGN KEY(created_by_user_id) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');

        // Table des messages dans les forums
        await db.execute('''
          CREATE TABLE forum_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            forum_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            message TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(forum_id) REFERENCES forums(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          );
        ''');

        // Initialiser la ligne de session (vide au début)
        await db.insert('current_session', {'id': 1, 'user_id': null});

        // ── Compte gérant par défaut ──────────────────────────────────
        await _seedManagerAccount(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE programs_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL DEFAULT 1,
              name TEXT NOT NULL,
              duration REAL NOT NULL,
              created_at TEXT NOT NULL DEFAULT '${DateTime.now().toIso8601String()}'
            );
          ''');
          await db.execute('''
            INSERT INTO programs_new (id, name, duration, user_id, created_at)
            SELECT id, name, duration, 1, '${DateTime.now().toIso8601String()}' FROM programs;
          ''');
          await db.execute('DROP TABLE programs;');
          await db.execute('ALTER TABLE programs_new RENAME TO programs;');

          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              email TEXT UNIQUE NOT NULL,
              password TEXT NOT NULL,
              phone_number TEXT NOT NULL,
              birth_date TEXT NOT NULL,
              height REAL NOT NULL,
              weight REAL NOT NULL,
              goal TEXT NOT NULL,
              created_at TEXT NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE current_session (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              user_id INTEGER,
              FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE SET NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE user_stats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL UNIQUE,
              workouts_completed INTEGER DEFAULT 0,
              total_days INTEGER DEFAULT 0,
              current_streak INTEGER DEFAULT 0,
              last_workout_date TEXT,
              FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            );
          ''');
          await db.insert('current_session', {'id': 1, 'user_id': null});
        }

        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE users ADD COLUMN is_admin INTEGER DEFAULT 0;');
          await db.execute('''
            CREATE TABLE forums (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT NOT NULL,
              created_by_user_id INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              message_count INTEGER DEFAULT 0,
              FOREIGN KEY(created_by_user_id) REFERENCES users(id) ON DELETE CASCADE
            );
          ''');
          await db.execute('''
            CREATE TABLE forum_messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              forum_id INTEGER NOT NULL,
              user_id INTEGER NOT NULL,
              message TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY(forum_id) REFERENCES forums(id) ON DELETE CASCADE,
              FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
            );
          ''');
        }

        if (oldVersion < 4) {
          // Migration v3 → v4 : insertion du compte gérant par défaut
          // (si la DB existait avant cette version, on l'ajoute ici)
          await _seedManagerAccount(db);
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Insère le compte gérant par défaut s'il n'existe pas déjà.
  ///
  /// Identifiants :
  ///   Email    → gerant@basedfit.com
  ///   Mot de passe → Gerant2024!
  static Future<void> _seedManagerAccount(Database db) async {
    const managerEmail = 'gerant@basedfit.com';
    const managerPassword = 'Gerant2024!';

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [managerEmail],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('users', {
        'first_name': 'Gérant',
        'last_name': 'BasedFit',
        'email': managerEmail,
        'password': hashPassword(managerPassword),
        'phone_number': '0000000000',
        'birth_date': '1990-01-01',
        'height': 170.0,
        'weight': 70.0,
        'goal': 'management',
        'is_admin': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Méthode pour réinitialiser la base de données (utile pour le développement)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'basedfit.db');
    await deleteDatabase(path);
    _db = null;
  }
}