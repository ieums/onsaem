import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'models/ai_tutor_session.dart';
import 'models/ai_tutor_message.dart';
import 'models/ai_tutor_problem.dart';

class AiTutorRepository {
  final Dio _dio;

  AiTutorRepository({Dio? dio}) : _dio = dio ?? dioClient;

  // 세션 생성 (problemId로)
  Future<AiTutorSession> createSession(int problemId) async {
    final res = await _dio.post(
      '/ai-tutor/sessions',
      data: {'problemId': problemId},
    );
    return AiTutorSession.fromJson(res.data as Map<String, dynamic>);
  }

  // 세션 목록
  Future<List<AiTutorSession>> listSessions() async {
    final res = await _dio.get('/ai-tutor/sessions');
    return (res.data as List)
        .map((e) => AiTutorSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 메시지 히스토리
  Future<List<AiTutorMessage>> getMessages(int sessionId) async {
    final res = await _dio.get('/ai-tutor/sessions/$sessionId/messages');
    return (res.data as List)
        .map((e) => AiTutorMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 메시지 전송 → AI 응답만 반환
  Future<AiTutorMessage> sendMessage(int sessionId, String content) async {
    final res = await _dio.post(
      '/ai-tutor/sessions/$sessionId/messages',
      data: {'content': content},
    );
    return AiTutorMessage.fromJson(res.data as Map<String, dynamic>);
  }
    Future<AiTutorProblem> getProblem(int problemId) async {
    final res = await _dio.get('/problems/$problemId');
    return AiTutorProblem.fromJson(res.data['data'] as Map<String, dynamic>);
  }
    // 세션 종료 (CLOSED)
  Future<void> closeSession(int sessionId) async {
    await _dio.patch('/ai-tutor/sessions/$sessionId/close');
  }
}

final aiTutorRepositoryProvider =
    Provider<AiTutorRepository>((ref) => AiTutorRepository());