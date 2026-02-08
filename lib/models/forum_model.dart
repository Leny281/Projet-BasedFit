class Forum {
  final int? id;
  final String title;
  final String description;
  final int createdByUserId;
  final String createdByUserName;
  final DateTime createdAt;
  final int messageCount;

  Forum({
    this.id,
    required this.title,
    required this.description,
    required this.createdByUserId,
    required this.createdByUserName,
    required this.createdAt,
    this.messageCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'created_by_user_id': createdByUserId,
      'created_at': createdAt.toIso8601String(),
      'message_count': messageCount,
    };
  }

  factory Forum.fromMap(Map<String, dynamic> map, String createdByUserName) {
    return Forum(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      createdByUserId: map['created_by_user_id'] as int,
      createdByUserName: createdByUserName,
      createdAt: DateTime.parse(map['created_at'] as String),
      messageCount: map['message_count'] as int? ?? 0,
    );
  }
}

class ForumMessage {
  final int? id;
  final int forumId;
  final int userId;
  final String userName;
  final String message;
  final DateTime createdAt;

  ForumMessage({
    this.id,
    required this.forumId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'forum_id': forumId,
      'user_id': userId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ForumMessage.fromMap(Map<String, dynamic> map, String userName) {
    return ForumMessage(
      id: map['id'] as int,
      forumId: map['forum_id'] as int,
      userId: map['user_id'] as int,
      userName: userName,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
