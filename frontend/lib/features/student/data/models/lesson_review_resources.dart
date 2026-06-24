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
      pdfUrl: json['pdfUrl'] as String?,
      recordingUrl: json['recordingUrl'] as String?,
    );
  }
}