import 'package:dio/dio.dart';
import 'package:ieum/core/network/dio_client.dart';

class TutorRepository {
  final Dio _dio;

  TutorRepository({Dio? dio}) : _dio = dio ?? dioClient;

  Future<void> updateAvailability(int tutorId, {required bool available}) async {
    await _dio.patch(
      '/tutors/$tutorId/availability',
      data: {'available': available},
    );
  }
}
