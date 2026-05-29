class ChatMessage {
  final String id;
  final String sessionId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isLoading = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      sessionId: json['session_id']?.toString() ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'role': role,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? role,
    String? content,
    DateTime? createdAt,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TarguiSession {
  final String id;
  final String titre;
  final String? enrollmentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const TarguiSession({
    required this.id,
    required this.titre,
    this.enrollmentId,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
  });

  factory TarguiSession.fromJson(Map<String, dynamic> json) {
    return TarguiSession(
      id: json['id']?.toString() ?? '',
      titre: json['titre'] ?? 'Nouvelle conversation',
      enrollmentId: json['enrollment_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      messageCount: json['message_count'] ?? 0,
    );
  }
}
