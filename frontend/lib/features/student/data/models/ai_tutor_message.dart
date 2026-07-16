enum AiTutorRole {
  user,
  ai;

  static AiTutorRole fromString(String v) =>
      v.toUpperCase() == 'USER' ? AiTutorRole.user : AiTutorRole.ai;

  bool get isUser => this == AiTutorRole.user;
}

class AiTutorMessage {
  final int messageId;
  final AiTutorRole role;
  final String content;
  final DateTime createdAt;
  final bool isFailed;

  const AiTutorMessage({
    required this.messageId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isFailed = false,
  });

  factory AiTutorMessage.fromJson(Map<String, dynamic> json) {
    return AiTutorMessage(
      messageId: json['messageId'] as int,
      role: AiTutorRole.fromString(json['role'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AiTutorMessage copyWith({bool? isFailed}) {
    return AiTutorMessage(
      messageId: messageId,
      role: role,
      content: content,
      createdAt: createdAt,
      isFailed: isFailed ?? this.isFailed,
    );
  }
}