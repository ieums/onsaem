import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class StudentQuestionsScreen extends ConsumerStatefulWidget {
  const StudentQuestionsScreen({super.key});

  @override
  ConsumerState<StudentQuestionsScreen> createState() =>
      _StudentQuestionsScreenState();
}

class _StudentQuestionsScreenState extends ConsumerState<StudentQuestionsScreen> {
  final _controller = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<_ChatMessage> _messages = [];
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        text: '안녕하세요! 온샘 AI튜터입니다. 🤖\n어떤 문제를 도와드릴까요?\n'
            '모르는 개념이나 문제 사진을 첨부해 보내주세요.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _pushSingleTurn(
      _ChatMessage(
        text: text,
        isUser: true,
      ),
    );
  }

  void _pushSingleTurn(_ChatMessage userMessage) {
    final dedupeKey = 'ai-tutor-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages
        ..removeRange(1, _messages.length)
        ..add(userMessage);
      _isResponding = true;
    });
    ref.read(studentNotificationControllerProvider).scheduleAiTutorResponse(
          dedupeKey: dedupeKey,
          preview: '보내주신 질문에 대한 AI 튜터 안내가 도착했어요.',
          delay: const Duration(milliseconds: 700),
        );
    _respondWithDisabledMessage(dedupeKey);
  }

  Future<void> _respondWithDisabledMessage(String dedupeKey) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _messages.add(const _ChatMessage(text: _disabledMessage, isUser: false));
      _isResponding = false;
    });

    await ref.read(studentNotificationControllerProvider).onAiTutorResponseArrived(
          dedupeKey: dedupeKey,
          preview: '보내주신 질문에 대한 AI 튜터 안내가 도착했어요.',
        );
  }

  void _showAttachBottomSheet() {
    final shell = ShellTheme.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: shell.scaffoldBackground,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        void closeAnd(Future<void> Function() action) {
          Navigator.pop(sheetContext);
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 280));
            if (!mounted) return;
            await action();
          });
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: shell.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '파일 첨부하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: shell.titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '문제 사진이나 파일을 보내주세요',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: shell.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: Icon(Icons.close_rounded, color: shell.hintColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _attachSheetButton(
                  shell: shell,
                  icon: Icons.photo_camera_outlined,
                  label: '카메라로 촬영',
                  onTap: () => closeAnd(_pickFromCamera),
                ),
                const SizedBox(height: 10),
                _attachSheetButton(
                  shell: shell,
                  icon: Icons.photo_outlined,
                  label: '사진 선택',
                  onTap: () => closeAnd(_pickFromGallery),
                ),
                const SizedBox(height: 10),
                _attachSheetButton(
                  shell: shell,
                  icon: Icons.folder_open_outlined,
                  label: '파일 선택',
                  onTap: () => closeAnd(_pickFromFiles),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachSheetButton({
    required ShellTheme shell,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: shell.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: shell.cardBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 22, color: AppColors.studentInk),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
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
        _showPermissionSnack('$label 권한이 꺼져 있어요. 설정에서 허용해 주세요.');
      }
      return false;
    }

    status = await permission.request();
    if (status.isGranted || status.isLimited) return true;

    if (!mounted) return false;
    if (status.isPermanentlyDenied) {
      _showPermissionSnack('$label 권한이 꺼져 있어요. 설정에서 허용해 주세요.');
    } else {
      _showPermissionSnack('$label 권한이 필요해요.');
    }
    return false;
  }

  Future<bool> _ensureCameraPermission() => _ensurePermission(
        permission: Permission.camera,
        label: '카메라',
      );

  /// iOS는 허용 필수. Android는 요청해 설정에 노출하고, 거부돼도 시스템 사진 선택기 시도.
  Future<bool> _ensurePhotosPermission({bool required = true}) async {
    if (Platform.isAndroid && !required) {
      final status = await Permission.photos.status;
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied) return false;
      await Permission.photos.request();
      return true;
    }
    return _ensurePermission(permission: Permission.photos, label: '사진');
  }

  void _showPermissionSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '설정',
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    if (!await _ensureCameraPermission()) return;
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (!mounted || file == null) return;
      final bytes = await file.readAsBytes();
      _submitAttachment(bytes: bytes, isImage: true);
    } catch (e) {
      if (!mounted) return;
      _showAttachError(detail: e);
    }
  }

  Future<void> _pickFromGallery() async {
    if (Platform.isIOS) {
      if (!await _ensurePhotosPermission()) return;
    } else if (Platform.isAndroid) {
      await _ensurePhotosPermission(required: false);
    }
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (!mounted || file == null) return;
      final bytes = await file.readAsBytes();
      _submitAttachment(bytes: bytes, isImage: true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('photo_access_denied') ||
          msg.contains('permission') ||
          msg.contains('access_denied')) {
        _showPermissionSnack('사진 접근 권한이 필요해요.');
        return;
      }
      _showAttachError(detail: e);
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        withData: true,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'pdf',
          'heic',
          'webp',
          'hwp',
          'hwpx',
        ],
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final ext = (picked.extension ?? '').toLowerCase();
      final isImage = _isImageExt(ext);
      Uint8List? bytes = picked.bytes;
      if (bytes == null && picked.path != null) {
        bytes = await File(picked.path!).readAsBytes();
      }
      _submitAttachment(bytes: bytes, isImage: isImage);
    } catch (_) {
      if (!mounted) return;
      _showAttachError();
    }
  }

  void _submitAttachment({
    required Uint8List? bytes,
    required bool isImage,
  }) {
    _pushSingleTurn(
      _ChatMessage(
        isUser: true,
        fileBytes: isImage ? bytes : null,
        isImageFile: isImage,
        isFileAttachment: !isImage,
      ),
    );
  }

  void _showAttachError({Object? detail}) {
    assert(() {
      if (detail != null) debugPrint('AI tutor attach error: $detail');
      return true;
    }());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('첨부에 실패했어요. 다시 시도해 주세요.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  bool _isImageExt(String ext) =>
      ext == 'jpg' ||
      ext == 'jpeg' ||
      ext == 'png' ||
      ext == 'webp' ||
      ext == 'heic';

  static const _disabledMessage =
      '죄송해요. AI튜터 기능은 아직 준비 중이에요.\n곧 더 정확한 풀이로 찾아올게요!';

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    return ColoredBox(
      color: shell.scaffoldBackground,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Text(
                    'AI 튜터',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: shell.titleColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                itemCount: _messages.length + (_isResponding ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (_isResponding && index == _messages.length) {
                    return _buildTypingBubble(shell);
                  }
                  final msg = _messages[index];
                  final align = msg.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start;
                  final bubbleColor = msg.isUser
                      ? AppColors.studentInk
                      : shell.cardBackground;
                  final textColor = msg.isUser ? Colors.white : shell.titleColor;
                  return Column(
                    crossAxisAlignment: align,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: bubbleColor,
                          borderRadius: BorderRadius.circular(18),
                          border: msg.isUser
                              ? null
                              : Border.all(color: shell.cardBorder, width: 1),
                        ),
                        child: _buildMessageContent(msg, textColor),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: _askRealTutor,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.studentPoint.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    foregroundColor: AppColors.studentInk,
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('실제 강사한테 질문하기'),
                ),
              ),
            ),
            _buildComposer(shell),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(_ChatMessage msg, Color textColor) {
    final textStyle = TextStyle(
      fontSize: 17,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: textColor,
    );
    if (msg.isImageFile && msg.fileBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          msg.fileBytes!,
          width: 220,
          height: 160,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 220,
            height: 160,
            color: Colors.black12,
            alignment: Alignment.center,
            child: Icon(Icons.broken_image_outlined, color: textColor, size: 28),
          ),
        ),
      );
    }
    if (msg.isFileAttachment) {
      return Icon(Icons.insert_drive_file_rounded, size: 28, color: textColor);
    }
    return Text(msg.text, style: textStyle);
  }

  Widget _buildTypingBubble(ShellTheme shell) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: shell.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: shell.cardBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('답변 준비 중', style: TextStyle(color: shell.subtitleColor, fontSize: 14)),
              const SizedBox(width: 6),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.studentInk),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _askRealTutor() {
    context.push(RoutePaths.studentProblemUpload);
  }

  Widget _buildComposer(ShellTheme shell) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? shell.detailBackground : Colors.white;
    final borderColor = isDark ? shell.cardBorder : const Color(0xFFE2E5EC);
    final inputFill = cardColor;
    final actionBg = isDark ? shell.iconBackground : AppColors.studentInk;
    final actionIcon = isDark ? shell.titleColor : Colors.white;
    const cardHeight = 52.0;
    const actionSize = 40.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _composerActionButton(
              icon: Icons.upload_file_outlined,
              onTap: _showAttachBottomSheet,
              size: actionSize,
              backgroundColor: actionBg,
              iconColor: actionIcon,
            ),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: borderColor,
            ),
            Expanded(
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: borderColor,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: inputFill,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _sendText(),
                  textInputAction: TextInputAction.send,
                  cursorColor: shell.titleColor,
                  style: TextStyle(fontSize: 15, color: shell.titleColor),
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: TextStyle(color: shell.hintColor, fontSize: 15),
                    isDense: true,
                    filled: true,
                    fillColor: inputFill,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _composerActionButton(
              icon: Icons.send_rounded,
              onTap: _sendText,
              size: actionSize,
              backgroundColor: actionBg,
              iconColor: actionIcon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _composerActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    this.text = '',
    required this.isUser,
    this.fileBytes,
    this.isImageFile = false,
    this.isFileAttachment = false,
  });

  final String text;
  final bool isUser;
  final Uint8List? fileBytes;
  final bool isImageFile;
  final bool isFileAttachment;
}
