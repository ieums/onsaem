class TutorReviewItem {
  const TutorReviewItem({
    this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.studentName,
  });

  /// 리뷰 신고(targetType=REVIEW)의 targetId. 백엔드 재배포 전이면 null → 신고 버튼 숨김.
  final int? id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? studentName;

  factory TutorReviewItem.fromJson(Map<String, dynamic> json) {
    return TutorReviewItem(
      id: (json['id'] as num?)?.toInt(),
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      studentName: json['studentName'] as String?,
    );
  }
}

class TutorProfileDetail {
  const TutorProfileDetail({
    required this.id,
    required this.name,
    this.profileImageUrl,
    this.school,
    this.major,
    this.bio,
    required this.subjects,
    this.ratingAvg,
    required this.reviewCount,
    required this.lessonCount,
    required this.isAvailable,
    required this.reviews,
  });

  final int id;
  final String name;
  final String? profileImageUrl;
  final String? school;
  final String? major;
  final String? bio;
  final List<String> subjects;
  final double? ratingAvg;
  final int reviewCount;
  final int lessonCount;
  final bool isAvailable;
  final List<TutorReviewItem> reviews;

  factory TutorProfileDetail.fromJson(Map<String, dynamic> json) {
    return TutorProfileDetail(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      school: json['school'] as String?,
      major: json['major'] as String?,
      bio: json['bio'] as String?,
      subjects: (json['subjects'] as List<dynamic>? ?? []).cast<String>(),
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int? ?? 0,
      lessonCount: json['lessonCount'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((e) => TutorReviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
