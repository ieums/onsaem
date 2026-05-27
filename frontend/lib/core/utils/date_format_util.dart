/// 앱 공통 날짜·시간 표기: `2026.05.24 20:31:42`
String formatDotDateTime(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  final second = date.second.toString().padLeft(2, '0');
  return '${date.year}.$month.$day $hour:$minute:$second';
}

/// 정렬·비교용 파싱 (점 표기·한국어·ISO)
DateTime parseFlexibleDateTime(String value) {
  final dotted = RegExp(
    r'^(\d{4})\.(\d{2})\.(\d{2}) (\d{2}):(\d{2}):(\d{2})$',
  ).firstMatch(value.trim());
  if (dotted != null) {
    return DateTime(
      int.parse(dotted.group(1)!),
      int.parse(dotted.group(2)!),
      int.parse(dotted.group(3)!),
      int.parse(dotted.group(4)!),
      int.parse(dotted.group(5)!),
      int.parse(dotted.group(6)!),
    );
  }

  final korean = RegExp(
    r'^(\d{4})년 (\d{2})월 (\d{2})일 (\d{2}):(\d{2}):(\d{2})$',
  ).firstMatch(value.trim());
  if (korean != null) {
    return DateTime(
      int.parse(korean.group(1)!),
      int.parse(korean.group(2)!),
      int.parse(korean.group(3)!),
      int.parse(korean.group(4)!),
      int.parse(korean.group(5)!),
      int.parse(korean.group(6)!),
    );
  }

  final normalized = value.contains('T') ? value : value.replaceFirst(' ', 'T');
  return DateTime.parse(normalized);
}
