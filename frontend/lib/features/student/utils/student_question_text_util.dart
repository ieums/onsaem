abstract final class StudentQuestionTextUtil {
  static String summarize(String text, {int maxLength = 52}) {
    final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return '업로드한 문제';
    if (trimmed.length <= maxLength) return trimmed;
    return '${trimmed.substring(0, maxLength)}…';
  }

  static String waitingLabel(DateTime startedAt) {
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    if (seconds < 5) return '방금 요청';
    if (seconds < 60) return '$seconds초 대기 중';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes분 대기 중';
    return '${minutes ~/ 60}시간 대기 중';
  }
}
