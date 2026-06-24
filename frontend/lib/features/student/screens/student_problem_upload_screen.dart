import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/screens/student_problem_edit_screen.dart';
import 'package:ieum/features/student/utils/student_question_text_util.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentProblemUploadScreen extends ConsumerStatefulWidget {
  const StudentProblemUploadScreen({super.key});

  @override
  ConsumerState<StudentProblemUploadScreen> createState() =>
      _StudentProblemUploadScreenState();
}

class _StudentProblemUploadScreenState
    extends ConsumerState<StudentProblemUploadScreen> {
  static const _subjects = ['국어', '수학', '영어', '사회', '과학'];
  static const _subjectEnum = {
    '국어': 'KOREAN',
    '수학': 'MATH',
    '영어': 'ENGLISH',
    '사회': 'SOCIAL',
    '과학': 'SCIENCE',
  };
  static Color get _softPointBorder =>
      AppColors.studentPoint.withValues(alpha: 0.48);
  static Color get _focusPointBorder =>
      AppColors.studentPoint.withValues(alpha: 0.72);

  static const _maxImages = 5;

  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  final List<Uint8List> _problemImages = [];
  String? _selectedSubject;
  bool _submitting = false; // OCR 분석 중(로딩 오버레이 표시)

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickProblemImage() async {
    final isDark = ref.read(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final sheetTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: sheetTheme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Theme(
          data: sheetTheme,
          child: Builder(
            builder: (innerContext) {
              final shell = ShellTheme.of(innerContext);
              final bottom = MediaQuery.paddingOf(innerContext).bottom;

              void closeAnd(Future<void> Function() action) {
                Navigator.pop(sheetContext);
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await Future<void>.delayed(const Duration(milliseconds: 280));
                  if (!mounted) return;
                  await action();
                });
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: shell.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '문제 사진',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sheetRow(
                      shell: shell,
                      icon: Icons.photo_camera_outlined,
                      label: '카메라로 촬영',
                      onTap: () => closeAnd(_pickFromCamera),
                    ),
                    const SizedBox(height: 8),
                    _sheetRow(
                      shell: shell,
                      icon: Icons.photo_outlined,
                      label: '앨범에서 선택',
                      onTap: () => closeAnd(_pickFromGallery),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _sheetRow({
    required ShellTheme shell,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: shell.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: shell.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.studentInk),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: shell.titleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _ensurePermission({
    required Permission permission,
    required String label,
  }) async {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showSnack('$label 권한이 꺼져 있어요. 설정에서 허용해 주세요.');
      }
      return false;
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (!mounted) return false;
    _showSnack('$label 권한이 필요해요.');
    return false;
  }

  Future<void> _pickFromCamera() async {
    // 웹은 dart:io Platform·permission_handler 미지원 → 권한 체크 건너뛰고 브라우저에 위임
    if (!kIsWeb &&
        !await _ensurePermission(
          permission: Permission.camera,
          label: '카메라',
        )) {
      return;
    }

    if (_problemImages.length >= _maxImages) {
      _showSnack('사진은 최대 $_maxImages장까지 올릴 수 있어요.');
      return;
    }

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted || file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _problemImages.add(bytes));
    } catch (_) {
      if (!mounted) return;
      _showSnack('사진 업로드에 실패했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _pickFromGallery() async {
    // 웹은 dart:io Platform 접근 시 런타임 에러 → kIsWeb으로 가드
    if (!kIsWeb && Platform.isIOS) {
      if (!await _ensurePermission(
        permission: Permission.photos,
        label: '사진',
      )) {
        return;
      }
    }

    final remaining = _maxImages - _problemImages.length;
    if (remaining <= 0) {
      _showSnack('사진은 최대 $_maxImages장까지 올릴 수 있어요.');
      return;
    }

    try {
      final files = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (!mounted || files.isEmpty) return;

      final picked = files.length > remaining ? files.sublist(0, remaining) : files;
      final bytesList = <Uint8List>[];
      for (final file in picked) {
        bytesList.add(await file.readAsBytes());
      }
      if (!mounted) return;
      setState(() => _problemImages.addAll(bytesList));

      if (files.length > remaining) {
        _showSnack('사진은 최대 $_maxImages장까지만 추가됐어요.');
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('사진 업로드에 실패했어요. 다시 시도해 주세요.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 서버/네트워크 에러에서 사람이 읽을 메시지 추출.
  /// 백엔드는 실패 시 ApiResponse.fail(message) → { message: "..." }를 준다.
  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'AI 분석이 오래 걸려 시간 초과됐어요. 잠시 후 다시 시도해 주세요.';
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return '서버에 연결할 수 없어요. 백엔드가 켜져 있는지 확인해 주세요.';
      }
    }
    return '문제 등록에 실패했어요. 다시 시도해 주세요.';
  }

  /// 한 사진에서 여러 문제가 감지됐을 때, 학생이 질문할 문제 하나를 고르는 시트.
  /// 선택한 인덱스를 반환, 닫으면 null.
  Future<int?> _pickDetectedProblem(List<DetectedProblem> detected) async {
    if (detected.isEmpty) return null;

    final isDark = ref.read(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final sheetTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetTheme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Theme(
          data: sheetTheme,
          child: Builder(
            builder: (innerContext) {
              final shell = ShellTheme.of(innerContext);
              final bottom = MediaQuery.paddingOf(innerContext).bottom;

              return Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: shell.cardBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '어떤 문제인가요?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '사진에서 여러 문제가 감지됐어요. 질문할 문제를 골라 주세요.',
                      style: TextStyle(fontSize: 14, color: shell.hintColor),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: detected.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final d = detected[i];
                          return Material(
                            color: shell.cardBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: shell.cardBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.pop(sheetContext, i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '문제 ${i + 1}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.studentInk,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d.preview,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: shell.titleColor,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submitMatchingRequest() async {
    if (_problemImages.isEmpty) {
      _showSnack('문제 사진을 업로드해 주세요.');
      return;
    }
    // 과목은 선택 사항 — 고르지 않으면 AI가 자동으로 분류한다.

    // 알림 권한은 매칭 알림용 — 있으면 좋지만 없어도 업로드는 진행한다.
    // (웹/미지원 플랫폼은 ensurePermission이 false를 주지만 막지 않음)
    await ref.read(appNotificationServiceProvider).ensurePermission();
    if (!mounted) return;

    // 백엔드에 실제 문제 등록 (POST /problems) — AI가 분류/난이도 판정
    final studentId = ref.read(currentUserProvider)?.id;
    if (studentId == null) {
      _showSnack('로그인이 필요해요.');
      return;
    }
    final repository = ref.read(problemRepositoryProvider);
    setState(() => _submitting = true);
    ProblemCreateResult result;
    try {
      result = await repository.createProblem(
        images: _problemImages,
        studentId: studentId,
        subject: _subjectEnum[_selectedSubject],
        studentDescription: _descriptionController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(_errorMessage(e));
      return;
    }
    if (!mounted) return;

    // 한 사진에서 여러 문제가 감지되면 학생이 하나를 선택 →
    // detectionId로 /select 호출(서버가 1차 OCR 결과를 캐시에서 꺼내 저장, 재OCR 없음)
    if (result.needsSelection) {
      setState(() => _submitting = false); // 선택 시트는 가리지 않음
      final index = await _pickDetectedProblem(result.allDetected);
      if (!mounted || index == null) return;
      setState(() => _submitting = true);
      try {
        result = await repository.selectProblem(
          detectionId: result.detectionId!,
          selectedIndex: index,
          studentId: studentId,
          subject: _subjectEnum[_selectedSubject],
          studentDescription: _descriptionController.text.trim(),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _submitting = false);
        _showSnack(_errorMessage(e));
        return;
      }
      if (!mounted) return;
    }

    // 분류 API 실패(과부하 등)로 기본값 등록됨 → 매칭 대신 분류 수정 화면으로 유도.
    if (result.needsClassification && result.id != null) {
      setState(() => _submitting = false);
      ref.invalidate(studentProblemsProvider);
      _showSnack('AI 분류가 혼잡해 기본값으로 등록했어요. 분류를 확인·수정해 주세요.');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StudentProblemEditScreen(
            problem: StudentProblemModel.fromCreateResult(result),
          ),
        ),
      );
      if (!mounted) return;
      setState(() => _submitting = true);
      // EditScreen에서 수정한 subject 반영을 위해 최신 목록 재조회
      ref.invalidate(studentProblemsProvider);
      List<StudentProblemModel> problems;
      try {
        problems = await ref.read(studentProblemsProvider.future);
      } catch (_) {
        problems = const [];
      }
      if (!mounted) return;
      final updated = problems.firstWhere(
        (p) => p.problemId == result.id,
        orElse: () => StudentProblemModel.fromCreateResult(result),
      );
      final questionSummary = StudentQuestionTextUtil.summarize(
        _descriptionController.text,
      );
      await ref.read(studentMatchingSessionProvider.notifier).startMatching(
        problemId: result.id!,
        studentId: studentId,
        subject: updated.subject ?? _selectedSubject ?? 'UNKNOWN',
        questionSummary: questionSummary,
        problemImageBytes: _problemImages.firstOrNull,
      );
      if (!mounted) return;
      context.go(RoutePaths.studentHome);
      return;
    }

    if (result.id == null) {
      setState(() => _submitting = false);
      _showSnack('문제 등록에 실패했어요. 다시 시도해 주세요.');
      return;
    }

    setState(() => _submitting = false);
    ref.invalidate(studentProblemsProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentProblemEditScreen(
          problem: StudentProblemModel.fromCreateResult(result),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _submitting = true);
    ref.invalidate(studentProblemsProvider);
    List<StudentProblemModel> problems;
    try {
      problems = await ref.read(studentProblemsProvider.future);
    } catch (_) {
      problems = const [];
    }
    if (!mounted) return;
    final updated = problems.firstWhere(
      (p) => p.problemId == result.id,
      orElse: () => StudentProblemModel.fromCreateResult(result),
    );
    final questionSummary = StudentQuestionTextUtil.summarize(
      _descriptionController.text,
    );
    await ref.read(studentMatchingSessionProvider.notifier).startMatching(
      problemId: result.id!,
      studentId: studentId,
      subject: updated.subject ?? _selectedSubject ?? 'UNKNOWN',
      questionSummary: questionSummary,
      problemImageBytes: _problemImages.firstOrNull,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    context.go(RoutePaths.studentHome);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (themedContext) {
          final shell = ShellTheme.of(themedContext);
          final pageBg = Theme.of(themedContext).scaffoldBackgroundColor;
          final isDarkTheme = Theme.of(themedContext).brightness == Brightness.dark;
          final fieldFill =
              isDarkTheme ? shell.detailBackground : shell.cardBackground;

          return Stack(
            children: [
              Scaffold(
            backgroundColor: pageBg,
            appBar: AppBar(
              backgroundColor: pageBg,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: shell.titleColor,
                ),
                onPressed: () => themedContext.pop(),
              ),
              title: Text(
                '문제 업로드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: shell.titleColor,
                ),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle(shell, '문제 사진'),
                        const SizedBox(height: 10),
                        _buildPhotoCard(shell),
                        const SizedBox(height: 22),
                        _sectionTitle(shell, '과목 (선택)'),
                        const SizedBox(height: 4),
                        Text(
                          '고르지 않으면 AI가 자동으로 분류해요.',
                          style: TextStyle(fontSize: 12.5, color: shell.hintColor),
                        ),
                        const SizedBox(height: 10),
                        _buildSubjectChips(shell),
                        const SizedBox(height: 22),
                        _sectionTitle(shell, '추가 설명'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _descriptionController,
                          minLines: 20,
                          maxLines: 24,
                          style: TextStyle(
                            fontSize: 16,
                            color: shell.titleColor,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            hintText: '헷갈리는 부분을 적어 주세요 (선택)',
                            hintStyle: TextStyle(
                              color: shell.hintColor,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: fieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _softPointBorder,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _softPointBorder,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _focusPointBorder,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ColoredBox(
                  color: pageBg,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _submitting ? null : _submitMatchingRequest,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.studentPoint,
                            foregroundColor: AppColors.studentInk,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '매칭 요청하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
              if (_submitting) _buildLoadingOverlay(shell),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingOverlay(ShellTheme shell) {
    return Positioned.fill(
      // Stack 직속 자식이라 Scaffold(Material) 밖 → Text의 노란 밑줄 방지용 투명 Material.
      child: Material(
        type: MaterialType.transparency,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.28),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                decoration: BoxDecoration(
                  color: shell.cardBackground,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.4,
                        valueColor: const AlwaysStoppedAnimation(AppColors.studentInk),
                        backgroundColor: AppColors.studentPoint.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '문제를 분석하고 있어요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI가 문제를 읽는 중이에요. 잠시만요!',
                      style: TextStyle(fontSize: 13, color: shell.hintColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ShellTheme shell, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: shell.titleColor,
      ),
    );
  }

  Widget _buildPhotoCard(ShellTheme shell) {
    // 사진이 없으면 큰 빈 카드, 있으면 썸네일 가로 스크롤 + 추가 타일
    if (_problemImages.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final photoHeight = (constraints.maxWidth * 0.62).clamp(168.0, 228.0);
          return Material(
            color: shell.cardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: _softPointBorder, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _pickProblemImage,
              child: SizedBox(
                height: photoHeight,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _softPointBorder, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        size: 24,
                        color: AppColors.studentInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '문제 사진 추가',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '여러 장도 가능 (최대 $_maxImages장)',
                      style: TextStyle(fontSize: 14, color: shell.hintColor),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    const thumbSize = 132.0;
    final canAddMore = _problemImages.length < _maxImages;

    return SizedBox(
      height: thumbSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _problemImages.length + (canAddMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == _problemImages.length) {
            return _addThumbTile(shell, thumbSize);
          }
          return _imageThumb(i, thumbSize);
        },
      ),
    );
  }

  Widget _addThumbTile(ShellTheme shell, double size) {
    return Material(
      color: shell.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: _softPointBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickProblemImage,
        child: SizedBox(
          width: size,
          height: size,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 28, color: AppColors.studentInk),
              SizedBox(height: 6),
              Text(
                '추가',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.studentInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageThumb(int index, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_problemImages[index], fit: BoxFit.cover),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => setState(() => _problemImages.removeAt(index)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChips(ShellTheme shell) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final subject in _subjects)
          GestureDetector(
            onTap: () => setState(() => _selectedSubject = subject),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedSubject == subject
                    ? AppColors.studentInk
                    : shell.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedSubject == subject
                      ? AppColors.studentInk
                      : shell.cardBorder,
                ),
              ),
              child: Text(
                subject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectedSubject == subject
                      ? AppColors.white
                      : shell.subtitleColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
