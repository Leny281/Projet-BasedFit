import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import '../models/event_model.dart';

class EventService {
  /// Crée un nouvel événement pour une salle
  static Future<int> createEvent(Event event) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('events', event.toMap());
  }

  /// Récupère tous les événements d'une salle
  static Future<List<Event>> getEventsByGym(int gymId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'events',
      where: 'gym_id = ?',
      whereArgs: [gymId],
      orderBy: 'created_at DESC',
    );
    return results.map((map) => Event.fromMap(map)).toList();
  }

  /// Récupère un événement par son ID
  static Future<Event?> getEventById(int eventId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Event.fromMap(results.first);
  }

  /// Met à jour un événement
  static Future<int> updateEvent(Event event) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  /// Supprime un événement
  static Future<int> deleteEvent(int eventId) async {
    final db = await AppDatabase.instance.database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  /// Inscrit un utilisateur à un événement
  static Future<bool> joinEvent(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;

    // Vérifier si l'événement existe et n'est pas complet
    final event = await getEventById(eventId);
    if (event == null) return false;

    // Compter le nombre de participants actuels
    final participantCount = await getParticipantCount(eventId);
    if (participantCount >= event.maxParticipants) {
      return false; // Événement complet
    }

    // Vérifier si l'utilisateur n'est pas déjà inscrit
    final alreadyJoined = await isUserJoined(eventId, userId);
    if (alreadyJoined) return false;

    // Inscrire l'utilisateur
    try {
      final participant = EventParticipant(
        eventId: eventId,
        userId: userId,
        joinedAt: DateTime.now(),
      );
      await db.insert('event_participants', participant.toMap());
      return true;
    } catch (e) {
      print('Erreur lors de l\'inscription à l\'événement: $e');
      return false;
    }
  }

  /// Désinscrit un utilisateur d'un événement
  static Future<bool> leaveEvent(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.delete(
      'event_participants',
      where: 'event_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
    );
    return result > 0;
  }

  /// Vérifie si un utilisateur est inscrit à un événement
  static Future<bool> isUserJoined(int eventId, int userId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'event_participants',
      where: 'event_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Récupère le nombre de participants à un événement
  static Future<int> getParticipantCount(int eventId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM event_participants WHERE event_id = ?',
      [eventId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Récupère la liste des participants à un événement avec leurs infos
  static Future<List<Map<String, dynamic>>> getEventParticipants(int eventId) async {
    final db = await AppDatabase.instance.database;
    return await db.rawQuery('''
      SELECT u.id, u.first_name, u.last_name, u.email, ep.joined_at
      FROM event_participants ep
      INNER JOIN users u ON ep.user_id = u.id
      WHERE ep.event_id = ?
      ORDER BY ep.joined_at ASC
    ''', [eventId]);
  }

  /// Récupère les événements auxquels un utilisateur est inscrit
  static Future<List<Event>> getUserEvents(int userId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.rawQuery('''
      SELECT e.*
      FROM events e
      INNER JOIN event_participants ep ON e.id = ep.event_id
      WHERE ep.user_id = ?
      ORDER BY e.created_at DESC
    ''', [userId]);
    return results.map((map) => Event.fromMap(map)).toList();
  }

  /// Récupère tous les événements des salles favorites d'un utilisateur
  static Future<List<Map<String, dynamic>>> getEventsForUser(int userId) async {
    final db = await AppDatabase.instance.database;
    return await db.rawQuery('''
      SELECT 
        e.*,
        g.name as gym_name,
        (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id) as participant_count,
        (SELECT COUNT(*) FROM event_participants WHERE event_id = e.id AND user_id = ?) as is_joined
      FROM events e
      INNER JOIN gyms g ON e.gym_id = g.id
      INNER JOIN user_gym_favorites ugf ON g.id = ugf.gym_id
      WHERE ugf.user_id = ?
      ORDER BY e.created_at DESC
    ''', [userId, userId]);
  }
}
