import 'package:dio/dio.dart';
import 'package:ieum/core/network/dio_client.dart';
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
}
