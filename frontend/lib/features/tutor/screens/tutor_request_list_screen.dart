import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/tutor/data/tutor_request_list_dummy_data.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_accept_dialog.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_problem_image.dart';

enum _SortOrder { newest, oldest }

class TutorRequestListScreen extends StatefulWidget {
  const TutorRequestListScreen({super.key});

  @override
  State<TutorRequestListScreen> createState() => _TutorRequestListScreenState();
}

class _TutorRequestListScreenState extends State<TutorRequestListScreen> {
  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _labelColor = Color(0xFF1A1D26);
  static const _hintColor = Color(0xFF9AA3B2);
  static const _borderColor = Color(0xFFE0E0E0);
  static const _detailBoxColor = Color(0xFFF3F4F8);
  static const _subjectFilters = TutorRequestDummyData.subjectFilters;
  static const _sortOptions = ['최신순', '오래된 순'];
  static const _selectorTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

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

  double get _sortMenuWidth => _measureSelectorWidth(_sortOptions);

  Future<void> _openSortMenu(BuildContext anchorContext) async {
    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final offset = box.localToGlobal(Offset.zero);
    final menuWidth = _sortMenuWidth;
    final screenSize = MediaQuery.sizeOf(context);
    final left = (offset.dx + box.size.width - menuWidth)
        .clamp(8.0, screenSize.width - menuWidth - 8);

    final selected = await showMenu<_SortOrder>(
      context: context,
      color: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _borderColor),
      ),
      constraints: BoxConstraints.tightFor(width: menuWidth),
      position: RelativeRect.fromLTRB(
        left,
        offset.dy + box.size.height + 8,
        screenSize.width - left - menuWidth,
        screenSize.height - offset.dy - box.size.height - 8,
      ),
      items: [
        _buildSortMenuItem(
          label: _sortOptions[0],
          order: _SortOrder.newest,
        ),
        _buildSortMenuItem(
          label: _sortOptions[1],
          order: _SortOrder.oldest,
        ),
      ],
    );

    if (!mounted || selected == null || selected == _sortOrder) return;
    setState(() => _sortOrder = selected);
  }

  PopupMenuItem<_SortOrder> _buildSortMenuItem({
    required String label,
    required _SortOrder order,
  }) {
    final isSelected = _sortOrder == order;
    return PopupMenuItem<_SortOrder>(
      value: order,
      height: 46,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: _sortMenuWidth,
        child: ColoredBox(
          color: isSelected ? const Color(0xFFE8EEFF) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: _selectorTextStyle.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primaryBlue : _hintColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _measureSelectorWidth(List<String> options) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var maxText = 0.0;
    for (final option in options) {
      for (final weight in [FontWeight.w500, FontWeight.w600]) {
        painter.text = TextSpan(
          text: option,
          style: _selectorTextStyle.copyWith(fontWeight: weight),
        );
        painter.layout();
        maxText = math.max(maxText, painter.width);
      }
    }
    return math.max(maxText + 56, 120);
  }

  @override
  Widget build(BuildContext context) {
    final requests = _visibleRequests;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '문제 신청 리스트',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _labelColor,
                      ),
                    ),
                  ),
                  Builder(
                    builder: (anchorContext) => IconButton(
                      onPressed: () => _openSortMenu(anchorContext),
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: _labelColor,
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
                  final label = _subjectFilters[index];
                  return _buildSubjectChip(label);
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
                        style: const TextStyle(color: _hintColor, fontSize: 14),
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
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : const Color(0xFFE8E8E8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(TutorRequestListItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    _buildSubjectBadge(item),
                    const SizedBox(height: 8),
                    Text(
                      item.detailSubject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _labelColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.chapter.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.chapter,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _hintColor,
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
              color: _detailBoxColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('예상 수업 시간', '${item.classMinutes}분'),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '예상 금액',
                  _formatWon(item.priceWon),
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
          style: const TextStyle(fontSize: 13, color: _hintColor),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: valueBold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? _labelColor,
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
              foregroundColor: Colors.white,
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
              foregroundColor: _labelColor,
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: _borderColor, width: 1),
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

  Widget _buildSubjectBadge(TutorRequestListItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: item.subjectBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        item.subject,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: item.subjectColor,
        ),
      ),
    );
  }

  String _formatWon(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return '$buffer원';
  }
}
