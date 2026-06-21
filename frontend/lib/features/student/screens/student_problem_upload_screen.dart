import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/utils/student_question_text_util.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
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
  static Color get _softPointBorder =>
      AppColors.studentPoint.withValues(alpha: 0.48);
  static Color get _focusPointBorder =>
      AppColors.studentPoint.withValues(alpha: 0.72);

  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _problemImageBytes;
  String? _selectedSubject;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickProblemImage() async {
    final isDark = ref.read(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final sheetTheme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
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
              Icon(icon, size: 22, color: AppColors.studentPoint),
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
    if (!await _ensurePermission(
      permission: Permission.camera,
      label: '카메라',
    )) {
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
      setState(() => _problemImageBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      _showSnack('사진 업로드에 실패했어요. 다시 시도해 주세요.');
    }
  }

  Future<void> _pickFromGallery() async {
    if (Platform.isIOS) {
      if (!await _ensurePermission(
        permission: Permission.photos,
        label: '사진',
      )) {
        return;
      }
    }

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted || file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _problemImageBytes = bytes);
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

  Future<void> _submitMatchingRequest() async {
    if (_problemImageBytes == null) {
      _showSnack('문제 사진을 업로드해 주세요.');
      return;
    }
    if (_selectedSubject == null) {
      _showSnack('과목을 선택해 주세요.');
      return;
    }

    final granted =
        await ref.read(appNotificationServiceProvider).ensurePermission();
    if (!mounted) return;
    if (!granted) {
      _showSnack('알림 권한이 필요합니다. 설정 → 온샘 → 알림에서 허용해 주세요.');
      return;
    }

    final sessionToken = DateTime.now().millisecondsSinceEpoch;
    final questionSummary = StudentQuestionTextUtil.summarize(
      _descriptionController.text,
    );
    await ref.read(studentMatchingSessionProvider.notifier).startMatching(
          subject: _selectedSubject!,
          questionSummary: questionSummary,
          problemImageBytes: _problemImageBytes,
          pendingId: 'upload-$sessionToken',
          sessionToken: sessionToken,
        );

    if (!mounted) return;
    context.pushReplacement(RoutePaths.studentMatchingWait);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
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

          return Scaffold(
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
                        _sectionTitle(shell, '과목'),
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
                          onPressed: _submitMatchingRequest,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.studentPoint,
                            foregroundColor: Colors.white,
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
          );
        },
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
    final hasImage = _problemImageBytes != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final photoHeight = (constraints.maxWidth * 0.62).clamp(168.0, 228.0);

        return Material(
          color: shell.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: _softPointBorder,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _pickProblemImage,
            child: SizedBox(
              height: photoHeight,
              width: double.infinity,
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          _problemImageBytes!,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                '변경',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _softPointBorder,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_a_photo_outlined,
                            size: 24,
                            color: AppColors.studentPoint,
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
                          '터치해서 업로드',
                          style: TextStyle(
                            fontSize: 14,
                            color: shell.hintColor,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
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
                    ? AppColors.studentPoint
                    : shell.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _selectedSubject == subject
                      ? AppColors.studentPoint
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
