// 마이페이지 '내 활동' 모델 (내 리뷰 / 내 신고).
// reviews/reports는 ApiResponse 래핑 → repository에서 res.data['data'] 파싱.

DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v as String);

/// 내가 쓴 리뷰 (GET /reviews/me).
class MyReview {
  const MyReview({
    required this.id,
    this.tutorId,
    this.lessonId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  final int id;
  final int? tutorId;
  final int? lessonId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  factory MyReview.fromJson(Map<String, dynamic> j) => MyReview(
        id: (j['id'] as num).toInt(),
        tutorId: (j['tutorId'] as num?)?.toInt(),
        lessonId: (j['lessonId'] as num?)?.toInt(),
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        comment: j['comment'] as String?,
        createdAt: _date(j['createdAt']),
      );
}

/// 내가 접수한 신고 (GET /reports/me).
class MyReport {
  const MyReport({
    required this.id,
    this.targetType,
    this.targetId,
    this.lessonId,
    this.reasons = const [],
    this.description,
    this.status,
    this.createdAt,
  });

  final int id;
  final String? targetType; // TUTOR/STUDENT/LESSON/REVIEW
  final int? targetId;
  final int? lessonId;
  final List<String> reasons; // ReportReason enum names
  final String? description;
  final String? status; // PENDING 등
  final DateTime? createdAt;

  factory MyReport.fromJson(Map<String, dynamic> j) => MyReport(
        id: (j['id'] as num).toInt(),
        targetType: j['targetType'] as String?,
        targetId: (j['targetId'] as num?)?.toInt(),
        lessonId: (j['lessonId'] as num?)?.toInt(),
        reasons: List<String>.from(j['reasons'] as List? ?? const []),
        description: j['description'] as String?,
        status: j['status'] as String?,
        createdAt: _date(j['createdAt']),
      );
}
