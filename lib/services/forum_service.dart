import '../models/forum_model.dart';
import '../data/app_database.dart';
import 'auth_service.dart';

class ForumService {
  static final ForumService _instance = ForumService._internal();
  factory ForumService() => _instance;
  ForumService._internal();

  final AppDatabase _dbProvider = AppDatabase.instance;
  final AuthService _authService = AuthService();

  // Créer un nouveau forum
  Future<int?> createForum({
    required String title,
    required String description,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    final db = await _dbProvider.database;
    
    final forumId = await db.insert('forums', {
      'title': title,
      'description': description,
      'created_by_user_id': currentUser.id,
      'created_at': DateTime.now().toIso8601String(),
      'message_count': 0,
    });

    return forumId;
  }

  // Récupérer tous les forums
  Future<List<Forum>> getAllForums() async {
    final db = await _dbProvider.database;
    
    final result = await db.rawQuery('''
      SELECT f.*, u.first_name, u.last_name
      FROM forums f
      INNER JOIN users u ON f.created_by_user_id = u.id
      ORDER BY f.created_at DESC
    ''');

    return result.map((map) {
      final userName = '${map['first_name']} ${map['last_name']}';
      return Forum.fromMap(map, userName);
    }).toList();
  }

  // Récupérer un forum par ID
  Future<Forum?> getForum(int forumId) async {
    final db = await _dbProvider.database;
    
    final result = await db.rawQuery('''
      SELECT f.*, u.first_name, u.last_name
      FROM forums f
      INNER JOIN users u ON f.created_by_user_id = u.id
      WHERE f.id = ?
    ''', [forumId]);

    if (result.isEmpty) return null;

    final map = result.first;
    final userName = '${map['first_name']} ${map['last_name']}';
    return Forum.fromMap(map, userName);
  }

  // Supprimer un forum (admin uniquement)
  Future<bool> deleteForum(int forumId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    final db = await _dbProvider.database;
    
    // Vérifier si l'utilisateur est admin
    final userResult = await db.query(
      'users',
      where: 'id = ? AND is_admin = 1',
      whereArgs: [currentUser.id],
    );

    if (userResult.isEmpty) return false;

    await db.delete(
      'forums',
      where: 'id = ?',
      whereArgs: [forumId],
    );

    return true;
  }

  // Ajouter un message à un forum
  Future<int?> addMessage({
    required int forumId,
    required String message,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return null;

    final db = await _dbProvider.database;
    
    final messageId = await db.insert('forum_messages', {
      'forum_id': forumId,
      'user_id': currentUser.id,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Incrémenter le compteur de messages du forum
    await db.rawUpdate('''
      UPDATE forums 
      SET message_count = message_count + 1 
      WHERE id = ?
    ''', [forumId]);

    return messageId;
  }

  // Récupérer tous les messages d'un forum
  Future<List<ForumMessage>> getForumMessages(int forumId) async {
    final db = await _dbProvider.database;
    
    final result = await db.rawQuery('''
      SELECT fm.*, u.first_name, u.last_name
      FROM forum_messages fm
      INNER JOIN users u ON fm.user_id = u.id
      WHERE fm.forum_id = ?
      ORDER BY fm.created_at ASC
    ''', [forumId]);

    return result.map((map) {
      final userName = '${map['first_name']} ${map['last_name']}';
      return ForumMessage.fromMap(map, userName);
    }).toList();
  }

  // Vérifier si l'utilisateur actuel est admin
  Future<bool> isCurrentUserAdmin() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return false;

    final db = await _dbProvider.database;
    
    final result = await db.query(
      'users',
      where: 'id = ? AND is_admin = 1',
      whereArgs: [currentUser.id],
    );

    return result.isNotEmpty;
  }

  // Définir un utilisateur comme admin (uniquement pour le développement/setup)
  Future<void> setUserAsAdmin(int userId) async {
    final db = await _dbProvider.database;
    await db.update(
      'users',
      {'is_admin': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
