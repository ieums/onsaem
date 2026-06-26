import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'package:ieum/features/student/models/mypage_models.dart';

/// 마이페이지 '내 활동' + 프로필 수정 API.
/// reviews/reports/auth = ApiResponse 래핑 → res.data['data'] 파싱.
class MypageRepository {
  final Dio _dio;
  MypageRepository({Dio? dio}) : _dio = dio ?? dioClient;

  /// 내가 쓴 리뷰 — GET /reviews/me (인증)
  Future<List<MyReview>> getMyReviews() async {
    final res = await _dio.get('/reviews/me');
    final data = res.data['data'] as List? ?? const [];
    return data.map((e) => MyReview.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 내 신고 내역 — GET /reports/me (인증)
  Future<List<MyReport>> getMyReports() async {
    final res = await _dio.get('/reports/me');
    final data = res.data['data'] as List? ?? const [];
    return data.map((e) => MyReport.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 내 정보 — GET /auth/me (프로필 수정 프리필용).
  /// {id,role,name,email,phone,birthDate,profileImageUrl,provider,status}
  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return (res.data['data'] as Map<String, dynamic>?) ?? const {};
  }

  /// 프로필 수정 — PATCH /auth/me (인증). 보낸 값만 갱신.
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? birthDate, // 'yyyy-MM-dd'
    String? profileImageUrl,
  }) async {
    await _dio.patch('/auth/me', data: {
      if (name != null && name.isNotEmpty) 'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (birthDate != null && birthDate.isNotEmpty) 'birthDate': birthDate,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    });
  }

  /// 프로필 사진 업로드 — POST /auth/me/profile-image (multipart).
  /// 저장된 profileImageUrl을 돌려준다.
  Future<String?> uploadProfileImage(Uint8List bytes, {String? filename}) async {
    final form = FormData.fromMap({
      'image': MultipartFile.fromBytes(
        bytes,
        filename: filename ?? 'profile.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });
    final res = await _dio.post('/auth/me/profile-image', data: form);
    final data = res.data['data'] as Map<String, dynamic>?;
    return data?['profileImageUrl'] as String?;
  }

  /// 강의 후기 작성 — POST /reviews. (강사는 lesson에서 서버가 판별)
  Future<void> createReview({
    required int lessonId,
    required int rating,
    String? comment,
  }) async {
    await _dio.post('/reviews', data: {
      'lessonId': lessonId,
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
  }

  /// 신고 접수 — POST /reports.
  /// 백엔드 CreateReportRequest가 reporterId·reporterType을 @NotNull로 요구하므로 함께 보낸다.
  /// (실제 저장 값은 서버가 JWT로 덮어쓰지만, 본문이 없으면 검증에서 400)
  /// targetType: 'TUTOR' | 'STUDENT' | 'LESSON' / reporterType: 'STUDENT' | 'TUTOR'
  Future<void> createReport({
    required int reporterId,
    required String reporterType,
    required String targetType,
    required int targetId,
    int? lessonId,
    required List<String> reasons,
    String? description,
  }) async {
    await _dio.post('/reports', data: {
      'reporterId': reporterId,
      'reporterType': reporterType,
      'targetType': targetType,
      'targetId': targetId,
      if (lessonId != null) 'lessonId': lessonId,
      'reasons': reasons,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    });
  }
}
