import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/features/student/screens/student_report_screen.dart';
import 'package:ieum/features/tutor/widgets/tutor_action_button_style.dart';

/// 강사가 강의 종료 후 보는 완료 화면. (강사는 별점 리뷰 없음 — 완료 안내 + 신고만)
class TutorLessonCompleteArgs {
  const TutorLessonCompleteArgs({required this.lessonId, this.studentId});
  final int lessonId;
  final int? studentId;
}

class TutorLessonCompleteScreen extends ConsumerWidget {
  const TutorLessonCompleteScreen({super.key, required this.args});

  final TutorLessonCompleteArgs args;

  Future<void> _openReport(BuildContext context) async {
    // 신고 제출 성공(true)이면 완료 화면에 안 머물고 바로 강사 홈으로.
    final reported = await context.push<bool>(
      RoutePaths.studentReport, // reporterType은 서버가 JWT(role=TUTOR)로 자동 판별
      extra: StudentReportArgs(
        lessonId: args.lessonId,
        personType: ReportPersonType.student,
        personId: (args.studentId ?? 0).toString(),
        personName: '학생',
      ),
    );
    if (reported == true && context.mounted) {
      context.go(RoutePaths.tutorHome);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 단독 라우트라 부모 shell 테마를 못 받으므로 직접 다크/라이트 테마로 감싼다.
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.primaryBlue),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : AppColors.tutorScaffoldLight,
    );
    return Theme(
      data: theme,
      child: Builder(builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              // 체크 아이콘 대신 마스코트 이미지(강사=보라 e).
              SizedBox(
                width: 120,
                height: 120,
                child: Image.asset(
                  'assets/images/review_tutor.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const SizedBox(width: 120, height: 120),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '수업이 완료되었습니다',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '수고하셨어요! 정산은 마이페이지에서 확인할 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              // 수업 중 문제가 있었다면 신고 (학생 리뷰 화면과 동일한 디자인)
              Text(
                '수업 진행에 불편한 점이 있으셨나요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _openReport(context),
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
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(RoutePaths.tutorHome),
                  // 통일 스타일: 테두리만 특징색 + 흰/다크 배경 + 검정/특징색 글씨.
                  style: tutorOutlinedButtonStyle(isDark, radius: 14,
                      minimumSize: const Size.fromHeight(52)),
                  child: const Text('홈으로',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      }),
    );
  }
}
