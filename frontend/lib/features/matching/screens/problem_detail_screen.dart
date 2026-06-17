import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/matching/models/searching_problem_model.dart';
import 'package:ieum/features/matching/providers/matching_provider.dart';
import 'package:ieum/features/tutor/providers/tutor_availability_provider.dart';

class ProblemDetailScreen extends ConsumerStatefulWidget {
  const ProblemDetailScreen({super.key, required this.problem});

  final SearchingProblemModel problem;

  @override
  ConsumerState<ProblemDetailScreen> createState() =>
      _ProblemDetailScreenState();
}

class _ProblemDetailScreenState extends ConsumerState<ProblemDetailScreen> {
  bool _isApplying = false;

  Future<void> _apply() async {
    setState(() => _isApplying = true);
    try {
      await ref
          .read(matchingProvider.notifier)
          .applyToLesson(widget.problem.problemId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신청이 완료되었습니다')),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신청에 실패했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final isOnline = ref.watch(tutorAvailabilityProvider);
    final problem = widget.problem;
    final canApply = isOnline && !problem.alreadyApplied && !_isApplying;

    return Scaffold(
      backgroundColor: shell.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: shell.scaffoldBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: shell.titleColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '문제 상세',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: shell.titleColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 문제 이미지
              _buildImageArea(problem, shell),
              const SizedBox(height: 20),

              // 요약
              if (problem.summary != null && problem.summary!.isNotEmpty) ...[
                Text(
                  problem.summary!,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: shell.titleColor,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 상세 정보
              _buildInfoCard(problem, shell),
              const SizedBox(height: 32),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: canApply ? _apply : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        disabledBackgroundColor:
                            AppColors.primaryBlue.withValues(alpha: 0.4),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isApplying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              problem.alreadyApplied ? '이미 신청됨' : '신청',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.pop(problem.problemId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: shell.titleColor,
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: shell.borderColor, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '거절',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea(SearchingProblemModel problem, dynamic shell) {
    if (problem.imageUrls.isEmpty) {
      return _imagePlaceholder(shell);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        problem.imageUrls.first,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imagePlaceholder(shell),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _imagePlaceholder(dynamic shell) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 40, color: shell.hintColor),
          const SizedBox(height: 8),
          Text(
            '문제 이미지 없음',
            style: TextStyle(fontSize: 14, color: shell.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(SearchingProblemModel problem, dynamic shell) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _infoRow('과목', problem.subjectLabel, shell),
          _infoRow('유형 (대)', problem.primaryType ?? '-', shell),
          _infoRow('유형 (소)', problem.secondaryType ?? '-', shell),
          _infoRow('난이도', problem.difficulty ?? '-', shell),
          _infoRow('시험 유형', problem.examType ?? '-', shell),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, dynamic shell) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: shell.hintColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: shell.titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
