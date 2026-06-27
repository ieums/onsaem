import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/screens/student_problem_edit_screen.dart';
import 'package:ieum/features/student/utils/problem_enum_labels.dart';
import 'package:ieum/features/student/widgets/student_problem_chips.dart';
import 'package:ieum/features/student/widgets/student_problem_image_viewer.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';
import 'package:ieum/features/student/screens/student_ai_tutor_screen.dart';

/// 문제 상세 화면. 등록한 문제의 이미지·요약·분류를 보여주고, 분류 수정으로 진입.
class StudentProblemDetailScreen extends ConsumerWidget {
  const StudentProblemDetailScreen({super.key, required this.problem});

  final StudentProblemModel problem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        builder: (context) {
          final shell = ShellTheme.of(context);
          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '문제 상세',
              onBack: () => Navigator.of(context).pop(),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (problem.imageUrls.isNotEmpty)
                    _ImagePager(shell: shell, urls: problem.imageUrls),
                  if (problem.imageUrls.isNotEmpty) const SizedBox(height: 16),
                  Row(
                    children: [
                      ProblemSubjectChip(subject: problem.subject),
                      const SizedBox(width: 8),
                      ProblemStatusChip(status: problem.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (problem.summary?.trim().isNotEmpty ?? false)
                        ? problem.summary!.trim()
                        : '문제 요약 없음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: shell.titleColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoCard(
                    shell: shell,
                    rows: [
                      ('과목', subjectLabel(problem.subject)),
                      ('난이도', difficultyLabel(problem.difficulty)),
                      ('출처', examTypeLabel(problem.examType)),
                      ('대분류', _orDash(problem.primaryType)),
                      ('소분류', _orDash(problem.secondaryType)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final changed =
                            await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentProblemEditScreen(problem: problem),
                          ),
                        );
                        if (changed == true) {
                          ref.invalidate(studentProblemsProvider);
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text(
                        '분류 수정',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.studentInk,
                        side: BorderSide(
                          color: AppColors.studentInk.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                
                                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentAiTutorScreen(
                              problemId: problem.problemId,
                              problemSummary: problem.summary,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.smart_toy_rounded, size: 20),
                      label: const Text(
                        'AI 튜터에게 질문하기',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.studentInk,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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

  static String _orDash(String? s) =>
      (s != null && s.trim().isNotEmpty) ? s.trim() : '-';
}

/// 이미지가 여러 장이면 좌우로 넘겨보는 페이저(점 인디케이터 + 페이지 카운터).
class _ImagePager extends StatefulWidget {
  const _ImagePager({required this.shell, required this.urls});
  final ShellTheme shell;
  final List<String> urls;

  @override
  State<_ImagePager> createState() => _ImagePagerState();
}

class _ImagePagerState extends State<_ImagePager> {
  final _controller = PageController();
  int _page = 0;

  static const double _height = 220;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.length == 1) {
      return SizedBox(height: _height, child: _image(context, urls.first, 0));
    }
    return Column(
      children: [
        SizedBox(
          height: _height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _image(context, urls[i], i),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_page + 1}/${urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < urls.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? AppColors.studentInk
                      : widget.shell.cardBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _image(BuildContext context, String url, int index) {
    final resolved = ApiConstants.resolveImageUrl(url);
    return GestureDetector(
      onTap: () => showStudentProblemImageGalleryUrls(
        context,
        imageUrls: [
          for (final u in widget.urls) ApiConstants.resolveImageUrl(u),
        ],
        initialIndex: index,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: widget.shell.detailBackground,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: widget.shell.hintColor),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.shell, required this.rows});
  final ShellTheme shell;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: shell.cardBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(
                      r.$1,
                      style: TextStyle(fontSize: 13.5, color: shell.hintColor),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: shell.titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
