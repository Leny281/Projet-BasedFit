import '../models/user_model.dart';
import '../data/app_database.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AppDatabase _dbProvider = AppDatabase.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Initialisation au démarrage
  Future<void> init() async {
    final db = await _dbProvider.database;
    
    // Charger l'utilisateur actuellement connecté
    final result = await db.query(
      'current_session',
      where: 'id = ?',
      whereArgs: [1],
    );

    if (result.isNotEmpty && result.first['user_id'] != null) {
      final userId = result.first['user_id'] as int;
      final userResult = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (userResult.isNotEmpty) {
        _currentUser = User.fromMap(userResult.first);
      }
    }
  }

  // Enregistrement
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required DateTime birthDate,
    required double height,
    required double weight,
    required String password,
  }) async {
    final db = await _dbProvider.database;

    // Vérifier si l'email existe déjà
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (existing.isNotEmpty) {
      return false;
    }

    // Créer l'utilisateur
    final userId = await db.insert('users', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'birth_date': birthDate.toIso8601String(),
      'height': height,
      'weight': weight,
      'goal': 'Remise en forme',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Créer les statistiques de l'utilisateur
    await db.insert('user_stats', {
      'user_id': userId,
      'workouts_completed': 0,
      'total_days': 0,
      'current_streak': 0,
    });

    // Charger l'utilisateur créé
    final userResult = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    _currentUser = User.fromMap(userResult.first);

    // Définir la session
    await db.update(
      'current_session',
      {'user_id': userId},
      where: 'id = ?',
      whereArgs: [1],
    );

    return true;
  }

  // Connexion
  Future<bool> login(String email, String password) async {
    final db = await _dbProvider.database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isEmpty) {
      return false;
    }

    _currentUser = User.fromMap(result.first);

    // Définir la session
    await db.update(
      'current_session',
      {'user_id': _currentUser!.id},
      where: 'id = ?',
      whereArgs: [1],
    );

    return true;
  }

  // Déconnexion
  Future<void> logout() async {
    _currentUser = null;
    final db = await _dbProvider.database;
    await db.update(
      'current_session',
      {'user_id': null},
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // Mise à jour du profil
  Future<void> updateUser(User updatedUser) async {
    final db = await _dbProvider.database;

    await db.update(
      'users',
      {
        'height': updatedUser.height,
        'weight': updatedUser.weight,
        'goal': updatedUser.goal,
      },
      where: 'id = ?',
      whereArgs: [updatedUser.id],
    );

    _currentUser = updatedUser;
  }

  // Obtenir les statistiques de l'utilisateur
  Future<Map<String, int>> getUserStats() async {
    if (_currentUser == null) {
      return {
        'workouts_completed': 0,
        'total_days': 0,
        'current_streak': 0,
      };
    }

    final db = await _dbProvider.database;
    final result = await db.query(
      'user_stats',
      where: 'user_id = ?',
      whereArgs: [_currentUser!.id],
    );

    if (result.isEmpty) {
      return {
        'workouts_completed': 0,
        'total_days': 0,
        'current_streak': 0,
      };
    }

    return {
      'workouts_completed': result.first['workouts_completed'] as int,
      'total_days': result.first['total_days'] as int,
      'current_streak': result.first['current_streak'] as int,
    };
  }

  // Mettre à jour les statistiques
  Future<void> updateStats({
    int? workoutsCompleted,
    int? totalDays,
    int? currentStreak,
  }) async {
    if (_currentUser == null) return;

    final db = await _dbProvider.database;
    final updates = <String, dynamic>{};

    if (workoutsCompleted != null) {
      updates['workouts_completed'] = workoutsCompleted;
    }
    if (totalDays != null) {
      updates['total_days'] = totalDays;
    }
    if (currentStreak != null) {
      updates['current_streak'] = currentStreak;
    }
    if (updates.isNotEmpty) {
      updates['last_workout_date'] = DateTime.now().toIso8601String();

      await db.update(
        'user_stats',
        updates,
        where: 'user_id = ?',
        whereArgs: [_currentUser!.id],
      );
    }
  }
}
