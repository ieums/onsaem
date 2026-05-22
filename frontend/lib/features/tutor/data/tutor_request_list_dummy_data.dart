import 'package:flutter/material.dart';
import 'package:ieum/features/tutor/data/tutor_pricing.dart';

/// 문제 신청 리스트 항목 (더미 / API 공통 형태).
class TutorRequestListItem {
  const TutorRequestListItem({
    required this.id,
    required this.subject,
    required this.subjectColor,
    required this.subjectBgColor,
    required this.detailSubject,
    required this.chapter,
    required this.minutesAgo,
    required this.classMinutes,
    required this.priceWon,
  });

  final String id;
  final String subject;
  final Color subjectColor;
  final Color subjectBgColor;
  final String detailSubject;
  final String chapter;
  final int minutesAgo;
  final int classMinutes;
  final int priceWon;

  String get timeAgo => '$minutesAgo분 전';
}

class TutorRequestSubjectTheme {
  const TutorRequestSubjectTheme({
    required this.color,
    required this.backgroundColor,
  });

  final Color color;
  final Color backgroundColor;
}

/// 수능특강 기준 시드 (월·일 없음). API 연동 시 이 파일만 교체·삭제하면 됩니다.
class TutorRequestSeed {
  TutorRequestSeed({
    required this.id,
    required this.subject,
    required this.detailSubject,
    required this.chapter,
    required this.minutesAgo,
    required this.classMinutes,
  });

  final String id;
  final String subject;
  final String detailSubject;
  final String chapter;
  final int minutesAgo;
  final int classMinutes;
}

class TutorRequestDummyData {
  TutorRequestDummyData._();

  static const subjectFilters = ['전체', '국어', '수학', '영어', '사회', '과학'];

  /// 강사 홈 「새로운 질문」 — N분 이내만 노출.
  static const newQuestionWithinMinutes = 5;

  /// 강사 홈 「새로운 질문」 페이지당 건수.
  static const newQuestionPageSize = 5;

  static int expectedPriceWon(int classMinutes) =>
      TutorPricing.expectedPriceWon(classMinutes);

  static const _themes = <String, TutorRequestSubjectTheme>{
    '국어': TutorRequestSubjectTheme(
      color: Color(0xFFE53935),
      backgroundColor: Color(0xFFFFEBEE),
    ),
    '수학': TutorRequestSubjectTheme(
      color: Color(0xFFF57C00),
      backgroundColor: Color(0xFFFFF3E0),
    ),
    '영어': TutorRequestSubjectTheme(
      color: Color(0xFFF9A825),
      backgroundColor: Color(0xFFFFF9C4),
    ),
    '사회': TutorRequestSubjectTheme(
      color: Color(0xFF43A047),
      backgroundColor: Color(0xFFE8F5E9),
    ),
    '과학': TutorRequestSubjectTheme(
      color: Color(0xFF1E88E5),
      backgroundColor: Color(0xFFE3F2FD),
    ),
  };

