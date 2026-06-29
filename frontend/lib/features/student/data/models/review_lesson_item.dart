/// 복습 목록 아이템 (완료된 강의 1건).
/// ready=false면 "복습 준비중"(전사/요약 처리 중)으로 진입 불가.
class ReviewLessonItem {
  final int lessonId;
  final String title;
  final bool ready;
  final int? sessionId;
  final DateTime? endedAt;
  final String? subject;

  const ReviewLessonItem({
    required this.lessonId,
    required this.title,
    required this.ready,
    this.sessionId,
    this.endedAt,
    this.subject,
  });

  factory ReviewLessonItem.fromJson(Map<String, dynamic> json) {
    return ReviewLessonItem(
      lessonId: json['lessonId'] as int,
      title: json['title'] as String? ?? '복습',
      ready: json['ready'] as bool? ?? false,
      sessionId: json['sessionId'] as int?,
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.tryParse(json['endedAt'] as String),
      subject: json['subject'] as String?,
    );
  }
}