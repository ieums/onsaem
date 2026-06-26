import 'package:dio/dio.dart';
import 'package:ieum/core/network/dio_client.dart';
import '../../student/models/applicant_model.dart';
import '../models/searching_problem_model.dart';
import '../models/tutor_application_model.dart';

class MatchingRepository {
  final Dio _dio;

  MatchingRepository({Dio? dio}) : _dio = dio ?? dioClient;

  Future<List<SearchingProblemModel>> getSearchingProblems(int tutorId) async {
    final res = await _dio.get(
      '/problems/searching',
      queryParameters: {'tutorId': tutorId},
    );
    final data = res.data['data'] as List;
    return data
        .map((e) => SearchingProblemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> applyToLesson(int problemId, int tutorId) async {
    await _dio.post(
      '/matching/$problemId/apply',
      data: {'tutorId': tutorId},
    );
  }

  Future<List<TutorApplicationModel>> getTutorApplications(int tutorId) async {
    final res = await _dio.get('/matching/tutor/$tutorId/applications');
    final data = res.data['data'] as List;
    return data
        .map((e) => TutorApplicationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelApplication(int problemId, int tutorId) async {
    await _dio.delete(
      '/matching/$problemId/apply',
      queryParameters: {'tutorId': tutorId},
    );
  }

  Future<void> rejectProblem(int problemId, int tutorId) async {
    await _dio.post(
      '/matching/$problemId/reject',
      queryParameters: {'tutorId': tutorId},
    );
  }

  Future<void> confirmMatch(int problemId, int tutorId) async {
    await _dio.post(
      '/matching/$problemId/confirm',
      data: {'tutorId': tutorId, 'confirmedBy': 'tutor'},
    );
  }

  Future<void> cancelConfirm(int problemId, int tutorId) async {
    await _dio.post(
      '/matching/$problemId/cancel-confirm',
      data: {'tutorId': tutorId, 'cancelledBy': 'tutor'},
    );
  }

  // ─── 학생용 API ──────────────────────────────────────────────────────────────

  // 탐색 기본 기간 = 1일(1440분). 강사가 항상 온라인은 아니라 '구인 게시판'처럼
  // 하루 동안 열어두고, 강사가 로그인할 때 보고 신청하도록 한다.
  Future<void> startMatching(int problemId, {int minutes = 1440}) async {
    await _dio.post(
      '/matching/$problemId/start',
      data: {'minutes': minutes},
    );
  }

  Future<List<ApplicantModel>> getApplicants(int problemId) async {
    final res = await _dio.get('/matching/$problemId/applicants');
    final data = res.data['data'] as List;
    return data
        .map((e) => ApplicantModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptTutor(int problemId, int tutorId) async {
    await _dio.post(
      '/matching/$problemId/accept',
      data: {'tutorId': tutorId},
    );
  }

  Future<void> confirmMatchStudent(int problemId, int tutorId) async {
    await _dio.post(
      '/matching/$problemId/confirm',
      data: {'tutorId': tutorId, 'confirmedBy': 'student'},
    );
  }

  Future<void> cancelConfirmStudent(int problemId, int tutorId) async {
    await _dio.post(
      '/matching/$problemId/cancel-confirm',
      data: {'tutorId': tutorId, 'cancelledBy': 'student'},
    );
  }

  Future<void> extendSearch(int problemId, {int minutes = 1440}) async {
    await _dio.post(
      '/matching/$problemId/extend',
      data: {'minutes': minutes},
    );
  }

  Future<void> cancelProblem(int problemId) async {
    await _dio.delete('/problems/$problemId');
  }
}
