import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'models/lesson_review_session.dart';
import 'models/lesson_review_message.dart';
import 'models/lesson_review_resources.dart';
import 'models/review_lesson_item.dart';

class LessonReviewRepository {
  final Dio _dio;

  LessonReviewRepository({Dio? dio}) : _dio = dio ?? dioClient;

  // 복습 세션 생성
  Future<LessonReviewSession> createSession(int lessonId) async {
    final res = await _dio.post(
      '/lesson-review/sessions',
      data: {'lessonId': lessonId},
    );
    return LessonReviewSession.fromJson(res.data as Map<String, dynamic>);
  }

  // 복습 목록 (완료된 강의 + 준비 상태). 전사 전이면 ready=false.
  Future<List<ReviewLessonItem>> listReviewLessons() async {
    final res = await _dio.get('/lesson-review/lessons');
    return (res.data as List)
        .map((e) => ReviewLessonItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 복습 세션 목록
  Future<List<LessonReviewSession>> listSessions() async {
    final res = await _dio.get('/lesson-review/sessions');
    return (res.data as List)
        .map((e) => LessonReviewSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 메시지 히스토리
  Future<List<LessonReviewMessage>> getMessages(int sessionId) async {
    final res = await _dio.get('/lesson-review/sessions/$sessionId/messages');
    return (res.data as List)
        .map((e) => LessonReviewMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // 메시지 전송 → AI 응답만 반환
  Future<LessonReviewMessage> sendMessage(int sessionId, String content) async {
    final res = await _dio.post(
      '/lesson-review/sessions/$sessionId/messages',
      data: {'content': content},
    );
    return LessonReviewMessage.fromJson(res.data as Map<String, dynamic>);
  }

  // 영상 URL + PDF URL 조회
  Future<LessonReviewResources> getResources(int lessonId) async {
    final res = await _dio.get('/lesson-review/lessons/$lessonId/summary-pdf');
    return LessonReviewResources.fromJson(res.data as Map<String, dynamic>);
  }
}

final lessonReviewRepositoryProvider =
    Provider<LessonReviewRepository>((ref) => LessonReviewRepository());