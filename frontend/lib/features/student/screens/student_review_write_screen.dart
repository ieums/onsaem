import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_matching_session_provider.dart';
import 'package:ieum/features/student/screens/student_report_screen.dart';
import 'package:ieum/routes/app_router.dart';

class StudentReviewWriteArgs {
  const StudentReviewWriteArgs({
    required this.tutorId,
    required this.tutorName,
    required this.subject,
    required this.tutorSubtitle,
    required this.avatarInitial,
  });

  final String tutorId;
  final String tutorName;
  final String subject;
  final String tutorSubtitle;
  final String avatarInitial;
}

class StudentReviewWriteScreen extends ConsumerStatefulWidget {
  const StudentReviewWriteScreen({super.key, required this.args});

  final StudentReviewWriteArgs args;

  @override
  ConsumerState<StudentReviewWriteScreen> createState() =>
      _StudentReviewWriteScreenState();
}

class _StudentReviewWriteScreenState
    extends ConsumerState<StudentReviewWriteScreen> {
  static const _maxReviewLength = 200;

  final _reviewController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _reviewController.dispose();
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

  String get _ratingHint {
    return switch (_rating) {
      0 => '강사님의 수업을 평가해주세요',
      1 => '아쉬워요',
      2 => '조금 아쉬워요',
      3 => '괜찮았어요',
      4 => '좋았어요!',
      _ => '최고예요!',
    };
  }

  Future<void> _finish({required bool submitted}) async {
    await ref.read(studentMatchingSessionProvider.notifier).cancelMatching();
    if (!mounted) return;
    context.go(RoutePaths.studentHome);
    if (!submitted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rootContext = appRouter.routerDelegate.navigatorKey.currentContext;
      if (rootContext == null) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(content: Text('리뷰가 등록되었습니다.')),
      );
    });
  }

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별점을 선택해 주세요.')),
      );
      return;
    }
    _finish(submitted: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final theme = _flowTheme(isDark);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          final pageBg = theme.scaffoldBackgroundColor;
          final buttonLabelColor = AppColors.studentInk;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _finish(submitted: false);
            },
            child: Scaffold(
            backgroundColor: pageBg,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(
                      '리뷰 작성',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: shell.titleColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _CompletionCheckRipple(),
                          const SizedBox(height: 16),
                          Text(
                            '수업이 완료되었습니다!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: shell.titleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '수업은 어떠셨나요?',
                            style: TextStyle(
                              fontSize: 15,
                              color: shell.subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                            decoration: BoxDecoration(
                              color: shell.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: shell.cardBorder),
                            ),
                            child: Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.args.tutorName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: shell.titleColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.args.tutorSubtitle,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: shell.subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _InteractiveStarRating(
                                  rating: _rating,
                                  onChanged: (value) => setState(() => _rating = value),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _ratingHint,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _rating == 0
                                        ? shell.hintColor
                                        : AppColors.reviewHighlight,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '리뷰를 작성해주세요',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: shell.titleColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: _reviewController,
                                  maxLength: _maxReviewLength,
                                  maxLines: 4,
                                  onChanged: (_) => setState(() {}),
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: shell.titleColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '수업에 대한 소감을 자유롭게 작성해주세요',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: shell.hintColor,
                                    ),
                                    filled: true,
                                    fillColor: shell.detailBackground,
                                    counterStyle: TextStyle(
                                      fontSize: 12,
                                      color: shell.hintColor,
                                    ),
                                    contentPadding: const EdgeInsets.all(14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: shell.cardBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: shell.cardBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.studentInk,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Column(
                            children: [
                              Text(
                                '수업 진행에 불편한 점이 있으셨나요?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: shell.subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  context.push(
                                    RoutePaths.studentReport,
                                    extra: StudentReportArgs(
                                      tutorId: widget.args.tutorId,
                                      tutorName: widget.args.tutorName,
                                    ),
                                  );
                                },
                                child: const Text(
                                  '신고하기',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.logoutRed,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.logoutRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        TextButton(
                          onPressed: () => _finish(submitted: false),
                          child: Text(
                            '건너뛰기',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: shell.subtitleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.studentPoint,
                              foregroundColor: buttonLabelColor,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              '제출하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}

class _CompletionCheckRipple extends StatefulWidget {
  const _CompletionCheckRipple();

  @override
  State<_CompletionCheckRipple> createState() => _CompletionCheckRippleState();
}

class _CompletionCheckRippleState extends State<_CompletionCheckRipple>
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
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CompletionRipplePainter(
              progress: _controller.value,
              color: AppColors.incomeGreen,
              ringCount: _ringCount,
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.incomeGreen.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 40,
                  color: AppColors.incomeGreen,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompletionRipplePainter extends CustomPainter {
  const _CompletionRipplePainter({
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
    final innerRadius = size.width * 0.30;
    final outerRadius = size.width * 0.48;

    for (var i = 0; i < ringCount; i++) {
      final phase = (progress + i / ringCount) % 1.0;
      final radius = innerRadius + (outerRadius - innerRadius) * phase;
      final opacity = (1 - phase).clamp(0.0, 1.0) * 0.45;

      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionRipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _InteractiveStarRating extends StatelessWidget {
  const _InteractiveStarRating({
    required this.rating,
    required this.onChanged,
  });

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            onPressed: () => onChanged(i),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            icon: Icon(
              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 32,
              color: i <= rating
                  ? AppColors.reviewHighlight
                  : ShellTheme.of(context).hintColor,
            ),
          ),
      ],
    );
  }
}
