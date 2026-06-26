class SearchingProblemModel {
  const SearchingProblemModel({
    required this.problemId,
    required this.studentId,
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
    required this.alreadyApplied,
  });

  final int problemId;
  final int studentId;
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
  final bool alreadyApplied;

  factory SearchingProblemModel.fromJson(Map<String, dynamic> json) {
    return SearchingProblemModel(
      problemId: json['problemId'] as int,
      studentId: json['studentId'] as int,
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
      alreadyApplied: json['alreadyApplied'] as bool? ?? false,
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
}
