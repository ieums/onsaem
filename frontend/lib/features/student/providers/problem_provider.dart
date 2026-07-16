import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/matching/models/pending_confirm.dart';
import 'package:ieum/features/matching/repositories/matching_repository.dart';
import 'package:ieum/features/student/models/applicant_model.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/repositories/problem_repository.dart';

/// 문제 도메인 API 레포지토리 프로바이더.
final problemRepositoryProvider = Provider<ProblemRepository>(
  (ref) => ProblemRepository(),
);

/// 매칭 API 레포지토리(지원강사 조회·강사 찾기 시작 등).
final matchingRepositoryProvider = Provider<MatchingRepository>(
  (ref) => MatchingRepository(),
);

/// 특정 문제에 지원한 강사 목록(읽기 전용). GET /matching/{problemId}/applicants.
/// 매칭을 시작하지 않았어도 빈 목록을 안전하게 반환.
final problemApplicantsProvider =
    FutureProvider.autoDispose.family<List<ApplicantModel>, int>(
  (ref, problemId) async {
    return ref.watch(matchingRepositoryProvider).getApplicants(problemId);
  },
);

/// 학생이 놓친 매칭 수락 요청(있으면) — 홈 배너로 복구용. 없으면 null.
/// 홈 진입/포커스 시 watch, 처리 후 invalidate로 갱신.
final pendingConfirmProvider =
    FutureProvider.autoDispose<PendingConfirm?>((ref) async {
  final studentId = ref.watch(currentUserProvider)?.id;
  if (studentId == null) return null;
  return ref.watch(matchingRepositoryProvider).fetchPendingConfirm(studentId);
});

/// 로그인한 학생의 내 질문 목록. 화면에서 watch, 수정/취소 후 invalidate로 새로고침.
final studentProblemsProvider =
    FutureProvider.autoDispose<List<StudentProblemModel>>((ref) async {
  final studentId = ref.watch(currentUserProvider)?.id;
  if (studentId == null) return const [];
  final repo = ref.watch(problemRepositoryProvider);
  return repo.getStudentProblems(studentId);
});
