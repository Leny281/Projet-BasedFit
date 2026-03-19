class Event {
  final int? id;
  final String name;
  final String description;
  final int duration; // Durée en minutes
  final int maxParticipants;
  final String reward; // Récompense (ex: "Badge exclusif")
  final int gymId;
  final DateTime createdAt;
  final DateTime? eventDate; // Date de l'événement (optionnel si c'est un événement récurrent)

  Event({
    this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.maxParticipants,
    required this.reward,
    required this.gymId,
    required this.createdAt,
    this.eventDate,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      duration: map['duration'] as int,
      maxParticipants: map['max_participants'] as int,
      reward: map['reward'] as String,
      gymId: map['gym_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      eventDate: map['event_date'] != null 
          ? DateTime.parse(map['event_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'duration': duration,
      'max_participants': maxParticipants,
      'reward': reward,
      'gym_id': gymId,
      'created_at': createdAt.toIso8601String(),
      'event_date': eventDate?.toIso8601String(),
    };
  }

  Event copyWith({
    int? id,
    String? name,
    String? description,
    int? duration,
    int? maxParticipants,
    String? reward,
    int? gymId,
    DateTime? createdAt,
    DateTime? eventDate,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      reward: reward ?? this.reward,
      gymId: gymId ?? this.gymId,
      createdAt: createdAt ?? this.createdAt,
      eventDate: eventDate ?? this.eventDate,
    );
  }
}

class EventParticipant {
  final int? id;
  final int eventId;
  final int userId;
  final DateTime joinedAt;

  EventParticipant({
    this.id,
    required this.eventId,
    required this.userId,
    required this.joinedAt,
  });

  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      id: map['id'] as int?,
      eventId: map['event_id'] as int,
      userId: map['user_id'] as int,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'event_id': eventId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
