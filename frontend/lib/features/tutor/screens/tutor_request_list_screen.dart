import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/utils/won_format_util.dart';
import 'package:ieum/core/widgets/shell_filter_chip.dart';
import 'package:ieum/core/widgets/shell_popup_menu.dart';
import 'package:ieum/features/tutor/data/tutor_request_list_dummy_data.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_accept_dialog.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_problem_image.dart';
import 'package:ieum/features/tutor/widgets/tutor_subject_badge.dart';

enum _SortOrder { newest, oldest }

class TutorRequestListScreen extends StatefulWidget {
  const TutorRequestListScreen({super.key});

  @override
  State<TutorRequestListScreen> createState() => _TutorRequestListScreenState();
}

class _TutorRequestListScreenState extends State<TutorRequestListScreen> {
  ShellTheme get _shell => ShellTheme.of(context);

  static const _subjectFilters = TutorRequestDummyData.subjectFilters;
  static const _sortOptionLabels = ['최신순', '오래된 순'];

  List<TutorRequestListItem> get _allRequests => TutorRequestDummyData.build();

  String _selectedFilter = '전체';
  _SortOrder _sortOrder = _SortOrder.newest;
  final Set<String> _rejectedRequestIds = {};

  void _rejectRequest(TutorRequestListItem item) {
    setState(() => _rejectedRequestIds.add(item.id));
  }

  Future<void> _showAcceptConfirmDialog(TutorRequestListItem item) async {
    final confirmed = await showTutorRequestAcceptDialog(context, item);
    if (!mounted || confirmed != true) return;
  }

  List<TutorRequestListItem> get _visibleRequests {
    final list = (_selectedFilter == '전체'
            ? List<TutorRequestListItem>.from(_allRequests)
            : _allRequests.where((r) => r.subject == _selectedFilter).toList())
        .where((r) => !_rejectedRequestIds.contains(r.id))
        .toList();

    list.sort(
      (a, b) => _sortOrder == _SortOrder.newest
          ? a.minutesAgo.compareTo(b.minutesAgo)
          : b.minutesAgo.compareTo(a.minutesAgo),
    );
    return list;
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
          isFirst: true,
          isLast: false,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
        buildShellPopupMenuItem(
          context: anchorContext,
          value: _SortOrder.oldest,
          label: _sortOptionLabels[1],
          menuWidth: menuWidth,
          isSelected: _sortOrder == _SortOrder.oldest,
          isFirst: false,
          isLast: true,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        ),
      ],
    );

    if (!mounted || selected == null || selected == _sortOrder) return;
    setState(() => _sortOrder = selected);
  }

  @override
  Widget build(BuildContext context) {
    final requests = _visibleRequests;

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
                itemBuilder: (context, index) {
                  return _buildSubjectChip(_subjectFilters[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: requests.isEmpty
                  ? Center(
                      child: Text(
                        _rejectedRequestIds.isNotEmpty &&
                                _selectedFilter == '전체'
                            ? '표시할 신청이 없습니다.'
                            : '해당 과목의 신청이 없습니다.',
                        style: TextStyle(color: _shell.hintColor, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      key: ValueKey(
                        '$_sortOrder-$_selectedFilter-${_rejectedRequestIds.length}',
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: requests.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildRequestCard(requests[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectChip(String label) {
    final selected = _selectedFilter == label;
    return ShellFilterChip(
      label: label,
      selected: selected,
      onTap: () => setState(() => _selectedFilter = label),
    );
  }

  Widget _buildRequestCard(TutorRequestListItem item) {
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
              TutorRequestProblemThumbnail(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TutorSubjectBadge(subject: item.subject),
                    const SizedBox(height: 8),
                    Text(
                      item.detailSubject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _shell.titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.chapter.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.chapter,
                        style: TextStyle(
                          fontSize: 13,
                          color: _shell.hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      item.timeAgo,
                      style: TextStyle(
                        fontSize: 11,
                        color: _shell.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _shell.detailBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('예상 수업 시간', '${item.classMinutes}분'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '예상 금액',
                  formatWon(item.priceWon),
                  valueColor: AppColors.primaryBlue,
                  valueBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildActionButtons(item),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: _shell.hintColor),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? _shell.titleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(TutorRequestListItem item) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () => _showAcceptConfirmDialog(item),
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
              '수락',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _rejectRequest(item),
            style: OutlinedButton.styleFrom(
              foregroundColor: _shell.titleColor,
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: _shell.borderColor, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '거절',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

}
