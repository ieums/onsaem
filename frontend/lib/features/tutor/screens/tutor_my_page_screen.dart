import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/widgets/shell_popup_menu.dart';
import 'package:ieum/core/utils/date_format_util.dart';
import 'package:ieum/features/tutor/providers/tutor_availability_provider.dart';

enum _ReviewSort { latest, oldest, ratingHigh, ratingLow }

class TutorMyPageScreen extends ConsumerStatefulWidget {
  const TutorMyPageScreen({super.key});

  @override
  ConsumerState<TutorMyPageScreen> createState() => _TutorMyPageScreenState();
}

class _TutorMyPageScreenState extends ConsumerState<TutorMyPageScreen> {
  ShellTheme get _shell => ShellTheme.of(context);

  static const _reviews = <({String student, double rating, String comment, String date})>[
    (
      student: '김00',
      rating: 5.0,
      comment: '개념-유형-실전 순서로 잡아주셔서 내신 대비가 훨씬 쉬워졌어요.',
      date: '2026.05.24 20:31:42',
    ),
    (
      student: '박00',
      rating: 4.5,
      comment: '헷갈리던 함수 단원을 빠르게 정리해 주셔서 도움 많이 됐어요.',
      date: '2026.05.20 19:04:16',
    ),
    (
      student: '이00',
      rating: 4.0,
      comment: '숙제 피드백이 빨라서 오답 복습 루틴 만들기 좋았습니다.',
      date: '2026.05.15 17:48:03',
    ),
    (
      student: '최00',
      rating: 5.0,
      comment: '시험 직전 핵심만 짚어주셔서 실전에서 시간 관리가 잘 됐어요.',
      date: '2026.05.09 22:12:58',
    ),
    (
      student: '정00',
      rating: 4.8,
      comment: '문제 풀이 속도가 빨라지고 오답 정리 방식도 잡혔어요.',
      date: '2026.05.04 18:27:11',
    ),
    (
      student: '한00',
      rating: 4.3,
      comment: '설명이 차분해서 어려운 단원도 부담 없이 따라갈 수 있었습니다.',
      date: '2026.05.01 21:36:29',
    ),
    (
      student: '윤00',
      rating: 4.9,
      comment: '질문을 많이 해도 친절하게 답해주셔서 자신감이 생겼어요.',
      date: '2026.04.26 16:09:54',
    ),
  ];

  _ReviewSort _reviewSort = _ReviewSort.latest;
  bool _pushNotifications = true;

  String _bankName = '국민은행';
  String _accountNumber = '123456-01-123456';
  String _accountHolder = '홍길동';

  static const _bankOptions = [
    '국민은행',
    '신한은행',
    '하나은행',
    '우리은행',
    'NH농협은행',
    '카카오뱅크',
    '토스뱅크',
    '케이뱅크',
    'IBK기업은행',
    '새마을금고',
    '신협',
    'SC제일은행',
    '수협은행',
    '우체국',
    '대구은행',
    '부산은행',
    '경남은행',
    '광주은행',
    '전북은행',
    '제주은행',
  ];

