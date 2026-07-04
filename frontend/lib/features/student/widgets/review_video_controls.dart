import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Chewie 기본 MaterialControls가 시간 텍스트를 고정폭(RichText)으로 그려서
/// 좁은 화면 + 긴 재생시간(1시간+)에서 오버플로우가 나는 문제를 피하려고
/// 최소 구성으로 새로 만든 컨트롤. 시간 텍스트만 Expanded로 감싸서 흘러넘치면 말줄임.
class ReviewVideoControls extends StatefulWidget {
  const ReviewVideoControls({super.key});

  @override
  State<ReviewVideoControls> createState() => _ReviewVideoControlsState();
}

class _ReviewVideoControlsState extends State<ReviewVideoControls> {
  static const _speedValues = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const _speedLabels = ['0.5', '0.75', '1', '1.25', '1.5', '2'];

  late final ChewieController _chewieController;
  VideoPlayerController get _controller => _chewieController.videoPlayerController;

  bool _showControls = true;
  Timer? _hideTimer;
  int _speedIndex = 2; // 1.0x
  bool _dragging = false;
  double _dragValue = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chewieController = ChewieController.of(context);
    _controller.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onValueChanged);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onValueChanged() {
    if (mounted) setState(() {});
  }

  // 재생 중일 때만 3초 후 컨트롤을 자동으로 숨김. 조작할 때마다 다시 3초 연장.
  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (_showControls && _controller.value.isPlaying) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _handleTap() {
    setState(() => _showControls = !_showControls);
    _resetHideTimer();
  }

  void _togglePlayPause() {
    _chewieController.togglePause();
    _resetHideTimer();
  }

  void _skip(int seconds) {
    final target = _controller.value.position + Duration(seconds: seconds);
    final duration = _controller.value.duration;
    _chewieController.seekTo(
      target < Duration.zero
          ? Duration.zero
          : (target > duration ? duration : target),
    );
    _resetHideTimer();
  }

  void _cycleSpeed() {
    setState(() => _speedIndex = (_speedIndex + 1) % _speedValues.length);
    _controller.setPlaybackSpeed(_speedValues[_speedIndex]);
    _resetHideTimer();
  }

  void _changeVolume(double delta) {
    final next = (_controller.value.volume + delta).clamp(0.0, 1.0);
    _chewieController.setVolume(next);
    _resetHideTimer();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        _togglePlayPause();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _skip(-10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _skip(10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _changeVolume(0.1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _changeVolume(-0.1);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;
    final position = value.position;
    final duration = value.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_showControls)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 32,
                    color: Colors.white,
                    icon: const Icon(Icons.replay_10_rounded),
                    onPressed: () => _skip(-10),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 52,
                    color: Colors.white,
                    icon: Icon(value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill),
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 32,
                    color: Colors.white,
                    icon: const Icon(Icons.forward_10_rounded),
                    onPressed: () => _skip(10),
                  ),
                ],
              ),
            if (_showControls)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 30, 12, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final shownValue = (_dragging ? _dragValue : progress).clamp(0.0, 1.0);
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: shownValue,
                                  onChangeStart: (v) {
                                    _hideTimer?.cancel();
                                    setState(() {
                                      _dragging = true;
                                      _dragValue = v;
                                    });
                                  },
                                  onChanged: (v) => setState(() => _dragValue = v),
                                  onChangeEnd: (v) {
                                    _chewieController.seekTo(duration * v);
                                    setState(() => _dragging = false);
                                    _resetHideTimer();
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white24,
                                ),
                              ),
                              // 드래그 중일 때만 썸 위에 시간 미리보기 말풍선 표시.
                              if (_dragging)
                                Positioned(
                                  left: (constraints.maxWidth - 44) * shownValue,
                                  top: -22,
                                  child: Container(
                                    width: 44,
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _fmt(duration * shownValue),
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(
                              value.volume == 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _chewieController
                                .setVolume(value.volume == 0 ? 1.0 : 0.0),
                          ),
                          Expanded(
                            child: Text(
                              '${_fmt(position)} / ${_fmt(duration)}',
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _cycleSpeed,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '${_speedLabels[_speedIndex]}x',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: Icon(
                              _chewieController.isFullScreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _chewieController.toggleFullScreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}