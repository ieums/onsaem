import 'package:dio/dio.dart';
import 'package:ieum/core/network/dio_client.dart';
import '../models/searching_problem_model.dart';

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
}