  static const _faqItems = <({String question, String answer})>[
    (
      question: '정산금은 언제 입금되나요?',
      answer:
          '수업 완료 후 영업일 기준 3~5일 이내에 등록하신 계좌로 입금됩니다. 주말·공휴일은 익영업일에 처리됩니다.',
    ),
    (
      question: '출금 신청은 어떻게 하나요?',
      answer:
          '정산 탭에서 출금 가능 금액을 확인한 뒤 「출금 신청」 버튼을 눌러 주세요. 최소 출금 금액과 1일 출금 횟수 제한이 적용될 수 있습니다.',
    ),
    (
      question: '수업료는 어떻게 정해지나요?',
      answer:
          '신청 유형·수업 시간에 따라 플랫폼 요금 기준이 적용됩니다. 수업 수락 전 예상 정산 금액을 확인할 수 있습니다.',
    ),
    (
      question: '학생 신청을 거절할 수 있나요?',
      answer:
          '가능합니다. 다만 잦은 거절은 매칭 우선순위에 영향을 줄 수 있으니 사유를 신중히 선택해 주세요.',
    ),
    (
      question: '프로필·계좌 정보는 어디서 수정하나요?',
      answer:
          '마이페이지의 「프로필 수정」에서 학력·과목을, 「정산 계좌 관리」에서 입금 계좌를 변경할 수 있습니다.',
    ),
    (
      question: '리뷰는 수정·삭제할 수 있나요?',
      answer:
          '학생이 작성한 리뷰는 강사가 직접 수정할 수 없습니다. 부적절한 리뷰는 고객센터로 신고해 주세요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final previewReviews = _sortedReviews().take(3).toList();

    return Scaffold(
      backgroundColor: _shell.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '마이페이지',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _shell.titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref
                        .read(shellDarkModeProvider.notifier)
                        .update((v) => !v),
                    icon: Icon(
                      ref.watch(shellDarkModeProvider)
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 24,
                    ),
                    color: Theme.of(context).colorScheme.secondary,
                    tooltip: ref.watch(shellDarkModeProvider)
                        ? '라이트 모드'
                        : '다크 모드',
                  ),
                  IconButton(
                    onPressed: () => context.go(RoutePaths.login),
                    icon: const Icon(Icons.logout_outlined, size: 24),
                    color: const Color(0xFFE53935),
                    tooltip: '로그아웃',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProfileSummary(),
              SizedBox(height: 14),
              _buildStatsSection(),
              SizedBox(height: 14),
              _buildRecentReviewsSection(previewReviews),
              SizedBox(height: 14),
              _buildGroupedMenuCard(
                children: [
                  _buildMenuRow(
                    icon: Icons.person_outline,
                    title: '프로필 수정',
                    onTap: () => context.push('${RoutePaths.signupTutor}?edit=true'),
                  ),
                  _buildMenuRow(
                    icon: Icons.account_balance_outlined,
                    title: '정산 계좌 관리',
                    onTap: _showSettlementAccountDialog,
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildSettingsCard(),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(RoutePaths.login),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFE53935),
                    side: BorderSide(color: AppColors.logoutRed),
                    minimumSize: Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '로그아웃',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _shell.titleColor,
          ),
        ),
        if (trailing != null) ...[Spacer(), trailing],
      ],
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _shell.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _shell.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: _shell.iconBackground,
            child: Icon(
              Icons.person,
              size: 42,
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '홍길동',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _shell.titleColor,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '수학교육학과 · 서울대학교',
                  style: TextStyle(
                    fontSize: 13,
                    color: _shell.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Color(0xFFF5A623)),
                    SizedBox(width: 3),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _shell.titleColor,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '(127)',
                      style: TextStyle(
                        fontSize: 12,
                        color: _shell.hintColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('활동 통계'),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatCard(value: '342', label: '총 수업')),
            SizedBox(width: 8),
            Expanded(child: _StatCard(value: '4.9', label: '평균 평점')),
            SizedBox(width: 8),
            Expanded(
              child: _StatCard(value: '385,000원', label: '이번 달 수입'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentReviewsSection(
    List<({String student, double rating, String comment, String date})> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          '최근 리뷰',
          trailing: TextButton(
            onPressed: _showReviewModal,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              '전체 보기',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _shell.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _shell.cardBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) Divider(height: 1, color: _shell.dividerColor),
                _buildReviewPreviewRow(items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPreviewRow(
    ({String student, double rating, String comment, String date}) review,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                review.student,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _shell.titleColor,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.star, size: 14, color: Color(0xFFF5A623)),
              Text(
                review.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _shell.titleColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            review.comment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: _shell.subtitleColor,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('설정'),
        SizedBox(height: 8),
        _buildGroupedMenuCard(
          children: [
            _buildSwitchRow(
              icon: Icons.school_outlined,
              title: '수업 가능 상태',
              value: ref.watch(tutorAvailabilityProvider),
              onChanged: (v) =>
                  ref.read(tutorAvailabilityProvider.notifier).toggle(v),
            ),
            _buildSwitchRow(
              icon: Icons.notifications_none_rounded,
              title: '푸시 알림',
              value: _pushNotifications,
              onChanged: (v) => setState(() => _pushNotifications = v),
            ),
            _buildMenuRow(
              icon: Icons.headset_mic_outlined,
              title: '고객센터',
              onTap: _showCustomerCenterSheet,
            ),
            _buildMenuRow(
              icon: Icons.help_outline_rounded,
              title: '자주 묻는 질문',
              onTap: _showFaqSheet,
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupedMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _shell.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _shell.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                _buildMenuIcon(icon),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _shell.titleColor,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _shell.chevronColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: _shell.dividerColor),
      ],
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              _buildMenuIcon(icon),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _shell.titleColor,
                  ),
                ),
              ),
              SwitchTheme(
                data: SwitchThemeData(
                  // ON/OFF 동일 크기. fill:1 — Icons.circle 기본은 링(테두리만).
                  thumbIcon: WidgetStateProperty.all(
                    Icon(
                      Icons.circle,
                      size: 20,
                      color: _shell.cardBackground,
                      fill: 1,
                    ),
                  ),
                  thumbColor: WidgetStateProperty.all(Colors.transparent),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AppColors.primaryBlue
                        : _shell.trackOffColor;
                  }),
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Transform.scale(
                  scale: 0.82,
                  alignment: Alignment.center,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: _shell.dividerColor),
      ],
    );
  }

  Widget _buildMenuIcon(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _shell.iconBackground,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primaryBlue, size: 18),
    );
  }

  List<({String student, double rating, String comment, String date})> _sortedReviews() {
    final list = List.of(_reviews);
    switch (_reviewSort) {
      case _ReviewSort.latest:
        list.sort(
          (a, b) => parseFlexibleDateTime(b.date)
              .compareTo(parseFlexibleDateTime(a.date)),
        );
        break;
      case _ReviewSort.oldest:
        list.sort(
          (a, b) => parseFlexibleDateTime(a.date)
              .compareTo(parseFlexibleDateTime(b.date)),
        );
        break;
      case _ReviewSort.ratingHigh:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _ReviewSort.ratingLow:
        list.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }
    return list;
  }

  String _reviewSortLabel(_ReviewSort sort) {
    switch (sort) {
      case _ReviewSort.latest:
        return '최신 순';
      case _ReviewSort.oldest:
        return '오래된 순';
      case _ReviewSort.ratingHigh:
        return '별점 높은 순';
      case _ReviewSort.ratingLow:
        return '별점 낮은 순';
    }
  }

  static const _reviewSortLabels = [
    '최신 순',
    '오래된 순',
    '별점 높은 순',
    '별점 낮은 순',
  ];

  double get _reviewSortMenuWidth => measureShellMenuLabelWidth(_reviewSortLabels);

  Future<void> _openReviewSortMenu(
    BuildContext anchorContext,
    VoidCallback onSortChanged,
  ) async {
    final menuWidth = _reviewSortMenuWidth;
    final selected = await showShellAnchorPopupMenu<_ReviewSort>(
      context: context,
      anchorContext: anchorContext,
      menuWidth: menuWidth,
      items: [
        buildShellPopupMenuItem(
          context: anchorContext,
          value: _ReviewSort.latest,
          label: _reviewSortLabels[0],
          menuWidth: menuWidth,
          isSelected: _reviewSort == _ReviewSort.latest,
          isFirst: true,
          isLast: false,
        ),
        buildShellPopupMenuItem(
          context: anchorContext,
          value: _ReviewSort.oldest,
          label: _reviewSortLabels[1],
          menuWidth: menuWidth,
          isSelected: _reviewSort == _ReviewSort.oldest,
        ),
        buildShellPopupMenuItem(
          context: anchorContext,
          value: _ReviewSort.ratingHigh,
          label: _reviewSortLabels[2],
          menuWidth: menuWidth,
          isSelected: _reviewSort == _ReviewSort.ratingHigh,
        ),
        buildShellPopupMenuItem(
          context: anchorContext,
          value: _ReviewSort.ratingLow,
          label: _reviewSortLabels[3],
          menuWidth: menuWidth,
          isSelected: _reviewSort == _ReviewSort.ratingLow,
          isFirst: false,
          isLast: true,
        ),
      ],
    );

    if (!mounted || selected == null || selected == _reviewSort) return;
    setState(() => _reviewSort = selected);
    onSortChanged();
  }

  void _showSettlementAccountDialog() {
    final accountController = TextEditingController(text: _accountNumber);
    final holderController = TextEditingController(text: _accountHolder);
    var selectedBank = _bankOptions.contains(_bankName) ? _bankName : _bankOptions.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        final width = MediaQuery.sizeOf(dialogContext).width * 0.92;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: scheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '정산 계좌 관리',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _shell.titleColor,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '입금받을 본인 명의 계좌만 등록할 수 있습니다.',
                        style: TextStyle(fontSize: 13, color: _shell.hintColor),
                      ),
                      SizedBox(height: 16),
                      _buildBankSelectField(
                        selectedBank: selectedBank,
                        onTap: () => _showBankPickerSheet(
                          dialogContext,
                          selectedBank: selectedBank,
                          onSelected: (bank) {
                            setDialogState(() => selectedBank = bank);
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildAccountField(label: '계좌번호', controller: accountController),
                      SizedBox(height: 10),
                      _buildAccountField(label: '예금주', controller: holderController),
                      SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size.fromHeight(44),
                                side: BorderSide(color: _shell.borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('취소'),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _bankName = selectedBank;
                                  _accountNumber = accountController.text.trim();
                                  _accountHolder = holderController.text.trim();
                                });
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('정산 계좌가 저장되었습니다.')),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: AppColors.onPrimaryFill(
                                  Theme.of(dialogContext).brightness,
                                ),
                                minimumSize: Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('저장'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      accountController.dispose();
      holderController.dispose();
    });
  }

