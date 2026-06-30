/// POST /problems 응답.
/// - needsSelection=true  : 한 이미지에서 여러 문제 감지 → 학생이 인덱스 선택 후 재요청
/// - needsSelection=false : 단일 문제로 등록 완료 (id 등 채워짐)
class ProblemCreateResult {
  const ProblemCreateResult({
    required this.needsSelection,
    this.needsClassification = false,
    this.multiPage = false,
    this.detectionId,
    this.id,
    this.studentId,
    this.summary,
    this.subject,
    this.difficulty,
    this.examType,
    this.primaryType,
    this.secondaryType,
    this.imageUrls = const [],
    this.status,
    this.createdAt,
    this.allDetected = const [],
  });

  final bool needsSelection;
  final bool needsClassification; // 분류 API 실패 → 분류 수정 화면으로 유도
  final bool multiPage; // 여러 장 한 문제 → 수정 화면에서 페이지 순서 재정렬 노출
  final String? detectionId; // 선택 시 /problems/select에 전달 (재OCR 방지)
  final int? id;
  final int? studentId;
  final String? summary;
  final String? subject;
  final String? difficulty;
  final String? examType;
  final String? primaryType;   // AI 분류 대분류 (성공 시 채워짐)
  final String? secondaryType; // AI 분류 소분류 (성공 시 채워짐)
  final List<String> imageUrls;
  final String? status;
  final DateTime? createdAt;

  /// needsSelection=true일 때 감지된 문제 후보들 (학생이 하나 선택).
  final List<DetectedProblem> allDetected;

  bool get isRegistered => !needsSelection && id != null;

  factory ProblemCreateResult.fromJson(Map<String, dynamic> json) {
    final detectedRaw = json['allDetected'] as List? ?? const [];
    return ProblemCreateResult(
      needsSelection: json['needsSelection'] as bool? ?? false,
      needsClassification: json['needsClassification'] as bool? ?? false,
      multiPage: json['multiPage'] as bool? ?? false,
      detectionId: json['detectionId'] as String?,
      id: json['id'] as int?,
      studentId: json['studentId'] as int?,
      summary: json['summary'] as String?,
      subject: json['subject'] as String?,
      difficulty: json['difficulty'] as String?,
      examType: json['examType'] as String?,
      primaryType: json['primaryType'] as String?,
      secondaryType: json['secondaryType'] as String?,
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? const []),
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      allDetected: detectedRaw
          .map((e) => DetectedProblem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 한 이미지에서 감지된 개별 문제(선택 후보).
class DetectedProblem {
  const DetectedProblem({
    this.summary,
    this.extractedText,
    this.subject,
    this.difficulty,
    this.problemNumber,
  });

  final String? summary;
  final String? extractedText;
  final String? subject;
  final String? difficulty;
  final int? problemNumber; // OCR 인식 문제 번호(있으면 'N번' 표시)

  factory DetectedProblem.fromJson(Map<String, dynamic> json) {
    return DetectedProblem(
      summary: json['summary'] as String?,
      extractedText: json['extractedText'] as String?,
      subject: json['subject'] as String?,
      difficulty: json['difficulty'] as String?,
      problemNumber: json['problemNumber'] as int?,
    );
  }

  /// 목록에 보여줄 미리보기 텍스트.
  /// summary 우선. 리터럴 "\n"·중복 공백을 정리해 한 줄로 깔끔하게 보여준다.
  String get preview {
    final s = _oneLine(summary);
    if (s.isNotEmpty) return s;
    final t = _oneLine(extractedText);
    if (t.isNotEmpty) return t.length > 60 ? '${t.substring(0, 60)}…' : t;
    return '문제 내용 미리보기 없음';
  }

  static String _oneLine(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll('\\n', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// GET /problems/student 항목 (내 문제 목록).
class StudentProblemModel {
  const StudentProblemModel({
    required this.problemId,
    this.summary,
    this.subject,
    this.primaryType,
    this.secondaryType,
    this.difficulty,
    this.examType,
    this.status,
    required this.searching,
    this.searchDeadline,
    required this.createdAt,
    this.imageUrls = const [],
    this.applicantCount = 0,
    this.multiPage = false,
    this.lessonId,
  });

  final int problemId;
  final String? summary;
  final String? subject;
  final String? primaryType;
  final String? secondaryType;
  final String? difficulty;
  final String? examType;
  final String? status;
  final bool searching;
  final DateTime? searchDeadline;
  final DateTime createdAt;
  final List<String> imageUrls;
  final int applicantCount;
  final bool multiPage; // 여러 장 한 문제 → 페이지 순서 재정렬 가능
  final int? lessonId; // 매칭/풀이 완료 문제의 강의 id(복습 진입용). 없으면 null

  factory StudentProblemModel.fromJson(Map<String, dynamic> json) {
    return StudentProblemModel(
      problemId: json['problemId'] as int,
      summary: json['summary'] as String?,
      subject: json['subject'] as String?,
      primaryType: json['primaryType'] as String?,
      secondaryType: json['secondaryType'] as String?,
      difficulty: json['difficulty'] as String?,
      examType: json['examType'] as String?,
      status: json['status'] as String?,
      searching: json['searching'] as bool? ?? false,
      searchDeadline: json['searchDeadline'] != null
          ? DateTime.tryParse(json['searchDeadline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? const []),
      applicantCount: json['applicantCount'] as int? ?? 0,
      multiPage: json['multiPage'] as bool? ?? false,
      lessonId: json['lessonId'] as int?,
    );
  }

  /// 등록 응답(ProblemCreateResult)을 분류 수정 화면용 모델로 변환.
  /// AI 분류 성공 시 primary/secondaryType이 응답에 실려오므로 그대로 전달 →
  /// 수정 화면에 대분류·소분류가 미리 선택돼 보인다.
  factory StudentProblemModel.fromCreateResult(ProblemCreateResult r) {
    return StudentProblemModel(
      problemId: r.id ?? 0,
      summary: r.summary,
      subject: r.subject,
      difficulty: r.difficulty,
      examType: r.examType,
      primaryType: r.primaryType,
      secondaryType: r.secondaryType,
      status: r.status,
      searching: false,
      createdAt: r.createdAt ?? DateTime.now(),
      imageUrls: r.imageUrls,
      multiPage: r.multiPage,
    );
  }
}
