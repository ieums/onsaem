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
    return Container(
      height: MediaQuery.of(context).size.height * 0.22,
      color: Colors.black,
      child: state.isInChannel ? _buildAgoraView(state) : _buildVideoPlaceholder(),
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
      child: Container(
        color: AppColors.whiteboardBackground,
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
            GestureDetector(
              onPanStart: (d) => notifier.onPanStart(d.localPosition),
              onPanUpdate: (d) => notifier.onPanUpdate(d.localPosition),
              onPanEnd: (_) => notifier.onPanEnd(),
              child: CustomPaint(
                painter: WhiteboardPainter(
                  strokes: state.strokes,
                  currentStroke: state.currentStroke,
                  remoteStroke: state.remoteStroke,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 하단 액션 바 ───────────────────────────────────────────────────────────

  Widget _buildActionBar(LessonState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
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
          _ActionButton(
            icon: state.localCameraEnabled
                ? Icons.videocam_outlined
                : Icons.videocam_off_outlined,
            label: state.localCameraEnabled ? '카메라 끄기' : '카메라 켜기',
            onTap: () =>
                ref.read(lessonProvider.notifier).toggleCamera(),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
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
            child:
                const Text('완료', style: TextStyle(color: Colors.white)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
