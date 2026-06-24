import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/providers/student_shell_tab_provider.dart';

class StudentMatchingWaitScreen extends ConsumerStatefulWidget {
  const StudentMatchingWaitScreen({super.key});

  @override
  ConsumerState<StudentMatchingWaitScreen> createState() =>
      _StudentMatchingWaitScreenState();
}

class _StudentMatchingWaitScreenState
    extends ConsumerState<StudentMatchingWaitScreen> {
  Future<void> _cancelMatching() async {
    await ref.read(studentMatchingSessionProvider.notifier).cancelMatching();
  }

  Future<void> _switchToAiTutor() async {
    ref.read(studentShellTabIndexProvider.notifier).state =
        studentShellAiTutorTabIndex;
    await _cancelMatching();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(studentMatchingSessionProvider, (previous, next) {
      if (!mounted) return;
      if (next?.status == StudentMatchingSessionStatus.selectingTutor) {
        context.pushReplacement(RoutePaths.studentTutorSelection);
      } else if (next == null && previous != null) {
        context.pop();
      }
    });

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
          final session = ref.watch(studentMatchingSessionProvider);

          if (session == null) {
            return Scaffold(
              backgroundColor: pageBg,
              body: const SizedBox.shrink(),
            );
          }

          return PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: pageBg,
              appBar: AppBar(
                backgroundColor: pageBg,
                elevation: 0,
                automaticallyImplyLeading: false,
                centerTitle: false,
                title: Text(
                  '매칭 대기',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      _MatchingRippleVisual(
                        color: AppColors.studentInk,
                        iconColor: isDark
                            ? AppColors.shellOnSurfaceLight
                            : Colors.white,
                      ),
                      const SizedBox(height: 40),
                      Text(
                        session.waitingForSubjectExpert
                            ? '담당 과목 강사를 찾고 있어요...'
                            : '강사를 찾고 있어요...',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: shell.titleColor,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.waitingForSubjectExpert
                            ? '배정되면 알림으로 알려드릴게요.\n앱을 켜 두지 않아도 괜찮아요.'
                            : '곧 최적의 강사와 연결됩니다',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: shell.subtitleColor,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(flex: 3),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _switchToAiTutor,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.studentInk,
                              width: 1.5,
                            ),
                            foregroundColor: AppColors.studentInk,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                          child: const Text(
                            'AI 튜터로 변경하기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _cancelMatching,
                        child: Text(
                          '요청 취소',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: shell.subtitleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MatchingRippleVisual extends StatefulWidget {
  const _MatchingRippleVisual({
    required this.color,
    required this.iconColor,
  });

  final Color color;
  final Color iconColor;

  @override
  State<_MatchingRippleVisual> createState() => _MatchingRippleVisualState();
}

class _MatchingRippleVisualState extends State<_MatchingRippleVisual>
    with SingleTickerProviderStateMixin {
  static const _ringCount = 3;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      height: 340,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _MatchingRipplePainter(
              progress: _controller.value,
              color: widget.color,
              ringCount: _ringCount,
            ),
            child: Center(
              child: Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  size: 52,
                  color: widget.iconColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MatchingRipplePainter extends CustomPainter {
  _MatchingRipplePainter({
    required this.progress,
    required this.color,
    required this.ringCount,
  });

  final double progress;
  final Color color;
  final int ringCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final innerRadius = size.width * 0.16;
    final outerRadius = size.width * 0.46;

    for (var i = 0; i < ringCount; i++) {
      final phase = (progress + i / ringCount) % 1.0;
      final radius = innerRadius + (outerRadius - innerRadius) * phase;
      final opacity = (1 - phase).clamp(0.0, 1.0) * 0.55;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MatchingRipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
