class AiTutorSession {
  const AiTutorSession({
    required this.sessionId,
    required this.problemId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final int sessionId;
  final int problemId;
  final String title;
  final AiTutorSessionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory AiTutorSession.fromJson(Map<String, dynamic> json) {
    return AiTutorSession(
      sessionId: json['sessionId'] as int,
      problemId: json['problemId'] as int,
      title: json['title'] as String? ?? 'AI 튜터',
      status: AiTutorSessionStatus.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}

enum AiTutorSessionStatus {
  active,
  closed;

  bool get isClosed => this == AiTutorSessionStatus.closed;

  static AiTutorSessionStatus fromString(String? value) {
    return (value?.toUpperCase() == 'CLOSED')
        ? AiTutorSessionStatus.closed
        : AiTutorSessionStatus.active;
  }
}