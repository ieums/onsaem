import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/student/data/student_review_dummy_data.dart';

class ReviewVideoPlaybackState {
  const ReviewVideoPlaybackState({
    required this.positionSeconds,
    required this.isPlaying,
    required this.volumeLevel,
    required this.volumeBeforeMute,
    required this.speedIndex,
  });

  final double positionSeconds;
  final bool isPlaying;
  final double volumeLevel;
  final double volumeBeforeMute;
  final int speedIndex;
}

class StudentReviewVideoPlayer extends StatefulWidget {
  const StudentReviewVideoPlayer({
    super.key,
    required this.durationSeconds,
    required this.initialPositionSeconds,
    this.isFullscreen = false,
    this.initialPlaybackState,
    this.borderRadius = 14,
  });

  final int durationSeconds;
  final int initialPositionSeconds;
  final bool isFullscreen;
  final ReviewVideoPlaybackState? initialPlaybackState;
  final double borderRadius;

  @override
  State<StudentReviewVideoPlayer> createState() =>
      _StudentReviewVideoPlayerState();
}

class _StudentReviewVideoPlayerState extends State<StudentReviewVideoPlayer> {
  static const _speedValues = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  static const _speedLabels = ['0.5', '0.75', '1', '1.25', '1.5', '2'];

  Timer? _playbackTimer;
  late double _positionSeconds;
  late bool _isPlaying;
  late double _volumeLevel;
  late double _volumeBeforeMute;
  late int _speedIndex;
  bool _showVolumeSlider = false;
  final _volumeLayerLink = LayerLink();
  OverlayEntry? _volumeOverlayEntry;

  int get _durationSeconds => widget.durationSeconds;

  double get _progress =>
      _durationSeconds == 0 ? 0 : _positionSeconds / _durationSeconds;

  String get _positionLabel =>
      StudentReviewVideoTime.formatSeconds(_positionSeconds.round());

  String get _durationLabel =>
      StudentReviewVideoTime.formatSeconds(_durationSeconds);

