import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'package:ieum/features/student/models/tutor_profile_detail.dart';

class TutorProfileRepository {
  TutorProfileRepository({Dio? dio}) : _dio = dio ?? dioClient;
  final Dio _dio;

  Future<TutorProfileDetail> fetchProfile(int tutorId) async {
    final response = await _dio.get('/tutors/$tutorId');
    return TutorProfileDetail.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}

final tutorProfileProvider =
    FutureProvider.autoDispose.family<TutorProfileDetail, int>((ref, tutorId) {
  return TutorProfileRepository().fetchProfile(tutorId);
});
