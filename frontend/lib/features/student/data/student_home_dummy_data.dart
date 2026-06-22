import 'package:ieum/core/utils/date_format_util.dart';

/// 학생 홈 탭 더미 데이터
abstract final class StudentHomeDummyData {
  static const studentName = '테스트';
  static const studentNickname = '닉네임';

  static const pendingQuestions = [
    StudentPendingQuestion(
      id: 'pq-1',
      subject: '수학',
      tutorName: '김선생',
      minutesAgo: 5,
    ),
    StudentPendingQuestion(
      id: 'pq-2',
      subject: '영어',
      tutorName: '이선생',
      minutesAgo: 12,
    ),
    StudentPendingQuestion(
      id: 'pq-3',
      subject: '국어',
      tutorName: '박선생',
      minutesAgo: 18,
    ),
  ];

  static const recentLessonsPageSize = 10;

  static final recentLessons = [
    StudentRecentLesson(
      id: 'rl-1',
      subject: '수학',
      tutorName: '김선생',
      question: '이 문제풀이에 미분 활용이 왜 꼭 필요한지에 대해 궁금해요!',
      recordedAt: DateTime(2024, 5, 18, 19, 32, 10),
      rating: 5,
      avatarInitial: '김',
    ),
    StudentRecentLesson(
      id: 'rl-2',
      subject: '영어',
      tutorName: '이선생',
      question: '관계대명사 that과 which의 차이를 수능 지문 예시로 설명해 주세요.',
      recordedAt: DateTime(2024, 5, 15, 16, 45, 28),
      rating: 4.5,
      avatarInitial: '이',
    ),
    StudentRecentLesson(
      id: 'rl-3',
      subject: '과학',
      tutorName: '최선생',
      question: '뉴턴 제2법칙과 에너지 보존 법칙을 연결해서 설명해 주실 수 있나요?',
      recordedAt: DateTime(2024, 5, 10, 14, 20, 00),
      rating: 5,
      avatarInitial: '최',
    ),
    StudentRecentLesson(
      id: 'rl-4',
      subject: '국어',
      tutorName: '박선생',
      question: '비문학 지문에서 필자의 논지와 근거를 어떻게 연결해 읽어야 할까요?',
      recordedAt: DateTime(2024, 5, 8, 11, 05, 42),
      rating: 4,
      avatarInitial: '박',
    ),
    StudentRecentLesson(
      id: 'rl-5',
      subject: '사회',
      tutorName: '정선생',
      question: '인구 구조 변화가 노동 시장과 경제 성장에 미치는 영향을 정리해 주세요.',
      recordedAt: DateTime(2024, 5, 5, 10, 18, 33),
      rating: 5,
      avatarInitial: '정',
    ),
    StudentRecentLesson(
      id: 'rl-6',
      subject: '수학',
      tutorName: '한선생',
      question: '확률 문제에서 순열과 조합, 중복을 어떻게 구분해야 하나요?',
      recordedAt: DateTime(2024, 5, 2, 18, 52, 14),
      rating: 4.5,
      avatarInitial: '한',
    ),
  ];
}

class StudentPendingQuestion {
  const StudentPendingQuestion({
    required this.id,
    required this.subject,
    required this.tutorName,
    required this.minutesAgo,
  });

  final String id;
  final String subject;
  final String tutorName;
  final int minutesAgo;
}

class StudentRecentLesson {
  StudentRecentLesson({
    required this.id,
    required this.subject,
    required this.tutorName,
    required this.question,
    required this.recordedAt,
    required this.rating,
    required this.avatarInitial,
  });

  final String id;
  final String subject;
  final String tutorName;
  final String question;
  final DateTime recordedAt;
  final double rating;
  final String avatarInitial;

  String get recordedAtLabel => formatDotDateTime(recordedAt);
}
