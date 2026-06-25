import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/storage/token_storage.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/auth/screens/password_reset_screen.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';
import 'package:ieum/features/tutor/providers/settlement_provider.dart';
import 'package:ieum/features/tutor/providers/tutor_availability_provider.dart';

class TutorMyPageScreen extends ConsumerStatefulWidget {
  const TutorMyPageScreen({super.key});

  @override
  ConsumerState<TutorMyPageScreen> createState() =>
      _TutorMyPageScreenState();
}

class _TutorMyPageScreenState
    extends ConsumerState<TutorMyPageScreen> {
  ShellTheme get _shell => ShellTheme.of(context);

  bool _pushNotifications = true;

  String _bankName = '';
  String _accountNumber = '';
  String _accountHolder = '';

  static const _bankOptions = [
    '국민은행', '신한은행', '하나은행', '우리은행', 'NH농협은행',
    '카카오뱅크', '토스뱅크', '케이뱅크', 'IBK기업은행', '새마을금고',
    '신협', 'SC제일은행', '수협은행', '우체국', '대구은행',
    '부산은행', '경남은행', '광주은행', '전북은행', '제주은행',
  ];

  static const _faqItems = <({String question, String answer})>[
    (
      question: '정산금은 언제 입금되나요?',
      answer: '수업 완료 후 영업일 기준 3~5일 이내에 등록하신 계좌로 입금됩니다. 주말·공휴일은 익영업일에 처리됩니다.',
    ),
    (
      question: '출금 신청은 어떻게 하나요?',
      answer: '정산 탭에서 출금 가능 금액을 확인한 뒤 「출금 신청」 버튼을 눌러 주세요. 최소 출금 금액과 1일 출금 횟수 제한이 적용될 수 있습니다.',
    ),
    (
      question: '수업료는 어떻게 정해지나요?',
      answer: '신청 유형·수업 시간에 따라 플랫폼 요금 기준이 적용됩니다. 수업 수락 전 예상 정산 금액을 확인할 수 있습니다.',
    ),
    (
      question: '학생 신청을 거절할 수 있나요?',
      answer: '가능합니다. 다만 잦은 거절은 매칭 우선순위에 영향을 줄 수 있으니 사유를 신중히 선택해 주세요.',
    ),
    (
      question: '프로필·계좌 정보는 어디서 수정하나요?',
      answer: '마이페이지의 「프로필 수정」에서 학력·과목을, 「정산 계좌 관리」에서 입금 계좌를 변경할 수 있습니다.',
    ),
    (
      question: '리뷰는 수정·삭제할 수 있나요?',
      answer: '학생이 작성한 리뷰는 강사가 직접 수정할 수 없습니다. 부적절한 리뷰는 고객센터로 신고해 주세요.',
    ),
  ];

  static const _supportEmail = 'ieum.team@gmail.com';

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final meData = me.valueOrNull;

    // meProvider 로드 완료 시 availability 동기화
    ref.listen(meProvider, (_, next) {
      if (next.hasValue) {
        final available = next.value?['isAvailable'] as bool? ?? true;
        ref.read(tutorAvailabilityProvider.notifier).syncFromApi(available);
      }
    });

    return Scaffold(
      backgroundColor: _shell.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProfileCard(meData),
              const SizedBox(height: 14),
              _buildStatsRow(meData),
              const SizedBox(height: 14),
              _buildSectionTitle('내 활동'),
              const SizedBox(height: 8),
              _buildGroupedMenuCard(children: [
                _buildMenuRow(
                  icon: Icons.star_outline_rounded,
                  title: '받은 리뷰',
                  onTap: () => context.push(RoutePaths.tutorMyReviews),
                ),
                _buildMenuRow(
                  icon: Icons.flag_outlined,
                  title: '신고 내역',
                  onTap: () => context.push(RoutePaths.tutorMyReports),
                ),
                _buildMenuRow(
                  icon: Icons.account_balance_outlined,
                  title: '정산 계좌 관리',
                  onTap: _showSettlementAccountDialog,
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 14),
              _buildSectionTitle('계정'),
              const SizedBox(height: 8),
              _buildGroupedMenuCard(children: [
                if ((meData?['provider'] as String?) == 'LOCAL')
                  _buildMenuRow(
                    icon: Icons.lock_outline_rounded,
                    title: '비밀번호 변경',
                    onTap: () => context.push(
                      RoutePaths.passwordReset,
                      extra: PasswordResetArgs(
                          email: meData?['email'] as String?,
                          isTutor: true),
                    ),
                  ),
                _buildMenuRow(
                  icon: Icons.school_outlined,
                  title: '학력 관리',
                  onTap: () async {
                    await context.push(RoutePaths.tutorAcademicEdit);
                    ref.invalidate(meProvider);
                  },
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 14),
              _buildSettingsCard(meData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
          onPressed: () =>
              ref.read(shellDarkModeProvider.notifier).update((v) => !v),
          icon: Icon(
            ref.watch(shellDarkModeProvider)
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            size: 24,
          ),
          color: Theme.of(context).colorScheme.secondary,
          tooltip: ref.watch(shellDarkModeProvider) ? '라이트 모드' : '다크 모드',
        ),
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout_outlined, size: 24),
          color: AppColors.logoutRed,
          tooltip: '로그아웃',
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await tokenStorage.clear();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) context.go(RoutePaths.login);
  }

  Widget _buildProfileCard(Map<String, dynamic>? me) {
    final name = (me?['name'] as String?)?.trim();
    final email = (me?['email'] as String?)?.trim();
    final imageUrl = (me?['profileImageUrl'] as String?)?.trim();
    final school = (me?['school'] as String?)?.trim();
    final major = (me?['major'] as String?)?.trim();
    final resolved = (imageUrl != null && imageUrl.isNotEmpty)
        ? ApiConstants.resolveImageUrl(imageUrl)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
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
            backgroundColor:
                AppColors.primaryBlue.withValues(alpha: 0.15),
            backgroundImage:
                resolved != null ? NetworkImage(resolved) : null,
            child: resolved == null
                ? const Icon(Icons.person,
                    size: 42, color: AppColors.primaryBlue)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '…',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _shell.titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email ?? '…',
                  style: TextStyle(
                    fontSize: 13,
                    color: _shell.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (school != null || major != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [?major, ?school]
                        .join(' · '),
                    style: TextStyle(
                      fontSize: 13,
                      color: _shell.hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined,
                size: 20, color: _shell.chevronColor),
            onPressed: () async {
              await context.push(RoutePaths.tutorProfileEdit);
              ref.invalidate(meProvider);
            },
            tooltip: '프로필 수정',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic>? me) {
    final lessonCount = me?['lessonCount'] as int?;
    final ratingAvg = me?['ratingAvg'];
    final ratingStr = ratingAvg == null
        ? '…'
        : double.tryParse('$ratingAvg')?.toStringAsFixed(1) ?? '…';

    final settlement = ref.watch(settlementDataProvider);
    final incomeStr = settlement.when(
      loading: () => '…',
      error: (_, _) => '-',
      data: (data) {
        final now = DateTime.now();
        final thisMonthIncome = data.transactions
            .where((t) =>
                t.date.year == now.year &&
                t.date.month == now.month &&
                t.amount > 0)
            .fold(0, (sum, t) => sum + t.amount);
        return _fmtKrw(thisMonthIncome);
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('활동 통계'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: lessonCount == null ? '…' : '$lessonCount',
                    label: '총 수업')),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(value: ratingStr, label: '평균 평점')),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(value: incomeStr, label: '이번달 수입')),
          ],
        ),
      ],
    );
  }

  static String _fmtKrw(int amount) {
    if (amount == 0) return '0원';
    final s = amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$s원';
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
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _buildSettingsCard(Map<String, dynamic>? me) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('설정'),
        const SizedBox(height: 8),
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
              onChanged: (v) =>
                  setState(() => _pushNotifications = v),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                _buildMenuIcon(icon),
                const SizedBox(width: 10),
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
                  Icon(Icons.chevron_right_rounded,
                      color: _shell.chevronColor, size: 22),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              _buildMenuIcon(icon),
              const SizedBox(width: 10),
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
                  thumbIcon: WidgetStateProperty.all(
                    Icon(Icons.circle,
                        size: 20,
                        color: _shell.cardBackground,
                        fill: 1),
                  ),
                  thumbColor:
                      WidgetStateProperty.all(Colors.transparent),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AppColors.primaryBlue
                        : _shell.trackOffColor;
                  }),
                  trackOutlineColor:
                      WidgetStateProperty.all(Colors.transparent),
                  overlayColor:
                      WidgetStateProperty.all(Colors.transparent),
                ),
                child: Transform.scale(
                  scale: 0.82,
                  alignment: Alignment.center,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
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

  void _showSettlementAccountDialog() {
    final accountController =
        TextEditingController(text: _accountNumber);
    final holderController =
        TextEditingController(text: _accountHolder);
    var selectedBank = _bankOptions.contains(_bankName)
        ? _bankName
        : _bankOptions.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        final width = MediaQuery.sizeOf(dialogContext).width * 0.92;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: scheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      Text('정산 계좌 관리',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _shell.titleColor)),
                      const SizedBox(height: 6),
                      Text('입금받을 본인 명의 계좌만 등록할 수 있습니다.',
                          style: TextStyle(
                              fontSize: 13,
                              color: _shell.hintColor)),
                      const SizedBox(height: 16),
                      _buildBankSelectField(
                        selectedBank: selectedBank,
                        onTap: () => _showBankPickerSheet(
                          dialogContext,
                          selectedBank: selectedBank,
                          onSelected: (bank) => setDialogState(
                              () => selectedBank = bank),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildAccountField(
                          label: '계좌번호',
                          controller: accountController),
                      const SizedBox(height: 10),
                      _buildAccountField(
                          label: '예금주',
                          controller: holderController),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext)
                                      .pop(),
                              style: OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size.fromHeight(44),
                                side: BorderSide(
                                    color: _shell.borderColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: const Text('취소'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _bankName = selectedBank;
                                  _accountNumber =
                                      accountController.text
                                          .trim();
                                  _accountHolder =
                                      holderController.text
                                          .trim();
                                });
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content:
                                            Text('정산 계좌가 저장되었습니다.')));
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                minimumSize:
                                    const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              child: const Text('저장'),
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
        Text('은행',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _shell.subtitleColor)),
        const SizedBox(height: 6),
        Material(
          color: _shell.scaffoldBackground,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: _shell.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(selectedBank,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _shell.titleColor)),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: _shell.hintColor),
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
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme =
            Theme.of(sheetContext).colorScheme;
        final bottom =
            MediaQuery.paddingOf(sheetContext).bottom;
        final maxH =
            MediaQuery.sizeOf(sheetContext).height * 0.55;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text('은행 선택',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _shell.titleColor)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                      12, 0, 12, 12 + bottom),
                  itemCount: _bankOptions.length,
                  separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: _shell.dividerColor),
                  itemBuilder: (_, index) {
                    final bank = _bankOptions[index];
                    final selected = bank == selectedBank;
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 8),
                      title: Text(bank,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? AppColors.primaryBlue
                                  : _shell.titleColor)),
                      trailing: selected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.primaryBlue)
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
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _shell.subtitleColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: _shell.scaffoldBackground,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: _shell.borderColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: _shell.borderColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primaryBlue)),
          ),
        ),
      ],
    );
  }

  void _showCustomerCenterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme =
            Theme.of(sheetContext).colorScheme;
        final bottom =
            MediaQuery.paddingOf(sheetContext).bottom;
        bool copied = false;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            void copyEmail() {
              Clipboard.setData(
                  const ClipboardData(text: _supportEmail));
              setSheetState(() => copied = true);
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outline,
                        borderRadius:
                            BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('고객센터',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _shell.titleColor)),
                  const SizedBox(height: 6),
                  Text('이용 중 궁금한 점은 아래 방법으로 문의해 주세요.',
                      style: TextStyle(
                          fontSize: 13,
                          color: _shell.hintColor)),
                  const SizedBox(height: 16),
                  _buildSupportTile(
                    icon: Icons.access_time_rounded,
                    title: '운영 시간',
                    subtitle: '평일 10:00 ~ 18:00 (주말·공휴일 휴무)',
                  ),
                  _buildSupportTile(
                    icon: Icons.mail_outline_rounded,
                    title: '이메일 문의',
                    subtitle: _supportEmail,
                    onTap: copyEmail,
                    trailing: copied
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  Icons
                                      .check_circle_rounded,
                                  size: 18,
                                  color: Color(0xFF2E9E6B)),
                              SizedBox(width: 4),
                              Text('복사됨',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: Color(
                                          0xFF2E9E6B))),
                            ],
                          )
                        : Icon(Icons.copy_rounded,
                            size: 18,
                            color: _shell.chevronColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '1:1 문의는 위 이메일로 보내주세요. 보통 1영업일 내 답변드려요.',
                      style: TextStyle(
                          fontSize: 12,
                          color: _shell.hintColor)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: copyEmail,
                      icon: const Icon(
                          Icons.content_copy_rounded,
                          size: 18),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize:
                            const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      label: Text(copied
                          ? '이메일이 복사됐어요'
                          : '문의 이메일 복사하기'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _shell.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _shell.titleColor)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13,
                              color: _shell.hintColor)),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  Icon(Icons.chevron_right_rounded,
                      color: _shell.chevronColor),
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
      backgroundColor:
          Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme =
            Theme.of(sheetContext).colorScheme;
        final maxH =
            MediaQuery.sizeOf(sheetContext).height * 0.82;
        final bottom =
            MediaQuery.paddingOf(sheetContext).bottom;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                12, 12, 12, 12 + bottom),
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
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('자주 묻는 질문',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _shell.titleColor)),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _faqItems.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      final item = _faqItems[index];
                      return Theme(
                        data: Theme.of(sheetContext).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: AppColors.primaryBlue
                              .withValues(alpha: 0.08),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _shell.scaffoldBackground,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            tilePadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(
                                    14, 0, 14, 14),
                            title: Text(item.question,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w700,
                                    color:
                                        _shell.titleColor)),
                            iconColor: AppColors.primaryBlue,
                            collapsedIconColor:
                                Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurfaceVariant,
                            children: [
                              Align(
                                alignment:
                                    Alignment.centerLeft,
                                child: Text(item.answer,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: _shell
                                            .subtitleColor,
                                        height: 1.45)),
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.outline),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
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
