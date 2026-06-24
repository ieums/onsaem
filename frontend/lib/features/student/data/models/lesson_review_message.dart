enum LessonReviewRole {
  user,
  ai;

  static LessonReviewRole fromString(String v) =>
      v.toUpperCase() == 'USER' ? LessonReviewRole.user : LessonReviewRole.ai;

  bool get isUser => this == LessonReviewRole.user;
}

class LessonReviewMessage {
  final int messageId;
  final LessonReviewRole role;
  final String content;
  final DateTime createdAt;

  const LessonReviewMessage({
    required this.messageId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory LessonReviewMessage.fromJson(Map<String, dynamic> json) {
    return LessonReviewMessage(
      messageId: json['messageId'] as int,
      role: LessonReviewRole.fromString(json['role'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}