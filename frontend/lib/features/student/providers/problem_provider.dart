import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/repositories/problem_repository.dart';

/// 문제 도메인 API 레포지토리 프로바이더.
final problemRepositoryProvider = Provider<ProblemRepository>(
  (ref) => ProblemRepository(),
);

/// 로그인한 학생의 내 질문 목록. 화면에서 watch, 수정/취소 후 invalidate로 새로고침.
final studentProblemsProvider =
    FutureProvider.autoDispose<List<StudentProblemModel>>((ref) async {
  final studentId = ref.watch(currentUserProvider)?.id;
  if (studentId == null) return const [];
  final repo = ref.watch(problemRepositoryProvider);
  return repo.getStudentProblems(studentId);
});