  IconData get _volumeIcon {
    if (_volumeLevel == 0) return Icons.volume_off_rounded;
    if (_volumeLevel < 0.5) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  ReviewVideoPlaybackState get _playbackState => ReviewVideoPlaybackState(
        positionSeconds: _positionSeconds,
        isPlaying: _isPlaying,
        volumeLevel: _volumeLevel,
        volumeBeforeMute: _volumeBeforeMute,
        speedIndex: _speedIndex,
      );

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPlaybackState;
    _positionSeconds = initial?.positionSeconds ??
        widget.initialPositionSeconds.toDouble();
    _isPlaying = initial?.isPlaying ?? false;
    _volumeLevel = initial?.volumeLevel ?? 1.0;
    _volumeBeforeMute = initial?.volumeBeforeMute ?? 1.0;
    _speedIndex = initial?.speedIndex ?? 2;
    if (_isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startPlayback());
    }
  }

  @override
  void dispose() {
    _removeVolumeOverlay();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _setVolumeLevel(double value) {
    setState(() {
      _volumeLevel = value.clamp(0.0, 1.0);
      if (_volumeLevel > 0) {
        _volumeBeforeMute = _volumeLevel;
      }
    });
    _volumeOverlayEntry?.markNeedsBuild();
  }

  void _toggleVolumeSlider() {
    if (_showVolumeSlider) {
      _hideVolumeOverlay();
    } else {
      _showVolumeOverlay();
    }
  }

  void _showVolumeOverlay() {
    final overlay = Overlay.of(context, rootOverlay: true);
    _volumeOverlayEntry?.remove();
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
                        value: _volumeLevel,
                        onChanged: _setVolumeLevel,
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
    setState(() => _showVolumeSlider = true);
  }

  void _removeVolumeOverlay() {
    _volumeOverlayEntry?.remove();
    _volumeOverlayEntry = null;
    _showVolumeSlider = false;
  }

  void _hideVolumeOverlay() {
    _removeVolumeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleMute() {
    setState(() {
      if (_volumeLevel == 0) {
        _volumeLevel = _volumeBeforeMute > 0 ? _volumeBeforeMute : 1.0;
      } else {
        _volumeBeforeMute = _volumeLevel;
        _volumeLevel = 0;
      }
    });
    _volumeOverlayEntry?.markNeedsBuild();
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _stopPlayback();
    } else {
      if (_positionSeconds >= _durationSeconds) {
        _positionSeconds = 0;
      }
      _startPlayback();
    }
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    setState(() => _isPlaying = true);
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final speed = _speedValues[_speedIndex];
      setState(() {
        _positionSeconds += 0.25 * speed;
        if (_positionSeconds >= _durationSeconds) {
          _positionSeconds = _durationSeconds.toDouble();
          _stopPlayback();
        }
      });
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    if (mounted) setState(() => _isPlaying = false);
  }

  void _seek(double value) {
    setState(() {
      _positionSeconds =
          (value * _durationSeconds).clamp(0, _durationSeconds.toDouble());
    });
  }

  void _skipSeconds(int delta) {
    setState(() {
      _positionSeconds =
          (_positionSeconds + delta).clamp(0, _durationSeconds.toDouble());
    });
  }

  void _cycleSpeed() {
    setState(() => _speedIndex = (_speedIndex + 1) % _speedValues.length);
    if (_isPlaying) {
      _stopPlayback();
      _startPlayback();
    }
  }

  ReviewVideoPlaybackState exportPlaybackState() => _playbackState;

  Future<void> _enterFullscreen() async {
    _hideVolumeOverlay();
    final snapshot = _playbackState;
    _stopPlayback();
    final result = await Navigator.of(context).push<ReviewVideoPlaybackState>(
      PageRouteBuilder<ReviewVideoPlaybackState>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return StudentReviewVideoFullscreenPage(
            durationSeconds: widget.durationSeconds,
            initialPlaybackState: snapshot,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    if (!mounted || result == null) return;
    _applyPlaybackState(result);
  }

  void _applyPlaybackState(ReviewVideoPlaybackState state) {
    _stopPlayback();
    setState(() {
      _positionSeconds = state.positionSeconds;
      _volumeLevel = state.volumeLevel;
      _volumeBeforeMute = state.volumeBeforeMute;
      _speedIndex = state.speedIndex;
    });
    if (state.isPlaying) {
      _startPlayback();
    }
  }

  void _exitFullscreen() {
    Navigator.of(context).pop(_playbackState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videoBg = isDark ? const Color(0xFF0E1014) : const Color(0xFF1A1D26);

    return OrientationBuilder(
      builder: (context, orientation) {
        final player = _buildPlayerSurface(videoBg);

        if (widget.isFullscreen) {
          return ColoredBox(
            color: Colors.black,
            child: player,
          );
        }

        final aspectRatio =
            orientation == Orientation.landscape ? 16 / 9 : 16 / 10;

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: ColoredBox(
            color: videoBg,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: player,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerSurface(Color videoBg) {
    return ColoredBox(
      color: videoBg,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: widget.isFullscreen ? 160 : 120,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _VideoCircleButton(
                icon: Icons.replay_10_rounded,
                onTap: () => _skipSeconds(-10),
              ),
              SizedBox(width: widget.isFullscreen ? 28 : 20),
              _VideoCircleButton(
                icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: widget.isFullscreen ? 64 : 56,
                iconSize: widget.isFullscreen ? 38 : 34,
                onTap: _togglePlayback,
              ),
              SizedBox(width: widget.isFullscreen ? 28 : 20),
              _VideoCircleButton(
                icon: Icons.forward_10_rounded,
                onTap: () => _skipSeconds(10),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12,
                widget.isFullscreen ? 28 : 20,
                12,
                widget.isFullscreen ? 16 : 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: _progress.clamp(0, 1),
                      onChanged: (value) {
                        _seek(value);
                        if (_isPlaying &&
                            _positionSeconds >= _durationSeconds) {
                          _stopPlayback();
                        }
                      },
                      activeColor: AppColors.studentPoint,
                      inactiveColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '$_positionLabel / $_durationLabel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      _buildVolumeControl(),
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.isFullscreen
                            ? _exitFullscreen
                            : _enterFullscreen,
                        icon: Icon(
                          widget.isFullscreen
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    return CompositedTransformTarget(
      link: _volumeLayerLink,
      child: IconButton(
        onPressed: _toggleVolumeSlider,
        onLongPress: _toggleMute,
        icon: Icon(
          _volumeIcon,
          color: Colors.white,
          size: 22,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }
}

class StudentReviewVideoFullscreenPage extends StatefulWidget {
  const StudentReviewVideoFullscreenPage({
    super.key,
    required this.durationSeconds,
    required this.initialPlaybackState,
  });

  final int durationSeconds;
  final ReviewVideoPlaybackState initialPlaybackState;

  @override
  State<StudentReviewVideoFullscreenPage> createState() =>
      _StudentReviewVideoFullscreenPageState();
}

class _StudentReviewVideoFullscreenPageState
    extends State<StudentReviewVideoFullscreenPage> {
  final _playerKey = GlobalKey<_StudentReviewVideoPlayerState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final state =
            _playerKey.currentState?.exportPlaybackState() ??
                widget.initialPlaybackState;
        Navigator.of(context).pop(state);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: StudentReviewVideoPlayer(
          key: _playerKey,
          durationSeconds: widget.durationSeconds,
          initialPositionSeconds:
              widget.initialPlaybackState.positionSeconds.round(),
          initialPlaybackState: widget.initialPlaybackState,
          isFullscreen: true,
          borderRadius: 0,
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
      onPointerDown: (event) =>
          _updateFromDy(event.localPosition.dy, trackHeight),
      onPointerMove: (event) =>
          _updateFromDy(event.localPosition.dy, trackHeight),
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
                  color: AppColors.studentPoint,
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

class _VideoCircleButton extends StatelessWidget {
  const _VideoCircleButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
    this.iconSize = 26,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
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
