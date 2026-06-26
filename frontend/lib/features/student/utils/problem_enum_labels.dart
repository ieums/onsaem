/// 백엔드 enum name → 한글 표시 라벨.
/// 백엔드(Spring)는 enum을 name(예: 'MATH')으로 직렬화하므로 그 값을 키로 둔다.
library;

const Map<String, String> subjectLabels = {
  'KOREAN': '국어',
  'MATH': '수학',
  'ENGLISH': '영어',
  'SOCIAL': '사회',
  'SCIENCE': '과학',
  'UNKNOWN': '미분류',
};

const Map<String, String> difficultyLabels = {
  'EASY': '쉬움',
  'MEDIUM': '보통',
  'HARD': '어려움',
};

const Map<String, String> examTypeLabels = {
  'SUNUNG': '수능',
  'MOCK_EVALUATION': '평가원 모의고사',
  'ACADEMIC_EVALUATION': '학력평가',
  'EBS_SUNEUNG_TEUKGANG': 'EBS 수능특강',
  'EBS_SUNEUNG_WANSUNG': 'EBS 수능완성',
  'SCHOOL_INTERNAL': '학교 내신',
  'ACADEMY': '학원/N제',
  'OTHER': '기타',
  'UNKNOWN': '미분류',
};

const Map<String, String> statusLabels = {
  'PENDING': '매칭 대기',
  'MATCHED': '매칭 완료',
  'RESOLVED': '풀이 완료',
  'EXPIRED': '만료됨',
  'CANCELED': '취소됨',
};

/// 과목 표시 라벨. enum name('MATH')이면 한글로 변환하고,
/// 이미 한글 표시명('수학')으로 들어와도 그대로 반환한다(이중 적용 안전).
String subjectLabel(String? name) {
  if (name == null || name.isEmpty) return '미분류';
  final byName = subjectLabels[name];
  if (byName != null) return byName;
  if (subjectLabels.containsValue(name)) return name; // 이미 라벨
  return '미분류';
}
String difficultyLabel(String? name) => difficultyLabels[name] ?? '-';
String examTypeLabel(String? name) => examTypeLabels[name] ?? '미분류';
String statusLabel(String? name) => statusLabels[name] ?? (name ?? '-');
