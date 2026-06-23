import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ieum/core/network/dio_client.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';

/// 문제(problem) 도메인 API 클라이언트.
/// 모든 응답은 ApiResponse 래핑 → `res.data['data']`로 언래핑.
class ProblemRepository {
  final Dio _dio;

  ProblemRepository({Dio? dio}) : _dio = dio ?? dioClient;

  /// 문제 등록 (이미지 1~N장 + 메타). multipart/form-data.
  /// images: 파일 파트(여러 장), data: application/json 파트.
  Future<ProblemCreateResult> createProblem({
    required List<Uint8List> images,
    required int studentId,
    String? subject, // Subject enum 이름 (예: 'MATH'). 지정 시 AI 판정보다 우선
    String? studentDescription,
    int? selectedProblemIndex,
  }) async {
    final data = <String, dynamic>{'studentId': studentId};
    if (subject != null) {
      data['subject'] = subject;
    }
    if (studentDescription != null && studentDescription.isNotEmpty) {
      data['studentDescription'] = studentDescription;
    }
    if (selectedProblemIndex != null) {
      data['selectedProblemIndex'] = selectedProblemIndex;
    }

    final form = FormData.fromMap({
      // 같은 'images' 키에 여러 파트 → 백엔드 List<MultipartFile>로 매핑
      'images': [
        for (var i = 0; i < images.length; i++)
          MultipartFile.fromBytes(
            images[i],
            filename: 'problem_$i.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
      ],
      'data': MultipartFile.fromString(
        jsonEncode(data),
        contentType: DioMediaType('application', 'json'),
      ),
    });

    // OCR + AI 분류(+재시도)는 30초를 넘길 수 있어 이 요청만 타임아웃을 길게 둔다.
    final res = await _dio.post(
      '/problems',
      data: form,
      options: Options(
        sendTimeout: const Duration(minutes: 1),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    return ProblemCreateResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// 여러 문제 감지 후 선택 확정 (재OCR/재업로드 없음). 1차 응답의 detectionId 사용.
  Future<ProblemCreateResult> selectProblem({
    required String detectionId,
    required int selectedIndex,
    required int studentId,
    String? subject,
    String? studentDescription,
  }) async {
    final res = await _dio.post('/problems/select', data: {
      'detectionId': detectionId,
      'selectedIndex': selectedIndex,
      'studentId': studentId,
      if (subject != null) 'subject': subject,
      if (studentDescription != null && studentDescription.isNotEmpty)
        'studentDescription': studentDescription,
    });
    return ProblemCreateResult.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// 분류(과목/유형/난이도/출처) 수정. enum은 name 문자열(예: 'MATH', 'HARD').
  Future<void> updateClassification({
    required int problemId,
    required String subject,
    String? primaryType,
    String? secondaryType,
    String? difficulty,
    String? examType,
  }) async {
    await _dio.patch('/problems/$problemId/classification', data: {
      'subject': subject,
      if (primaryType != null && primaryType.isNotEmpty) 'primaryType': primaryType,
      if (secondaryType != null && secondaryType.isNotEmpty)
        'secondaryType': secondaryType,
      if (difficulty != null) 'difficulty': difficulty,
      if (examType != null) 'examType': examType,
    });
  }

  /// 내 문제 목록.
  Future<List<StudentProblemModel>> getStudentProblems(int studentId) async {
    final res = await _dio.get(
      '/problems/student',
      queryParameters: {'studentId': studentId},
    );
    final data = res.data['data'] as List;
    return data
        .map((e) => StudentProblemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 문제 취소.
  Future<void> cancelProblem(int problemId) async {
    await _dio.delete('/problems/$problemId');
  }
}
