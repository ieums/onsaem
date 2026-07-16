import 'searching_problem_model.dart';

class TutorApplicationModel {
  const TutorApplicationModel({
    required this.applicationId,
    required this.problemId,
    required this.status,
    required this.appliedAt,
    this.summary,
    this.studentDescription,
    this.subject,
    this.primaryType,
    this.secondaryType,
    this.difficulty,
    this.examType,
    required this.imageUrls,
    this.searchDeadline,
    required this.createdAt,
    required this.searching,
  });

  final int applicationId;
  final int problemId;
  final String status;
  final DateTime appliedAt;
  final String? summary;
  final String? studentDescription;
  final String? subject;
  final String? primaryType;
  final String? secondaryType;
  final String? difficulty;
  final String? examType;
  final List<String> imageUrls;
  final DateTime? searchDeadline;
  final DateTime createdAt;
  final bool searching;

  factory TutorApplicationModel.fromJson(Map<String, dynamic> json) {
    return TutorApplicationModel(
      applicationId: json['applicationId'] as int,
      problemId: json['problemId'] as int,
      status: json['status'] as String? ?? 'PENDING',
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      summary: json['summary'] as String?,
      studentDescription: json['studentDescription'] as String?,
      subject: json['subject'] as String?,
      primaryType: json['primaryType'] as String?,
      secondaryType: json['secondaryType'] as String?,
      difficulty: json['difficulty'] as String?,
      examType: json['examType'] as String?,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? []),
      searchDeadline: json['searchDeadline'] != null
          ? DateTime.parse(json['searchDeadline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      searching: json['searching'] as bool? ?? false,
    );
  }

  String get subjectLabel {
    const map = {
      'MATH': '수학',
      'KOREAN': '국어',
      'ENGLISH': '영어',
      'SCIENCE': '과학',
      'SOCIAL': '사회',
    };
    return map[subject] ?? '-';
  }

  String get statusLabel {
    const map = {
      'PENDING': '신청 중',
      'CONFIRMING': '수락 대기 중',
      'ACCEPTED': '매칭 완료',
      'UNAVAILABLE': '수업 중',
    };
    return map[status] ?? status;
  }

  SearchingProblemModel toSearchingProblem() {
    return SearchingProblemModel(
      problemId: problemId,
      studentId: 0,
      summary: summary,
      studentDescription: studentDescription,
      subject: subject,
      primaryType: primaryType,
      secondaryType: secondaryType,
      difficulty: difficulty,
      examType: examType,
      imageUrls: imageUrls,
      searchDeadline: searchDeadline,
      createdAt: createdAt,
      alreadyApplied: true,
    );
  }
}
