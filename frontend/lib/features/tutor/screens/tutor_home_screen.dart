import 'package:flutter/material.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/features/tutor/data/tutor_request_list_dummy_data.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_accept_dialog.dart';
import 'package:ieum/features/tutor/widgets/tutor_request_problem_image.dart';

class TutorHomeScreen extends StatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  State<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends State<TutorHomeScreen> {
  static const _backgroundColor = Color(0xFFF8F9FD);
  static const _labelColor = Color(0xFF1A1D26);
  static const _hintColor = Color(0xFF9AA3B2);
  static const _borderColor = Color(0xFFE0E0E0);
  static const _offlineButtonColor = Color(0xFFD8D8D8);
  static const _offlineButtonTextColor = Color(0xFF7C7C7C);
  bool _isOnline = true;
  int _questionPageIndex = 0;
  final Set<String> _rejectedQuestionIds = {};

  List<TutorRequestListItem> get _allRecentQuestions =>
      TutorRequestDummyData.recentQuestions();

  List<TutorRequestListItem> get _visibleRecentQuestions {
    return _allRecentQuestions
        .where((q) => !_rejectedQuestionIds.contains(q.id))
        .toList();
  }

  void _rejectQuestion(TutorRequestListItem item) {
    setState(() {
      _rejectedQuestionIds.add(item.id);
      final pageCount = _questionPageCount;
      if (pageCount == 0) {
        _questionPageIndex = 0;
      } else if (_questionPageIndex >= pageCount) {
        _questionPageIndex = pageCount - 1;
      }
    });
  }

  int get _questionPageCount {
    final count = _visibleRecentQuestions.length;
    if (count == 0) return 0;
    return (count / TutorRequestDummyData.newQuestionPageSize).ceil();
  }

  List<TutorRequestListItem> get _pagedQuestions {
    final items = _visibleRecentQuestions;
    if (items.isEmpty) return [];

    final pageCount = _questionPageCount;
    final safeIndex =
        pageCount == 0 ? 0 : _questionPageIndex.clamp(0, pageCount - 1);
    final start = safeIndex * TutorRequestDummyData.newQuestionPageSize;
    final end = (start + TutorRequestDummyData.newQuestionPageSize)
        .clamp(0, items.length);
    return items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '강사 홈',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _labelColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildOnlineStatusCard(),
              const SizedBox(height: 24),
              _buildQuestionListHeader(),
              const SizedBox(height: 12),
              if (_visibleRecentQuestions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      _rejectedQuestionIds.isNotEmpty
                          ? '표시할 새 질문이 없습니다.'
                          : '5분 이내 새 질문이 없습니다.',
                      style: const TextStyle(color: _hintColor, fontSize: 14),
                    ),
                  ),
                )
              else ...[
                for (final question in _pagedQuestions) ...[
                  _buildQuestionCard(question),
                  const SizedBox(height: 12),
                ],
                _buildQuestionPagination(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '온라인 상태',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _labelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isOnline ? '질문을 기다리고 있어요' : '오프라인 상태입니다',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              SwitchTheme(
                data: SwitchThemeData(
                  thumbIcon: WidgetStateProperty.all(
                    const Icon(
                      Icons.circle,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  thumbColor: WidgetStateProperty.all(Colors.transparent),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? const Color(0xFF4CD964)
                        : const Color(0xFFD8D8D8);
                  }),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Switch(
                  value: _isOnline,
                  onChanged: (value) => setState(() => _isOnline = value),
                ),
              ),
            ],
          ),
          if (_isOnline) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CD964),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '접속 중',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CD964),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionListHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            '새로운 질문 리스트',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _labelColor,
            ),
          ),
        ),
        Text(
          '${_visibleRecentQuestions.length}개',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionPagination() {
    final pageCount = _questionPageCount;
    if (pageCount <= 1) return const SizedBox.shrink();

    final canGoPrev = _questionPageIndex > 0;
    final canGoNext = _questionPageIndex < pageCount - 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canGoPrev
                ? () => setState(() => _questionPageIndex -= 1)
                : null,
            icon: Icon(
              Icons.chevron_left,
              size: 22,
              color: canGoPrev ? _labelColor : _hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '${_questionPageIndex + 1} / $pageCount',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _labelColor,
            ),
          ),
          IconButton(
            onPressed: canGoNext
                ? () => setState(() => _questionPageIndex += 1)
                : null,
            icon: Icon(
              Icons.chevron_right,
              size: 22,
              color: canGoNext ? _labelColor : _hintColor,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(TutorRequestListItem question) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TutorRequestProblemThumbnail(item: question),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubjectBadge(question),
                    const SizedBox(height: 8),
                    Text(
                      question.detailSubject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _labelColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (question.chapter.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        question.chapter,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      question.timeAgo,
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
          const SizedBox(height: 14),
          _buildActionButtons(question),
        ],
      ),
    );
  }

  Future<void> _showAcceptConfirmDialog(TutorRequestListItem item) async {
    final confirmed = await showTutorRequestAcceptDialog(context, item);
    if (!mounted || confirmed != true) return;
    // TODO: 모달 수락 후 이동 화면 (추후 디자인)
  }

  Widget _buildActionButtons(TutorRequestListItem question) {
    final acceptBg = _isOnline ? AppColors.primaryBlue : _offlineButtonColor;
    final acceptFg = _isOnline ? Colors.white : _offlineButtonTextColor;
    final rejectBorder = _isOnline ? _borderColor : _offlineButtonColor;
    final rejectFg = _isOnline ? _labelColor : _offlineButtonTextColor;

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: _isOnline ? () => _showAcceptConfirmDialog(question) : null,
            style: FilledButton.styleFrom(
              backgroundColor: acceptBg,
              foregroundColor: acceptFg,
              elevation: 0,
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '수락',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: _isOnline ? () => _rejectQuestion(question) : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: rejectFg,
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: rejectBorder, width: 1),
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
    );
  }

  Widget _buildSubjectBadge(TutorRequestListItem question) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: question.subjectBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        question.subject,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: question.subjectColor,
        ),
      ),
    );
  }
}
