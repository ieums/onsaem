class ApplicantModel {
  const ApplicantModel({
    required this.applicationId,
    required this.tutorId,
    required this.appliedAt,
    required this.status,
    required this.name,
    required this.school,
    required this.major,
    required this.ratingAvg,
    required this.reviewCount,
    required this.lessonCount,
    required this.bio,
    required this.profileImageUrl,
    required this.isOnline,
    required this.isAvailable,
    required this.avgResponseMinutes,
    required this.subjects,
  });

  final int applicationId;
  final int tutorId;
  final DateTime appliedAt;
  final String status;
  final String name;
  final String school;
  final String major;
  final double ratingAvg;
  final int reviewCount;
  final int lessonCount;
  final String? bio;
  final String? profileImageUrl;
  final bool isOnline;
  final bool isAvailable;
  final int avgResponseMinutes;
  final List<String> subjects;

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    return ApplicantModel(
      applicationId: json['applicationId'] as int,
      tutorId: json['tutorId'] as int,
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      status: json['status'] as String? ?? '',
      name: json['name'] as String? ?? '',
      school: json['school'] as String? ?? '',
      major: json['major'] as String? ?? '',
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      lessonCount: json['lessonCount'] as int? ?? 0,
      bio: json['bio'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? true,
      isAvailable: true,
      avgResponseMinutes: json['avgResponseMinutes'] as int? ?? 0,
      subjects: (json['subjects'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  ApplicantModel copyWith({
    int? applicationId,
    int? tutorId,
    DateTime? appliedAt,
    String? status,
    String? name,
    String? school,
    String? major,
    double? ratingAvg,
    int? reviewCount,
    int? lessonCount,
    String? bio,
    String? profileImageUrl,
    bool? isOnline,
    bool? isAvailable,
    int? avgResponseMinutes,
    List<String>? subjects,
  }) {
    return ApplicantModel(
      applicationId: applicationId ?? this.applicationId,
      tutorId: tutorId ?? this.tutorId,
      appliedAt: appliedAt ?? this.appliedAt,
      status: status ?? this.status,
      name: name ?? this.name,
      school: school ?? this.school,
      major: major ?? this.major,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      reviewCount: reviewCount ?? this.reviewCount,
      lessonCount: lessonCount ?? this.lessonCount,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isOnline: isOnline ?? this.isOnline,
      isAvailable: isAvailable ?? this.isAvailable,
      avgResponseMinutes: avgResponseMinutes ?? this.avgResponseMinutes,
      subjects: subjects ?? this.subjects,
    );
  }
}
