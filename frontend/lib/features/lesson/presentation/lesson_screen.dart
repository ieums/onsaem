import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import 'lesson_provider.dart';
import 'whiteboard_painter.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String channelName;
  final int uid;
  final bool isTutor;

  const LessonScreen({
    super.key,
    required this.channelName,
    required this.uid,
    required this.isTutor,
  });

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final _imagePicker = ImagePicker();

  // ─── 줌/팬 상태 (커스텀 Transform) ──────────────────────────────────────────
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // 제스처 시작 시 스냅샷
  double _baseScale = 1.0;
  Offset _baseFocal = Offset.zero;
  Offset _baseOffset = Offset.zero;
  bool _isDrawingGesture = false;

  /// 화면 좌표 → 캔버스 좌표 변환
  /// Transform = T(offset) * S(scale) 이므로
  /// screenPos = scale * canvasPos + offset → canvasPos = (screenPos - offset) / scale
  Offset _toCanvas(Offset screenPos) {
    return (screenPos - _offset) / _scale;
  }

  /// Transform 행렬: screenPos = scale * canvasPos + offset
  Matrix4 _buildMatrix() {
    final m = Matrix4.diagonal3Values(_scale, _scale, 1.0);
    m.setTranslationRaw(_offset.dx, _offset.dy, 0.0);
    return m;
  }

  // ─────────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lessonProvider.notifier).initialize(
            widget.channelName,
            widget.uid,
            widget.isTutor,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 수업 완료 시 홈으로 이동
    ref.listen<LessonState>(lessonProvider, (prev, next) {
      if (next.isCompleted && !(prev?.isCompleted ?? false)) {
        context.go('/');
      }
    });

    final state = ref.watch(lessonProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && !state.isInChannel) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 48),
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildVideoArea(state),
            _buildWhiteboard(state),
            _buildActionBar(state),
          ],
        ),
      ),
    );
  }

  // ─── 영상 영역 ──────────────────────────────────────────────────────────────

  Widget _buildVideoArea(LessonState state) {
    // 튜터: 자신의 카메라 상태 기준 / 학생: 강사의 카메라 상태(STOMP 동기화) 기준
    final showVideo = widget.isTutor
        ? state.localCameraEnabled
        : state.remoteCameraEnabled;
    final videoHeight =
        showVideo ? MediaQuery.of(context).size.height * 0.22 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: videoHeight,
      color: Colors.black,
      child: showVideo
          ? (state.isInChannel
              ? _buildAgoraView(state)
              : _buildVideoPlaceholder())
          : const SizedBox.shrink(),
    );
  }

  Widget _buildAgoraView(LessonState state) {
    final engine = ref.read(lessonProvider.notifier).engine;
    if (engine == null) return _buildVideoPlaceholder();

    if (widget.isTutor) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    }

    final remoteUid = state.remoteUid;
    if (remoteUid == null) {
      return _buildVideoPlaceholder(label: '강사 연결 대기 중...');
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: engine,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _buildVideoPlaceholder({String label = '연결 중...'}) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 36),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ─── 화이트보드 ─────────────────────────────────────────────────────────────

  Widget _buildWhiteboard(LessonState state) {
    final notifier = ref.read(lessonProvider.notifier);

    return Expanded(
      child: ClipRect(
        child: Container(
          color: AppColors.whiteboardBackground,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // onScaleStart/Update/End으로 단일 손가락(드로잉)과
            // 멀티 손가락(줌+팬)을 하나의 recognizer로 처리 → 충돌 없음
            onScaleStart: (d) {
              // 시작은 항상 1 pointer (추가 pointer는 onScaleUpdate에서 감지)
              _isDrawingGesture = true;
              _baseScale = _scale;
              _baseFocal = d.localFocalPoint;
              _baseOffset = _offset;
              notifier.onPanStart(_toCanvas(d.localFocalPoint));
            },
            onScaleUpdate: (d) {
              if (d.pointerCount >= 2) {
                // 두 손가락: 줌 + 팬
                if (_isDrawingGesture) {
                  notifier.onPanEnd(); // 진행 중인 드로잉 스트로크 마무리
                  _isDrawingGesture = false;
                }
                final newScale = (_baseScale * d.scale).clamp(0.5, 4.0);
                // 시작 focal 아래의 캔버스 점이 현재 focal 아래에 유지되도록 offset 계산
                final focalCanvas = (_baseFocal - _baseOffset) / _baseScale;
                setState(() {
                  _scale = newScale;
                  _offset = d.localFocalPoint - focalCanvas * newScale;
                });
              } else if (_isDrawingGesture) {
                // 한 손가락: 드로잉
                notifier.onPanUpdate(_toCanvas(d.localFocalPoint));
              }
            },
            onScaleEnd: (_) {
              if (_isDrawingGesture) {
                notifier.onPanEnd();
                _isDrawingGesture = false;
              }
            },
            child: Transform(
              transform: _buildMatrix(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (state.backgroundImageUrl != null)
                    Image.network(
                      state.backgroundImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
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

  // ─── 하단 액션 바 ───────────────────────────────────────────────────────────

  static const _penColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  Widget _buildActionBar(LessonState state) {
    final notifier = ref.read(lessonProvider.notifier);
    final canUndo = state.undoHistory.isNotEmpty;
    final canRedo = state.redoHistory.isNotEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 행 1: 색상 팔레트 + 지우개
          _buildColorPalette(state),
          const SizedBox(height: 6),
          // 행 2: Undo, Redo, 이미지, 수업완료, 카메라
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Undo
              IconButton(
                onPressed: canUndo ? () => notifier.undo() : null,
                icon: Icon(
                  Icons.undo,
                  color: canUndo ? AppColors.textPrimary : Colors.grey[400],
                ),
                tooltip: '실행 취소',
              ),
              // Redo
              IconButton(
                onPressed: canRedo ? () => notifier.redo() : null,
                icon: Icon(
                  Icons.redo,
                  color: canRedo ? AppColors.textPrimary : Colors.grey[400],
                ),
                tooltip: '다시 실행',
              ),
              _ActionButton(
                icon: Icons.image_outlined,
                label: '이미지',
                onTap: () => _pickAndUploadImage(),
              ),
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: '수업완료',
                color: AppColors.buttonDanger,
                onTap: () => _confirmComplete(),
              ),
              if (widget.isTutor)
                _ActionButton(
                  icon: state.localCameraEnabled
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_outlined,
                  label: state.localCameraEnabled ? '카메라 끄기' : '카메라 켜기',
                  onTap: () => notifier.toggleCamera(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette(LessonState state) {
    final notifier = ref.read(lessonProvider.notifier);
    final isEraser = state.isEraserMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 색상 팔레트
        ..._penColors.map((color) {
          final isSelected = !isEraser && state.currentPenColor == color;
          return GestureDetector(
            onTap: () => notifier.setPenColor(color),
            child: Opacity(
              opacity: isEraser ? 0.4 : 1.0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black87 : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        // 지우개 버튼
        GestureDetector(
          onTap: () => notifier.toggleEraser(),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isEraser ? Colors.grey[300] : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isEraser ? Colors.black54 : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.auto_fix_normal,
              size: 22,
              color: isEraser ? Colors.black87 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

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

// ─── 재사용 버튼 위젯 ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
