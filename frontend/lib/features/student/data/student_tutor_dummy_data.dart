import 'package:ieum/features/student/models/student_tutor_profile.dart';

abstract final class StudentTutorDummyData {
  static const _all = [
    StudentTutorProfile(
      id: 'tutor-kim',
      name: '김선생',
      avatarInitial: '김',
      isOnline: true,
      department: '수학교육과',
      university: '서울대학교',
      rating: 4.9,
      reviewCount: 127,
      lessonCount: 342,
      avgResponseMinutes: 2,
      introLine: '개념부터 차근차근, 풀이는 스스로 할 수 있게',
      introBody:
          '수학교육학과 전공 후 5년간 1:1 과외를 진행했습니다. '
          '학생이 스스로 풀 수 있도록 단계별로 질문을 던지며, '
          '틀린 문제는 왜 틀렸는지 원리부터 다시 짚어드려요.',
      styles: ['개념 위주 설명', '문제 풀이 중심', '친절한 피드백'],
      subjects: ['수학', '과학'],
      reviews: [
        StudentTutorReview(
          studentLabel: '학생A',
          dateLabel: '2024.05.15',
          rating: 5,
          body: '미분 개념이 헷갈렸는데, 그래프로 설명해 주셔서 바로 이해됐어요.',
        ),
        StudentTutorReview(
          studentLabel: '학생B',
          dateLabel: '2024.05.02',
          rating: 5,
          body: '답만 알려주지 않고 풀이 과정을 함께 짜 줘서 실력이 늘었습니다.',
        ),
      ],
    ),
    StudentTutorProfile(
      id: 'tutor-lee',
      name: '이선생',
      avatarInitial: '이',
      isOnline: true,
      department: '영어영문학과',
      university: '연세대학교',
      rating: 4.8,
      reviewCount: 89,
      lessonCount: 218,
      avgResponseMinutes: 3,
      introLine: '수능·내신 영어, 문법과 독해를 함께',
      introBody:
          '영어영문학과 재학 중이며 수능 영어와 내신 대비를 병행하고 있습니다. '
          '지문 구조를 먼저 파악한 뒤, 오답 유형별로 정리해 드립니다.',
      styles: ['지문 구조 분석', '오답 노트 정리', '꼼꼼한 문법'],
      subjects: ['영어', '국어'],
      reviews: [
        StudentTutorReview(
          studentLabel: '학생C',
          dateLabel: '2024.04.28',
          rating: 5,
          body: '관계대명사 구분이 어려웠는데 예문으로 쉽게 정리해 주셨어요.',
        ),
      ],
    ),
    StudentTutorProfile(
      id: 'tutor-park',
      name: '박선생',
      avatarInitial: '박',
      isOnline: false,
      department: '물리학과',
      university: '고려대학교',
      rating: 4.7,
      reviewCount: 64,
      lessonCount: 156,
      avgResponseMinutes: 5,
      introLine: '과학은 원리 이해가 먼저, 그다음 문제 적용',
      introBody:
          '물리학과 전공으로 수학·과학 통합 수업을 진행합니다. '
          '공식 암기보다 유도 과정을 함께 보며 응용 문제에도 대비합니다.',
      styles: ['원리 중심', '실험·도식 활용', '기출 유형 정리'],
      subjects: ['과학', '수학'],
      reviews: [
        StudentTutorReview(
          studentLabel: '학생D',
          dateLabel: '2024.04.10',
          rating: 4.5,
          body: '역학 단원에서 막혔는데, 그림으로 설명해 주셔서 이해가 빨랐습니다.',
        ),
      ],
    ),
  ];

  static StudentTutorProfile? byId(String id) {
    for (final tutor in _all) {
      if (tutor.id == id) return tutor;
    }
    for (final tutor in _assignableOnWait) {
      if (tutor.id == id) return tutor;
    }
    return null;
  }

  /// 담당 과목 대기 후 배정되는 강사 (데모: 초기 매칭 풀과 분리)
  static const _assignableOnWait = [
    StudentTutorProfile(
      id: 'tutor-choi',
      name: '최선생',
      avatarInitial: '최',
      isOnline: true,
      department: '사회교육과',
      university: '이화여자대학교',
      rating: 4.8,
      reviewCount: 52,
      lessonCount: 118,
      avgResponseMinutes: 3,
      introLine: '사회 개념은 흐름으로, 자료는 근거로',
      introBody:
          '사회교육과 전공으로 내신·수능 사회 과목을 지도합니다. '
          '개념 연결과 자료 해석을 함께 다루며, 서술형 답안 정리도 도와드려요.',
      styles: ['개념 연결', '자료 해석', '서술형 코칭'],
      subjects: ['사회'],
      reviews: [
        StudentTutorReview(
          studentLabel: '학생E',
          dateLabel: '2024.05.08',
          rating: 5,
          body: '경제 단원 그래프 해석이 어려웠는데, 흐름대로 정리해 주셔서 좋았어요.',
        ),
        StudentTutorReview(
          studentLabel: '학생F',
          dateLabel: '2024.05.01',
          rating: 5,
          body: '서술형 답안 정리 방법을 알려주셔서 시험에서 시간을 덜 썼어요.',
        ),
        StudentTutorReview(
          studentLabel: '학생G',
          dateLabel: '2024.04.22',
          rating: 4.5,
          body: '자료 해석 문제가 많았는데, 근거 찾는 순서를 알려주셔서 도움이 됐습니다.',
        ),
        StudentTutorReview(
          studentLabel: '학생H',
          dateLabel: '2024.04.15',
          rating: 5,
          body: '개념 연결이 잘 되어 있어서 암기보다 이해 위주로 공부할 수 있었어요.',
        ),
      ],
    ),
  ];

  static List<StudentTutorProfile> expertsAfterSubjectWait(String subject) {
    final ready = subjectExpertsFor(subject);
    if (ready.isNotEmpty) return ready;

    return _assignableOnWait
        .where((tutor) => tutor.subjects.contains(subject))
        .toList();
  }

  static List<StudentTutorProfile> subjectExpertsFor(String subject) {
    return _all.where((tutor) => tutor.subjects.contains(subject)).toList();
  }

  static List<StudentTutorProfile> nonSubjectCandidatesFor(String subject) {
    return _all.where((tutor) => !tutor.subjects.contains(subject)).toList();
  }

  static List<StudentTutorProfile> expandedCandidatesForSubject(String subject) {
    final experts = <StudentTutorProfile>[
      ...subjectExpertsFor(subject),
      ..._assignableOnWait.where((tutor) => tutor.subjects.contains(subject)),
    ];
    final others = nonSubjectCandidatesFor(subject);
    final seen = <String>{};
    final merged = <StudentTutorProfile>[];

    for (final tutor in [...experts, ...others]) {
      if (seen.add(tutor.id)) {
        merged.add(tutor);
      }
    }

    return merged;
  }

  static List<StudentTutorProfile> candidatesForSubject(String subject) {
    final experts = subjectExpertsFor(subject);
    if (experts.isNotEmpty) return experts;
    return nonSubjectCandidatesFor(subject);
  }
}
