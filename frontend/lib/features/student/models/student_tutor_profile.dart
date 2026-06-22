class StudentTutorReview {
  const StudentTutorReview({
    required this.studentLabel,
    required this.dateLabel,
    required this.rating,
    required this.body,
  });

  final String studentLabel;
  final String dateLabel;
  final double rating;
  final String body;
}

class StudentTutorProfile {
  const StudentTutorProfile({
    required this.id,
    required this.name,
    required this.avatarInitial,
    required this.isOnline,
    required this.department,
    required this.university,
    required this.rating,
    required this.reviewCount,
    required this.lessonCount,
    required this.avgResponseMinutes,
    required this.introLine,
    required this.introBody,
    required this.styles,
    required this.subjects,
    required this.reviews,
  });

  final String id;
  final String name;
  final String avatarInitial;
  final bool isOnline;
  final String department;
  final String university;
  final double rating;
  final int reviewCount;
  final int lessonCount;
  final int avgResponseMinutes;
  final String introLine;
  final String introBody;
  final List<String> styles;
  final List<String> subjects;
  final List<StudentTutorReview> reviews;

  String get educationLine => '$university $department';

  String get ratingLabel => '$rating ($reviewCount개 리뷰)';
}
