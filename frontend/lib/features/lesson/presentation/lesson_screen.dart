import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/shell_theme_extension.dart';
import 'lesson_provider.dart';
import 'whiteboard_painter.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String channelName;

  const LessonScreen({super.key, required this.channelName});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final _imagePicker = ImagePicker();

  // ─── 타이머 ──────────────────────────────────────────────────────────────────
  Timer? _timer;
  int _elapsedSeconds = 0;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  String _formatTimer(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ─── 줌/팬 상태 ──────────────────────────────────────────────────────────────
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  double _baseScale = 1.0;
  Offset _baseFocal = Offset.zero;
  Offset _baseOffset = Offset.zero;
  bool _isDrawingGesture = false;
  bool _wasZoomGesture = false;

  // ─── 이미지 편집 모드 상태 ────────────────────────────────────────────────────
  double _imageBaseX = 0;
  double _imageBaseY = 0;
  double _imageBaseWidth = 0;
  double _imageBaseHeight = 0;
  bool _imageDidMove = false;

  Offset _toCanvas(Offset screenPos) => (screenPos - _offset) / _scale;

  Matrix4 _buildMatrix() {
    final m = Matrix4.diagonal3Values(_scale, _scale, 1.0);
    m.setTranslationRaw(_offset.dx, _offset.dy, 0.0);
    return m;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(currentUserProvider);
      ref.read(lessonProvider.notifier).initialize(
            widget.channelName,
            session?.id ?? 0,
            session?.isTutor ?? false,
          );
      // 웹에서는 isInChannel이 설정되지 않으므로 즉시 타이머 시작
      if (kIsWeb) _startTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    ref.listen<LessonState>(lessonProvider, (prev, next) {
      // 실기기: 채널 입장 시점에 타이머 시작
      if (!kIsWeb && next.isInChannel && !(prev?.isInChannel ?? false)) {
        _startTimer();
      }
      // 수업 완료 시 홈으로 이동
      if (next.isCompleted && !(prev?.isCompleted ?? false)) {
        context.go('/');
      }
      // 원격 줌 동기화
      if (prev?.remoteScale != next.remoteScale ||
          prev?.remoteOffsetX != next.remoteOffsetX ||
          prev?.remoteOffsetY != next.remoteOffsetY) {
        setState(() {
          _scale = next.remoteScale;
          _offset = Offset(next.remoteOffsetX, next.remoteOffsetY);
        });
      }
    });

    final state = ref.watch(lessonProvider);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: shell.scaffoldBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && !state.isInChannel) {
      return Scaffold(
        backgroundColor: shell.scaffoldBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: shell.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state, shell),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildWhiteboard(state),
                  _buildFloatingToolbar(state, shell),
                ],
              ),
            ),
            _buildBottomBar(state, shell),
          ],
        ),
      ),
    );
  }

  // ─── 상단 바 ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(LessonState state, ShellTheme shell) {
    return Container(
      color: shell.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 과목명 pill (텍스트 길이에 맞게 자동 크기)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Text(
              widget.channelName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 빨간 점 + 타이머 (과목명 바로 우측)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.buttonDanger,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatTimer(_elapsedSeconds),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: shell.hintColor,
                ),
              ),
            ],
          ),
          // 우측: 강의 종료
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _confirmComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.buttonDanger,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '강의 종료',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 화이트보드 ─────────────────────────────────────────────────────────────

  Widget _buildWhiteboard(LessonState state) {
    final notifier = ref.read(lessonProvider.notifier);

    return ClipPath(
      clipper: const _WhiteboardClipper(),
      child: Container(
        color: AppColors.whiteboardBackground,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (d) {
            final s = ref.read(lessonProvider);
            if (s.isImageEditMode) {
              if (_isDrawingGesture) notifier.cancelCurrentStroke();
              _isDrawingGesture = false;
              _wasZoomGesture = false;
              _imageBaseX = s.imageX;
              _imageBaseY = s.imageY;
              _imageBaseWidth = s.imageWidth;
              _imageBaseHeight = s.imageHeight;
              _imageDidMove = false;
              _baseFocal = d.localFocalPoint;
              _baseScale = 1.0;
              return;
            }
            _isDrawingGesture = true;
            _wasZoomGesture = false;
            _baseScale = _scale;
            _baseFocal = d.localFocalPoint;
            _baseOffset = _offset;
            notifier.onPanStart(_toCanvas(d.localFocalPoint));
          },
          onScaleUpdate: (d) {
            final s = ref.read(lessonProvider);
            if (s.isImageEditMode) {
              _imageDidMove = true;
              if (d.pointerCount >= 2) {
                final newW = (_imageBaseWidth * d.scale).clamp(50.0, 3000.0);
                final newH = (_imageBaseHeight * d.scale).clamp(50.0, 3000.0);
                final cx = _imageBaseX + _imageBaseWidth / 2;
                final cy = _imageBaseY + _imageBaseHeight / 2;
                notifier.updateImageBounds(
                  x: cx - newW / 2,
                  y: cy - newH / 2,
                  width: newW,
                  height: newH,
                );
              } else {
                final canvasDelta = (d.localFocalPoint - _baseFocal) / _scale;
                notifier.updateImageBounds(
                  x: _imageBaseX + canvasDelta.dx,
                  y: _imageBaseY + canvasDelta.dy,
                  width: s.imageWidth,
                  height: s.imageHeight,
                );
              }
              return;
            }
            if (d.pointerCount >= 2) {
              if (_isDrawingGesture) {
                notifier.cancelCurrentStroke();
                _isDrawingGesture = false;
              }
              _wasZoomGesture = true;
              final newScale = (_baseScale * d.scale).clamp(0.5, 4.0);
              final focalCanvas = (_baseFocal - _baseOffset) / _baseScale;
              setState(() {
                _scale = newScale;
                _offset = d.localFocalPoint - focalCanvas * newScale;
              });
            } else if (_isDrawingGesture) {
              notifier.onPanUpdate(_toCanvas(d.localFocalPoint));
            }
          },
          onScaleEnd: (_) {
            final s = ref.read(lessonProvider);
            if (s.isImageEditMode) {
              if (!_imageDidMove) {
                final p = _toCanvas(_baseFocal);
                final outside = p.dx < s.imageX ||
                    p.dx > s.imageX + s.imageWidth ||
                    p.dy < s.imageY ||
                    p.dy > s.imageY + s.imageHeight;
                if (outside) notifier.exitImageEditMode();
              } else {
                notifier.sendImageMove();
              }
              _imageDidMove = false;
              _isDrawingGesture = false;
              _wasZoomGesture = false;
              return;
            }
            if (_isDrawingGesture) {
              notifier.onPanEnd();
              _isDrawingGesture = false;
            }
            if (_wasZoomGesture) {
              notifier.sendZoom(_scale, _offset);
              _wasZoomGesture = false;
            }
          },
          child: Transform(
            transform: _buildMatrix(),
            child: SizedBox(
              width: 5000,
              height: 5000,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  if (state.backgroundImageUrl != null)
                    state.imageWidth > 0
                        ? Positioned(
                            left: state.imageX,
                            top: state.imageY,
                            width: state.imageWidth,
                            height: state.imageHeight,
                            child: DecoratedBox(
                              decoration: state.isImageEditMode
                                  ? BoxDecoration(
                                      border: Border.all(
                                          color: Colors.blue, width: 2))
                                  : const BoxDecoration(),
                              child: Image.network(
                                state.backgroundImageUrl!,
                                fit: BoxFit.fill,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          )
                        : Image.network(
                            state.backgroundImageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                  CustomPaint(
                    painter: WhiteboardPainter(
                      strokes: state.strokes,
                      currentStroke: state.currentStroke,
                      remoteStroke: state.remoteStroke,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── 우측 플로팅 툴바 ────────────────────────────────────────────────────────

  static const _penColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  Widget _buildFloatingToolbar(LessonState state, ShellTheme shell) {
    final notifier = ref.read(lessonProvider.notifier);
    final isEraser = state.isEraserMode;
    final isImageEdit = state.isImageEditMode;
    final canUndo = state.undoHistory.isNotEmpty;
    final canRedo = state.redoHistory.isNotEmpty;

    return Positioned(
      right: 12,
      bottom: 16,
      child: Container(
        decoration: BoxDecoration(
          color: shell.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolBtn(
              icon: Icons.edit_outlined,
              active: !isEraser && !isImageEdit,
              shell: shell,
              onTap: () => notifier.setPenColor(state.currentPenColor),
            ),
            _ToolBtn(
              icon: Icons.auto_fix_normal,
              active: isEraser,
              shell: shell,
              onTap: () => notifier.toggleEraser(),
            ),
            _ToolBtn(
              icon: Icons.undo,
              enabled: canUndo,
              shell: shell,
              onTap: canUndo ? () => notifier.undo() : null,
            ),
            _ToolBtn(
              icon: Icons.redo,
              enabled: canRedo,
              shell: shell,
              onTap: canRedo ? () => notifier.redo() : null,
            ),
            _ToolBtn(
              icon: Icons.image_outlined,
              shell: shell,
              onTap: () => _pickAndUploadImage(),
            ),
            if (state.backgroundImageUrl != null)
              _ToolBtn(
                icon: Icons.open_with,
                active: isImageEdit,
                shell: shell,
                onTap: () => notifier.toggleImageEditMode(),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Divider(height: 1, color: shell.borderColor),
            ),
            ..._penColors.map((c) => _ColorDot(
                  color: c,
                  selected: !isEraser && state.currentPenColor == c,
                  onTap: () => notifier.setPenColor(c),
                )),
          ],
        ),
      ),
    );
  }

  // ─── 하단 바 ─────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(LessonState state, ShellTheme shell) {
    final notifier = ref.read(lessonProvider.notifier);

    return Container(
      color: shell.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _Avatar(
            label: state.isTutor ? 'T' : 'S',
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 6),
          _Avatar(
            label: state.isTutor ? 'S' : 'T',
            color: AppColors.roleStudentAccent,
          ),
          const SizedBox(width: 20),
          _ControlBtn(
            icon: state.isMicEnabled ? Icons.mic : Icons.mic_off,
            active: state.isMicEnabled,
            shell: shell,
            onTap: () => notifier.toggleMic(),
          ),
          if (state.isTutor) ...[
            const SizedBox(width: 8),
            _ControlBtn(
              icon: state.localCameraEnabled
                  ? Icons.videocam_outlined
                  : Icons.videocam_off_outlined,
              active: state.localCameraEnabled,
              shell: shell,
              onTap: () => notifier.toggleCamera(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 공통 로직 ───────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadImage() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (file == null) return;
    await ref.read(lessonProvider.notifier).uploadImage(file);
  }

  Future<void> _confirmComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('수업 완료'),
        content: const Text('수업을 종료하시겠습니까?\n녹화가 저장됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(lessonProvider.notifier).completeLesson();
    }
  }
}

// ─── 플로팅 툴바 버튼 ──────────────────────────────────────────────────────────

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool enabled;
  final ShellTheme shell;
  final VoidCallback? onTap;

  const _ToolBtn({
    required this.icon,
    required this.shell,
    this.active = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = !enabled
        ? shell.hintColor
        : active
            ? AppColors.primaryBlue
            : shell.titleColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }
}

// ─── 색상 원형 버튼 ────────────────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primaryBlue : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// ─── 아바타 ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String label;
  final Color color;

  const _Avatar({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── 하단 컨트롤 버튼 ─────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final ShellTheme shell;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.shell,
    required this.onTap,
    this.active = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active
              ? shell.iconBackground
              : shell.hintColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: active ? shell.titleColor : shell.hintColor,
        ),
      ),
    );
  }
}

// ─── 화이트보드 클리퍼 ────────────────────────────────────────────────────────
// 나중에 카메라 화면 분할 기능 추가 예정이므로 유지

class _WhiteboardClipper extends CustomClipper<Path> {
  const _WhiteboardClipper();

  @override
  Path getClip(Size size) => Path()
    ..addRect(Rect.fromLTRB(
      -size.width * 100,
      0,
      size.width * 100,
      size.height * 100,
    ));

  @override
  bool shouldReclip(_WhiteboardClipper oldClipper) => false;
}
