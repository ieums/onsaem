class LessonReviewResources {
  final String pdfStatus;
  final String? pdfUrl;
  final String? recordingUrl;

  const LessonReviewResources({
    required this.pdfStatus,
    this.pdfUrl,
    this.recordingUrl,
  });

  bool get hasPdf => pdfStatus == 'COMPLETED' && pdfUrl != null;
  bool get hasVideo => recordingUrl != null;

  factory LessonReviewResources.fromJson(Map<String, dynamic> json) {
    return LessonReviewResources(
      pdfStatus: json['status'] as String,
      // 백엔드 SummaryPdfResponse의 필드명은 downloadUrl (pdfUrl 아님).
      pdfUrl: json['downloadUrl'] as String?,
      recordingUrl: json['recordingUrl'] as String?,
    );
  }
}