  Widget _buildBankSelectField({
    required String selectedBank,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '은행',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _shell.subtitleColor,
          ),
        ),
        SizedBox(height: 6),
        Material(
          color: _shell.scaffoldBackground,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _shell.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedBank,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _shell.titleColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _shell.hintColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBankPickerSheet(
    BuildContext context, {
    required String selectedBank,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final bottom = MediaQuery.paddingOf(sheetContext).bottom;
        final maxH = MediaQuery.sizeOf(sheetContext).height * 0.55;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 14),
              Text(
                '은행 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _shell.titleColor,
                ),
              ),
              SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
                  itemCount: _bankOptions.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: _shell.dividerColor,
                  ),
                  itemBuilder: (_, index) {
                    final bank = _bankOptions[index];
                    final selected = bank == selectedBank;
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        bank,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryBlue
                              : _shell.titleColor,
                        ),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check_rounded,
                              color: AppColors.primaryBlue,
                            )
                          : null,
                      onTap: () {
                        onSelected(bank);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _shell.subtitleColor,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: _shell.scaffoldBackground,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _shell.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _shell.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primaryBlue),
            ),
          ),
        ),
      ],
    );
  }

  void _showCustomerCenterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final bottom = MediaQuery.paddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '고객센터',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _shell.titleColor,
                ),
              ),
              SizedBox(height: 6),
              Text(
                '이용 중 궁금한 점은 아래 방법으로 문의해 주세요.',
                style: TextStyle(fontSize: 13, color: _shell.hintColor),
              ),
              SizedBox(height: 16),
              _buildSupportTile(
                icon: Icons.access_time_rounded,
                title: '운영 시간',
                subtitle: '평일 10:00 ~ 18:00 (주말·공휴일 휴무)',
              ),
              _buildSupportTile(
                icon: Icons.phone_in_talk_outlined,
                title: '전화 문의',
                subtitle: '1588-0000',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('전화 연결은 준비 중입니다.')),
                ),
              ),
              _buildSupportTile(
                icon: Icons.mail_outline_rounded,
                title: '이메일 문의',
                subtitle: 'support@onsaem.com',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('메일 앱 연동은 준비 중입니다.')),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('1:1 문의는 준비 중입니다.')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.onPrimaryFill(
                      Theme.of(sheetContext).brightness,
                    ),
                    minimumSize: Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('1:1 문의하기'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Material(
        color: _shell.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _shell.titleColor,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: _shell.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded, color: _shell.chevronColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFaqSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final maxH = MediaQuery.sizeOf(sheetContext).height * 0.82;
        final bottom = MediaQuery.paddingOf(sheetContext).bottom;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 14),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '자주 묻는 질문',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _shell.titleColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _faqItems.length,
                    separatorBuilder: (_, _) => SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      final item = _faqItems[index];
                      return Theme(
                        data: Theme.of(sheetContext).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: AppColors.primaryBlue.withValues(alpha: 0.08),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _shell.scaffoldBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.symmetric(horizontal: 14),
                            childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                            title: Text(
                              item.question,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _shell.titleColor,
                              ),
                            ),
                            iconColor: AppColors.primaryBlue,
                            collapsedIconColor:
                                Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.answer,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _shell.subtitleColor,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final maxH = size.height * 0.62;
        final maxW = size.width * 0.92;
        final scheme = Theme.of(dialogContext).colorScheme;
        return Dialog(
          backgroundColor: scheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final reviews = _sortedReviews();
                return Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text(
                              '리뷰 관리',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _shell.titleColor,
                              ),
                            ),
                          ),
                          Spacer(),
                          Builder(
                            builder: (anchorContext) => IconButton(
                              onPressed: () => _openReviewSortMenu(
                                anchorContext,
                                () => setModalState(() {}),
                              ),
                              icon: Icon(
                                Icons.tune_rounded,
                                size: 26,
                                color: _shell.titleColor,
                              ),
                              tooltip: _reviewSortLabel(_reviewSort),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(Icons.close_rounded),
                            color: _shell.subtitleColor,
                            tooltip: '닫기',
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(height: 1, color: scheme.outline),
                      SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          itemCount: reviews.length,
                          separatorBuilder: (_, _) => SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final r = reviews[index];
                            return Container(
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _shell.scaffoldBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        r.student,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _shell.titleColor,
                                        ),
                                      ),
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: const Color(0xFFF5A623),
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        r.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _shell.titleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    r.comment,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: scheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    r.date,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
