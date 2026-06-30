class AiTutorSession {
  const AiTutorSession({
    required this.sessionId,
    required this.problemId,
    required this.title,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.messageCount = 0,
    this.lastMessage,
  });

  final int sessionId;
  final int problemId;
  final String title;
  final AiTutorSessionStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// 이 세션에 쌓인 메시지 수. 0이면 입장만 하고 아직 질문은 안 한 상태.
  final int messageCount;

  /// 카톡식 미리보기 — 마지막 메시지(보통 AI 답변)의 첫 줄.
  final String? lastMessage;

  /// 질문을 한 번이라도 했는가('이어서' 노출 판단).
  bool get hasStarted => messageCount > 0;

  factory AiTutorSession.fromJson(Map<String, dynamic> json) {
    final preview = json['lastMessage'] as String?;
    return AiTutorSession(
      sessionId: json['sessionId'] as int,
      problemId: json['problemId'] as int,
      title: json['title'] as String? ?? 'AI 튜터',
      status: AiTutorSessionStatus.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      messageCount: json['messageCount'] as int? ?? 0,
      lastMessage:
          (preview != null && preview.trim().isNotEmpty) ? preview.trim() : null,
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