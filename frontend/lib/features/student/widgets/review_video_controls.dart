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
  double _volumeBeforeMute = 1.0;

  final _volumeLayerLink = LayerLink();
  OverlayEntry? _volumeOverlayEntry;

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
    _volumeOverlayEntry?.remove();
    super.dispose();
  }

  void _onValueChanged() {
    if (mounted) setState(() {});
    _volumeOverlayEntry?.markNeedsBuild();
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
    if (_volumeOverlayEntry != null) {
      _hideVolumeOverlay();
      return;
    }
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

  void _setVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    _chewieController.setVolume(clamped);
    if (clamped > 0) _volumeBeforeMute = clamped;
  }

  void _toggleMute() {
    final current = _controller.value.volume;
    if (current == 0) {
      _setVolume(_volumeBeforeMute > 0 ? _volumeBeforeMute : 1.0);
    } else {
      _volumeBeforeMute = current;
      _setVolume(0);
    }
  }

  void _toggleVolumeSlider() {
    if (_volumeOverlayEntry != null) {
      _hideVolumeOverlay();
    } else {
      _hideTimer?.cancel();
      _showVolumeOverlay();
    }
  }

  void _showVolumeOverlay() {
    final overlay = Overlay.of(context, rootOverlay: true);
    _volumeOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hideVolumeOverlay,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _volumeLayerLink,
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 48,
                    height: 136,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _VerticalVolumeSlider(
                        value: _controller.value.volume,
                        onChanged: _setVolume,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_volumeOverlayEntry!);
    setState(() {});
  }

  void _hideVolumeOverlay() {
    _volumeOverlayEntry?.remove();
    _volumeOverlayEntry = null;
    if (mounted) {
      setState(() {});
      _resetHideTimer();
    }
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
        _setVolume(_controller.value.volume + 0.1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _setVolume(_controller.value.volume - 0.1);
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
                  _circleButton(
                    icon: Icons.replay_10_rounded,
                    size: 44,
                    iconSize: 22,
                    onTap: () => _skip(-10),
                  ),
                  const SizedBox(width: 20),
                  _circleButton(
                    icon: value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 64,
                    iconSize: 34,
                    onTap: _togglePlayPause,
                  ),
                  const SizedBox(width: 20),
                  _circleButton(
                    icon: Icons.forward_10_rounded,
                    size: 44,
                    iconSize: 22,
                    onTap: () => _skip(10),
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
                          CompositedTransformTarget(
                            link: _volumeLayerLink,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: _toggleVolumeSlider,
                              onLongPress: _toggleMute,
                              icon: Icon(
                                value.volume == 0
                                    ? Icons.volume_off_rounded
                                    : value.volume < 0.5
                                        ? Icons.volume_down_rounded
                                        : Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
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

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
    required double iconSize,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}

class _VerticalVolumeSlider extends StatelessWidget {
  const _VerticalVolumeSlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  void _updateFromDy(double dy, double height) {
    if (height <= 0) return;
    onChanged((1 - (dy / height)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    const trackHeight = 112.0;
    const trackWidth = 4.0;
    const thumbSize = 14.0;
    const hitWidth = 36.0;
    final fillHeight = trackHeight * value;
    final thumbBottom =
        (fillHeight - thumbSize / 2).clamp(0.0, trackHeight - thumbSize);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _updateFromDy(event.localPosition.dy, trackHeight),
      onPointerMove: (event) => _updateFromDy(event.localPosition.dy, trackHeight),
      child: SizedBox(
        width: hitWidth,
        height: trackHeight,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: trackWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: trackWidth,
                height: fillHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: thumbBottom,
              child: Center(
                child: Container(
                  width: thumbSize,
                  height: thumbSize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}