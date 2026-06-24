enum LessonReviewSessionStatus {
  active,
  closed;

  static LessonReviewSessionStatus fromString(String v) =>
      v.toUpperCase() == 'CLOSED'
          ? LessonReviewSessionStatus.closed
          : LessonReviewSessionStatus.active;

  bool get isClosed => this == LessonReviewSessionStatus.closed;
}

class LessonReviewSession {
  final int sessionId;
  final int lessonId;
  final String title;
  final LessonReviewSessionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LessonReviewSession({
    required this.sessionId,
    required this.lessonId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory LessonReviewSession.fromJson(Map<String, dynamic> json) {
    return LessonReviewSession(
      sessionId: json['sessionId'] as int,
      lessonId: json['lessonId'] as int,
      title: json['title'] as String,
      status: LessonReviewSessionStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
}