import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/screens/student_review_write_screen.dart';
import 'package:ieum/features/student/widgets/classroom_problem_view.dart';
import 'package:ieum/features/student/widgets/classroom_whiteboard.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

enum ClassroomViewMode { whiteboard, problem }

class StudentClassroomScreen extends ConsumerStatefulWidget {
  const StudentClassroomScreen({super.key});

  @override
  ConsumerState<StudentClassroomScreen> createState() =>
      _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends ConsumerState<StudentClassroomScreen> {
  static const _endButton = Color(0xFFE85D4C);

  late final DateTime _startedAt;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isMuted = false;
  ClassroomViewMode _viewMode = ClassroomViewMode.whiteboard;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_startedAt);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  ThemeData _flowTheme(bool isDark) {
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmEndClass() async {
    final shell = ShellTheme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(dialogContext).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '강의를 종료하시겠어요?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: shell.titleColor,
            ),
          ),
          content: Text(
            '종료하면 리뷰 작성 화면으로 이동합니다.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: shell.subtitleColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                '계속하기',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: shell.subtitleColor,
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: _endButton,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                '종료',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final session = ref.read(studentMatchingSessionProvider);
    if (session == null) {
      if (!mounted) return;
      context.go(RoutePaths.studentHome);
      return;
    }

    final tutor = session.selectedTutor;
    final tutorId = tutor?.id ?? session.selectedTutorId;
    if (tutorId == null) {
      if (!mounted) return;
      context.go(RoutePaths.studentHome);
      return;
    }

    if (!mounted) return;

    context.go(
      RoutePaths.studentReviewWrite,
      extra: StudentReviewWriteArgs(
        tutorId: tutorId,
        tutorName: tutor?.name ?? '강사',
        subject: session.subject,
        tutorSubtitle: '${session.subject} 전문 강사',
        avatarInitial: tutor?.avatarInitial ?? '강',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studentMatchingSessionProvider);
    final isDark = ref.watch(shellDarkModeProvider);
    final theme = _flowTheme(isDark);

    if (session == null ||
        session.status != StudentMatchingSessionStatus.connected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go(RoutePaths.studentHome);
      });
      return Theme(
        data: theme,
        child: const Scaffold(body: SizedBox.shrink()),
      );
    }

    final tutor = session.selectedTutor;
    final tutorName = tutor?.name ?? '강사';

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          final pageBg = theme.scaffoldBackgroundColor;

          return Scaffold(
            backgroundColor: pageBg,
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        TutorSubjectBadge(subject: session.subject),
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_elapsed),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: shell.titleColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _confirmEndClass,
                          style: FilledButton.styleFrom(
                            backgroundColor: _endButton,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '강의 종료',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: IndexedStack(
                        index: _viewMode == ClassroomViewMode.whiteboard ? 0 : 1,
                        children: [
                          ClassroomWhiteboard(
                            key: const ValueKey('classroom-whiteboard'),
                            frameBorderColor: shell.cardBorder,
                          ),
                          ClassroomProblemView(
                            key: const ValueKey('classroom-problem'),
                            summary: session.questionSummary,
                            imageBytes: session.problemImageBytes,
                            frameBorderColor: shell.cardBorder,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: shell.cardBackground,
                      border: Border(top: BorderSide(color: shell.cardBorder)),
                    ),
                    child: Row(
                      children: [
                        _ParticipantTile(
                          label: '나',
                          initial: '나',
                          accent: AppColors.studentInk,
                          tileBackground: shell.detailBackground,
                          tileBorder: shell.cardBorder,
                          labelColor: shell.subtitleColor,
                          onlineRingColor: shell.cardBackground,
                        ),
                        const SizedBox(width: 10),
                        _ParticipantTile(
                          label: tutorName,
                          initial: tutorName.isNotEmpty ? tutorName[0] : '?',
                          accent: AppColors.primaryBlue,
                          isOnline: true,
                          tileBackground: shell.detailBackground,
                          tileBorder: shell.cardBorder,
                          labelColor: shell.subtitleColor,
                          onlineRingColor: shell.cardBackground,
                        ),
                        const Spacer(),
                        _ClassroomViewToggle(
                          mode: _viewMode,
                          trackBackground: shell.detailBackground,
                          onChanged: (mode) =>
                              setState(() => _viewMode = mode),
                        ),
                        const SizedBox(width: 10),
                        _RoundControlButton(
                          icon: _isMuted
                              ? Icons.mic_off_rounded
                              : Icons.mic_rounded,
                          active: !_isMuted,
                          activeColor: AppColors.vividBlue,
                          danger: _isMuted,
                          idleBackground: shell.detailBackground,
                          onTap: () => setState(() => _isMuted = !_isMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.label,
    required this.initial,
    required this.accent,
    required this.tileBackground,
    required this.tileBorder,
    required this.labelColor,
    required this.onlineRingColor,
    this.isOnline = false,
  });

  final String label;
  final String initial;
  final Color accent;
  final Color tileBackground;
  final Color tileBorder;
  final Color labelColor;
  final Color onlineRingColor;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tileBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tileBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              if (isOnline)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.incomeGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: onlineRingColor, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassroomViewToggle extends StatelessWidget {
  const _ClassroomViewToggle({
    required this.mode,
    required this.trackBackground,
    required this.onChanged,
  });

  final ClassroomViewMode mode;
  final Color trackBackground;
  final ValueChanged<ClassroomViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: trackBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleChip(
            label: '화이트보드',
            icon: Icons.draw_rounded,
            selected: mode == ClassroomViewMode.whiteboard,
            isDark: isDark,
            onTap: () => onChanged(ClassroomViewMode.whiteboard),
          ),
          _ViewToggleChip(
            label: '문제',
            icon: Icons.quiz_rounded,
            selected: mode == ClassroomViewMode.problem,
            isDark: isDark,
            onTap: () => onChanged(ClassroomViewMode.problem),
          ),
        ],
      ),
    );
  }
}

class _ViewToggleChip extends StatelessWidget {
  const _ViewToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final background = selected
        ? AppColors.vividBlue
        : Colors.transparent;
    final foreground = selected
        ? Colors.white
        : (isDark ? shell.subtitleColor : shell.titleColor);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.icon,
    required this.active,
    required this.onTap,
    required this.idleBackground,
    this.activeColor = AppColors.vividBlue,
    this.danger = false,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color idleBackground;
  final Color activeColor;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);

    final background = danger
        ? AppColors.logoutRed.withValues(alpha: 0.14)
        : active
            ? activeColor.withValues(alpha: 0.16)
            : idleBackground;
    final foreground = danger
        ? AppColors.logoutRed
        : active
            ? activeColor
            : shell.subtitleColor;

    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: foreground, size: 22),
        ),
      ),
    );
  }
}
