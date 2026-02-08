import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  Database? _db;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'basedfit.db');

    return openDatabase(
      path,
      version: 3,
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration de la version 1 à 2
          // Ajouter la colonne user_id à programs si elle n'existe pas
          await db.execute('''
            CREATE TABLE programs_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER NOT NULL DEFAULT 1,
              name TEXT NOT NULL,
              duration REAL NOT NULL,
              created_at TEXT NOT NULL DEFAULT '${DateTime.now().toIso8601String()}'
            );
          ''');

          // Copier les données existantes
          await db.execute('''
            INSERT INTO programs_new (id, name, duration, user_id, created_at)
            SELECT id, name, duration, 1, '${DateTime.now().toIso8601String()}' FROM programs;
          ''');

          // Supprimer l'ancienne table et renommer
          await db.execute('DROP TABLE programs;');
          await db.execute('ALTER TABLE programs_new RENAME TO programs;');

          // Créer les nouvelles tables
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
          // Migration de la version 2 à 3 - Ajout du système de forum
          // Ajouter is_admin aux utilisateurs
          await db.execute('ALTER TABLE users ADD COLUMN is_admin INTEGER DEFAULT 0;');
          
          // Créer les tables de forum
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
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Méthode pour réinitialiser la base de données (utile pour le développement)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'basedfit.db');
    await deleteDatabase(path);
    _db = null;
  }
}
