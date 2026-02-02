import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class WorkoutDatabase {
  static final WorkoutDatabase instance = WorkoutDatabase._internal();
  Database? _db;

  WorkoutDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'basedfit_workouts.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE programs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            duration REAL NOT NULL
          );
        ''');

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
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }
}
