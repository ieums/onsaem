/// 학생이 아직 수락하지 않은 매칭 요청(앱을 껐다 켰을 때 홈 배너로 복구).
class PendingConfirm {
  const PendingConfirm({
    required this.problemId,
    required this.tutorId,
    required this.tutorName,
    this.subject,
    this.questionSummary,
  });

  final int problemId;
  final int tutorId;
  final String tutorName;
  final String? subject;
  final String? questionSummary;

  factory PendingConfirm.fromJson(Map<String, dynamic> json) {
    return PendingConfirm(
      problemId: (json['problemId'] as num).toInt(),
      tutorId: (json['tutorId'] as num).toInt(),
      tutorName: json['tutorName'] as String? ?? '강사',
      subject: json['subject'] as String?,
      questionSummary: json['questionSummary'] as String?,
    );
  }
}
