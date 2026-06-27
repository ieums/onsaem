/// AI 튜터 상단 배너에 띄울 문제 정보 (GET /problems/{id} 응답 중 일부).
class AiTutorProblem {
  final List<String> imageUrls;
  final String? summary;
  final String? extractedText;

  const AiTutorProblem({
    this.imageUrls = const [],
    this.summary,
    this.extractedText,
  });

  factory AiTutorProblem.fromJson(Map<String, dynamic> json) {
    return AiTutorProblem(
      imageUrls: List<String>.from(json['imageUrls'] as List? ?? const []),
      summary: json['summary'] as String?,
      extractedText: json['extractedText'] as String?,
    );
  }
}