  /// 20건 — 대과목별 최소 1건, 수능특강 상세·단원 구성.
  /// `const` 미사용 — 더미 필드 추가·변경 시 hot reload 호환.
  static final seeds = <TutorRequestSeed>[
    // 국어
    TutorRequestSeed(
      id: 'req-01',
      subject: '국어',
      detailSubject: '화법과 작문',
      chapter: '발표·토론',
      minutesAgo: 3,
      classMinutes: 25,
    ),
    TutorRequestSeed(
      id: 'req-02',
      subject: '국어',
      detailSubject: '독서',
      chapter: '인문/예술',
      minutesAgo: 8,
      classMinutes: 35,
    ),
    TutorRequestSeed(
      id: 'req-03',
      subject: '국어',
      detailSubject: '문학',
      chapter: '현대시',
      minutesAgo: 16,
      classMinutes: 40,
    ),
    TutorRequestSeed(
      id: 'req-04',
      subject: '국어',
      detailSubject: '언어와 매체',
      chapter: '음운의 변동',
      minutesAgo: 28,
      classMinutes: 20,
    ),
    // 수학
    TutorRequestSeed(
      id: 'req-05',
      subject: '수학',
      detailSubject: '수학I',
      chapter: '지수함수와 로그함수',
      minutesAgo: 2,
      classMinutes: 30,
    ),
    TutorRequestSeed(
      id: 'req-06',
      subject: '수학',
      detailSubject: '수학II',
      chapter: '함수의 극한',
      minutesAgo: 5,
      classMinutes: 35,
    ),
    TutorRequestSeed(
      id: 'req-07',
      subject: '수학',
      detailSubject: '미적분',
      chapter: '정적분의 활용',
      minutesAgo: 14,
      classMinutes: 40,
    ),
    TutorRequestSeed(
      id: 'req-08',
      subject: '수학',
      detailSubject: '확률과 통계',
      chapter: '연속확률변수',
      minutesAgo: 4,
      classMinutes: 30,
    ),
    // 영어
    TutorRequestSeed(
      id: 'req-09',
      subject: '영어',
      detailSubject: '영어',
      chapter: '빈칸추론',
      minutesAgo: 5,
      classMinutes: 20,
    ),
    TutorRequestSeed(
      id: 'req-10',
      subject: '영어',
      detailSubject: '영어',
      chapter: '어법',
      minutesAgo: 2,
      classMinutes: 25,
    ),
    TutorRequestSeed(
      id: 'req-11',
      subject: '영어',
      detailSubject: '영어',
      chapter: '순서/문장 삽입',
      minutesAgo: 19,
      classMinutes: 30,
    ),
    // 사회
    TutorRequestSeed(
      id: 'req-12',
      subject: '사회',
      detailSubject: '정치와 법',
      chapter: '기본권의 보장과 제한',
      minutesAgo: 4,
      classMinutes: 35,
    ),
    TutorRequestSeed(
      id: 'req-13',
      subject: '사회',
      detailSubject: '경제',
      chapter: '국민소득의 측정',
      minutesAgo: 13,
      classMinutes: 30,
    ),
    TutorRequestSeed(
      id: 'req-14',
      subject: '사회',
      detailSubject: '한국지리',
      chapter: '산업 입지',
      minutesAgo: 22,
      classMinutes: 25,
    ),
    TutorRequestSeed(
      id: 'req-15',
      subject: '사회',
      detailSubject: '윤리와 사상',
      chapter: '유교의 인간상',
      minutesAgo: 31,
      classMinutes: 35,
    ),
    // 과학
    TutorRequestSeed(
      id: 'req-16',
      subject: '과학',
      detailSubject: '물리학I',
      chapter: '역학과 에너지',
      minutesAgo: 3,
      classMinutes: 30,
    ),
    TutorRequestSeed(
      id: 'req-17',
      subject: '과학',
      detailSubject: '물리학II',
      chapter: '전자기 유도',
      minutesAgo: 24,
      classMinutes: 35,
    ),
    TutorRequestSeed(
      id: 'req-18',
      subject: '과학',
      detailSubject: '화학I',
      chapter: '화학 반응식',
      minutesAgo: 1,
      classMinutes: 25,
    ),
    TutorRequestSeed(
      id: 'req-19',
      subject: '과학',
      detailSubject: '생명과학I',
      chapter: '유전과 법칙',
      minutesAgo: 5,
      classMinutes: 25,
    ),
    TutorRequestSeed(
      id: 'req-20',
      subject: '과학',
      detailSubject: '지구과학I',
      chapter: '대기와 바다',
      minutesAgo: 38,
      classMinutes: 30,
    ),
  ];

  static List<TutorRequestListItem> build() {
    return [
      for (final seed in seeds)
        TutorRequestListItem(
          id: seed.id,
          subject: seed.subject,
          subjectColor: _themes[seed.subject]!.color,
          subjectBgColor: _themes[seed.subject]!.backgroundColor,
          detailSubject: seed.detailSubject,
          chapter: seed.chapter,
          minutesAgo: seed.minutesAgo,
          classMinutes: seed.classMinutes,
          priceWon: expectedPriceWon(seed.classMinutes),
        ),
    ];
  }

  /// [withinMinutes] 이내 신청만 최신순(분 전 오름차순).
  static List<TutorRequestListItem> recentQuestions({
    int withinMinutes = newQuestionWithinMinutes,
  }) {
    final list = build()
        .where((item) => item.minutesAgo <= withinMinutes)
        .toList()
      ..sort((a, b) => a.minutesAgo.compareTo(b.minutesAgo));
    return list;
  }
}
