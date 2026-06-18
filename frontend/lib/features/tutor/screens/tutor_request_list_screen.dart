import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/widgets/shell_filter_chip.dart';
import 'package:ieum/core/widgets/shell_popup_menu.dart';
import 'package:ieum/features/matching/models/tutor_application_model.dart';
import 'package:ieum/features/matching/providers/matching_provider.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_problem_image.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

enum _SortOrder { newest, oldest }

class TutorRequestListScreen extends ConsumerStatefulWidget {
  const TutorRequestListScreen({super.key});

  @override
  ConsumerState<TutorRequestListScreen> createState() =>
      _TutorRequestListScreenState();
}

class _TutorRequestListScreenState
    extends ConsumerState<TutorRequestListScreen> {
  ShellTheme get _shell => ShellTheme.of(context);

  static const _subjectFilters = ['전체', '국어', '수학', '영어', '사회', '과학'];
  static const _sortOptionLabels = ['최신순', '오래된 순'];

  String _selectedFilter = '전체';
  _SortOrder _sortOrder = _SortOrder.newest;

  List<TutorApplicationModel> _getVisible(List<TutorApplicationModel> all) {
    final filtered = _selectedFilter == '전체'
        ? List<TutorApplicationModel>.from(all)
        : all.where((a) => a.subjectLabel == _selectedFilter).toList();
    filtered.sort((a, b) => _sortOrder == _SortOrder.newest
        ? b.appliedAt.compareTo(a.appliedAt)
        : a.appliedAt.compareTo(b.appliedAt));
    return filtered;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }

  Future<void> _cancelApplication(TutorApplicationModel app) async {
    try {
      await ref
          .read(tutorApplicationsProvider.notifier)
          .cancelApplication(app.problemId);
      if (mounted) {
        ref.invalidate(matchingProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신청이 취소되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('취소 실패: $e')),
        );
      }
    }
  }

  double get _sortMenuWidth =>
      math.max(measureShellMenuLabelWidth(_sortOptionLabels), 120);

  Future<void> _openSortMenu(BuildContext anchorContext) async {
    final menuWidth = _sortMenuWidth;
    final selected = await showShellAnchorPopupMenu<_SortOrder>(
      context: context,
      anchorContext: anchorContext,
      menuWidth: menuWidth,
      items: [
        buildShellPopupMenuItem(
          context: anchorContext,
          value: _SortOrder.newest,
          label: _sortOptionLabels[0],
          menuWidth: menuWidth,
          isSelected: _sortOrder == _SortOrder.newest,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
        buildShellPopupMenuItem(
          context: anchorContext,
          value: _SortOrder.oldest,
          label: _sortOptionLabels[1],
          menuWidth: menuWidth,
          isSelected: _sortOrder == _SortOrder.oldest,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ],
    );

    if (!mounted || selected == null || selected == _sortOrder) return;
    setState(() => _sortOrder = selected);
  }

  @override
  Widget build(BuildContext context) {
    final appsState = ref.watch(tutorApplicationsProvider);

    return Scaffold(
      backgroundColor: _shell.scaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '문제 신청 리스트',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _shell.titleColor,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (anchorContext) => IconButton(
                      onPressed: () => _openSortMenu(anchorContext),
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _shell.titleColor,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _subjectFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    _buildSubjectChip(_subjectFilters[index]),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: appsState.applications.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '목록을 불러오지 못했습니다.',
                        style:
                            TextStyle(color: _shell.hintColor, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref
                            .read(tutorApplicationsProvider.notifier)
                            .refresh(),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
                data: (all) {
                  final visible = _getVisible(all);
                  if (visible.isEmpty) {
                    return Center(
                      child: Text(
                        _selectedFilter == '전체'
                            ? '신청한 문제가 없습니다.'
                            : '해당 과목의 신청이 없습니다.',
                        style:
                            TextStyle(color: _shell.hintColor, fontSize: 14),
                      ),
                    );
                  }
                  return ListView.separated(
                    key: ValueKey('$_sortOrder-$_selectedFilter'),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildRequestCard(visible[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChip(String label) {
    return ShellFilterChip(
      label: label,
      selected: _selectedFilter == label,
      onTap: () => setState(() => _selectedFilter = label),
    );
  }

  Widget _buildRequestCard(TutorApplicationModel app) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _shell.menuSheetBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TutorRequestProblemThumbnail(
                imageUrl: app.imageUrls.firstOrNull,
                title: app.primaryType,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TutorSubjectBadge(subject: app.subjectLabel),
                        const Spacer(),
                        Text(
                          app.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: app.status == 'ACCEPTED'
                                ? AppColors.primaryBlue
                                : _shell.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      app.primaryType ?? '-',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _shell.titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (app.secondaryType != null &&
                        app.secondaryType!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        app.secondaryType!,
                        style:
                            TextStyle(fontSize: 13, color: _shell.hintColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(app.appliedAt),
                      style:
                          TextStyle(fontSize: 11, color: _shell.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildActionButtons(app),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TutorApplicationModel app) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => context.push(
              '/problem-detail',
              extra: app.toSearchingProblem(),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.onPrimaryFill(
                Theme.of(context).brightness,
              ),
              elevation: 0,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '자세히',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: app.status == 'CONFIRMING'
              ? SizedBox(
                  height: 44,
                  child: Center(
                    child: Text(
                      '확인 대기 중',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                )
              : OutlinedButton(
                  onPressed: () => _cancelApplication(app),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _shell.titleColor,
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: _shell.borderColor, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '취소',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
        ),
      ],
    );
  }
}
