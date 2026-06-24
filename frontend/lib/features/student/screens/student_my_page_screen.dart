import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/notifications/app_notification_service.dart';
import 'package:ieum/core/providers/current_user_provider.dart';
import 'package:ieum/core/storage/token_storage.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/auth/screens/password_reset_screen.dart';
import 'package:ieum/features/student/models/payment_models.dart';
import 'package:ieum/features/student/providers/mypage_provider.dart';
import 'package:ieum/features/student/providers/payment_provider.dart';
import 'package:ieum/features/student/providers/student_notification_provider.dart';
import 'package:ieum/features/student/providers/student_wallet_provider.dart';

class StudentMyPageScreen extends ConsumerStatefulWidget {
  const StudentMyPageScreen({super.key});

  @override
  ConsumerState<StudentMyPageScreen> createState() => _StudentMyPageScreenState();
}

class _StudentMyPageScreenState extends ConsumerState<StudentMyPageScreen> {
  ShellTheme get _shell => ShellTheme.of(context);

  Color get _pageBackground =>
      Theme.of(context).brightness == Brightness.dark
          ? _shell.scaffoldBackground
          : Colors.white;

  static const _faqItems = <({String question, String answer})>[
    (
      question: '크레딧은 어떻게 충전하나요?',
      answer:
          '마이페이지 상단의 「충전하기」를 눌러 원하는 금액을 선택해 신용·체크카드로 결제하면 즉시 반영됩니다.',
    ),
    (
      question: '질문은 어떻게 등록하나요?',
      answer:
          '홈에서 문제 사진을 올리면 AI가 과목을 자동으로 분류해 드려요. 등록한 질문은 마이페이지 「내 질문」에서 확인·수정할 수 있습니다.',
    ),
    (
      question: 'AI 튜터는 무료인가요?',
      answer:
          '아니요, AI 튜터는 구독 후 이용할 수 있어요. 구독 중에는 추가 크레딧 없이 AI 튜터에게 자유롭게 질문할 수 있습니다. 구독은 마이페이지 「구독 관리」에서 시작할 수 있어요.',
    ),
    (
      question: '구독은 어떻게 하나요?',
      answer:
          '마이페이지 「구독 관리」에서 플랜을 선택해 결제하면 구독이 시작됩니다. 현재 구독 상태와 남은 기간, 자동 갱신 설정도 거기서 확인·변경할 수 있어요.',
    ),
    (
      question: '환불·구독 해지는 어떻게 하나요?',
      answer:
          '충전한 크레딧은 사용 전이라면 결제 내역에서 환불을 요청할 수 있어요. 구독은 「구독 관리」에서 해지하면 자동 갱신이 중단되고, 남은 기간 동안은 계속 이용할 수 있습니다.',
    ),
    (
      question: '프로필은 어디서 수정하나요?',
      answer:
          '마이페이지 상단 프로필 카드의 수정(✎) 버튼을 누르면 이름·휴대폰 번호·생년월일·프로필 사진을 변경할 수 있습니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _pageBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildProfileSummary(),
              const SizedBox(height: 14),
              _buildCreditCard(),
              const SizedBox(height: 14),
              _buildSubscriptionCard(),
              const SizedBox(height: 14),
              _buildStatsSection(),
              const SizedBox(height: 18),
              _buildSectionTitle('내 활동'),
              const SizedBox(height: 10),
              _buildGroupedMenuCard(
                children: [
                  _buildMenuRow(
                    icon: Icons.assignment_outlined,
                    title: '내 질문',
                    onTap: () => context.push(RoutePaths.studentProblemList),
                  ),
                  _buildMenuRow(
                    icon: Icons.rate_review_outlined,
                    title: '내 리뷰 내역',
                    onTap: () => context.push(RoutePaths.studentMyReviews),
                  ),
                  _buildMenuRow(
                    icon: Icons.flag_outlined,
                    title: '내 신고 내역',
                    onTap: () => context.push(RoutePaths.studentMyReports),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingsCard(),
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

  /// 로그아웃: 저장된 토큰을 비우고 세션을 초기화한 뒤 로그인 화면으로.
  Future<void> _logout() async {
    await tokenStorage.clear();
    ref.read(currentUserProvider.notifier).state = null;
    if (mounted) context.go(RoutePaths.login);
  }

  Widget _buildProfileSummary() {
    final me = ref.watch(meProvider).valueOrNull;
    final name = (me?['name'] as String?)?.trim();
    final email = (me?['email'] as String?)?.trim();
    final imageUrl = (me?['profileImageUrl'] as String?)?.trim();

    return Material(
      color: _pageBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openProfileEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _shell.cardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor:
                    AppColors.roleStudentBorder.withValues(alpha: 0.35),
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? NetworkImage(ApiConstants.resolveImageUrl(imageUrl))
                    : null,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(Icons.person,
                        size: 42, color: AppColors.studentInk)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (name == null || name.isEmpty) ? '온샘 학생' : name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _shell.titleColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (email == null || email.isEmpty) ? '-' : email,
                      style: TextStyle(
                        fontSize: 13,
                        color: _shell.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, size: 20, color: _shell.chevronColor),
            ],
          ),
        ),
      ),
    );
  }

  /// 프로필 수정 화면으로 이동 후 돌아오면 카드를 새로고침.
  Future<void> _openProfileEdit() async {
    await context.push(RoutePaths.studentProfileEdit);
    ref.invalidate(meProvider);
  }

  Widget _buildCreditCard() {
    final balance =
        ref.watch(coinBalanceProvider).valueOrNull?.availableBalance;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '보유 크레딧',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _shell.hintColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(RoutePaths.studentCreditRecharge),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.studentInk,
                ),
                child: const Text(
                  '충전하기',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${balance == null ? '…' : formatCredits(balance)} P',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.studentInk,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final async = ref.watch(mySubscriptionProvider);
    final sub = async.valueOrNull;
    final loading = async.isLoading;
    final hasActive = sub != null && sub.valid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _shell.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '구독',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _shell.hintColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(RoutePaths.studentSubscription),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.studentInk,
                ),
                child: Text(
                  hasActive ? '관리' : '구독하기',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasActive)
            _buildActiveSubscription(sub)
          else
            Text(
              loading ? '…' : 'AI 튜터, 구독하고 무제한으로 질문하세요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _shell.titleColor,
                height: 1.2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscription(Subscription sub) {
    final daysLeft = _daysLeft(sub.endDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                size: 20, color: AppColors.studentInk),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${sub.planName ?? '구독'} 이용 중',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _shell.titleColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (sub.autoRenew
                        ? AppColors.studentInk
                        : _shell.hintColor)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sub.autoRenew ? '자동갱신 ON' : '자동갱신 OFF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      sub.autoRenew ? AppColors.studentInk : _shell.hintColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          [
            if (sub.endDate != null) '${_ymd(sub.endDate!)}까지',
            if (daysLeft != null) '남은 $daysLeft일',
          ].join(' · '),
          style: TextStyle(fontSize: 13, color: _shell.hintColor),
        ),
      ],
    );
  }

  static int? _daysLeft(DateTime? end) {
    if (end == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = end.difference(today).inDays;
    return d < 0 ? 0 : d;
  }

  static String _ymd(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}.${two(l.month)}.${two(l.day)}';
  }

  Widget _buildStatsSection() {
    final reviewCount = ref.watch(myReviewsProvider).valueOrNull?.length;
    final reportCount = ref.watch(myReportsProvider).valueOrNull?.length;
    String fmt(int? n) => n == null ? '…' : '$n';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('활동 통계'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StudentStatCard(value: fmt(reviewCount), label: '작성 리뷰'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StudentStatCard(value: fmt(reportCount), label: '접수 신고'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: _shell.titleColor,
      ),
    );
  }

  Widget _buildSettingsCard() {
    final me = ref.watch(meProvider).valueOrNull;
    // 소셜 계정은 비밀번호가 없으므로 '비밀번호 변경'을 LOCAL 가입자에게만 노출.
    final isLocal = (me?['provider'] as String?) == 'LOCAL';
    final email = me?['email'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('설정 · 지원'),
        const SizedBox(height: 8),
        _buildGroupedMenuCard(
          children: [
            if (isLocal)
              _buildMenuRow(
                icon: Icons.lock_outline_rounded,
                title: '비밀번호 변경',
                onTap: () => context.push(
                  RoutePaths.passwordReset,
                  extra: PasswordResetArgs(email: email, isTutor: false),
                ),
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
        const SizedBox(height: 12),
        _buildNotificationSettingsCard(),
      ],
    );
  }

  Widget _buildNotificationSettingsCard() {
    final pushEnabled =
        ref.watch(studentNotificationSettingsProvider).pushEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 설정',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _shell.titleColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildGroupedMenuCard(
          children: [
            _buildNotificationRow(
              icon: Icons.notifications_active_outlined,
              title: '푸시 알림 받기',
              value: pushEnabled,
              onChanged: (v) => _updateNotificationSetting(
                enabled: v,
                update: (notifier) => notifier.setAll(v),
              ),
              showDivider: false,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateNotificationSetting({
    required bool enabled,
    required Future<void> Function(StudentNotificationSettingsNotifier) update,
  }) async {
    if (enabled) {
      final granted =
          await ref.read(appNotificationServiceProvider).requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림 권한이 필요합니다. 기기 설정에서 허용해 주세요.'),
          ),
        );
      }
    }
    await update(ref.read(studentNotificationSettingsProvider.notifier));
  }

  Widget _buildGroupedMenuCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _pageBackground,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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

  Widget _buildNotificationRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return isDark ? const Color(0xFF2A2E38) : Colors.white;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    return states.contains(WidgetState.selected)
                        ? AppColors.studentInk
                        : _shell.trackOffColor;
                  }),
                  trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                ),
                child: Transform.scale(
                  scale: 0.82,
                  alignment: Alignment.center,
                  child: CupertinoSwitch(
                    value: value,
                    onChanged: onChanged,
                    activeTrackColor: AppColors.studentInk,
                    inactiveTrackColor: _shell.trackOffColor,
                    thumbColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2E38)
                            : Colors.white,
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
        color: AppColors.roleStudentBorder.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.studentInk, size: 18),
    );
  }

  void _showCustomerCenterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final bottom = MediaQuery.paddingOf(sheetContext).bottom;
        bool copied = false; // 이메일 복사 피드백(시트 내부 상태)
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void copyEmail() {
              Clipboard.setData(const ClipboardData(text: _supportEmail));
              setSheetState(() => copied = true);
            }

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
              const SizedBox(height: 16),
              Text(
                '고객센터',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _shell.titleColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '이용 중 궁금한 점은 아래 방법으로 문의해 주세요.',
                style: TextStyle(fontSize: 13, color: _shell.hintColor),
              ),
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
                          Icon(Icons.check_circle_rounded,
                              size: 18, color: Color(0xFF2E9E6B)),
                          SizedBox(width: 4),
                          Text('복사됨',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E9E6B))),
                        ],
                      )
                    : Icon(Icons.copy_rounded,
                        size: 18, color: _shell.chevronColor),
              ),
              const SizedBox(height: 4),
              Text(
                '1:1 문의는 위 이메일로 보내주세요. 보통 1영업일 내 답변드려요.',
                style: TextStyle(fontSize: 12, color: _shell.hintColor),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: copyEmail,
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.studentPoint,
                    foregroundColor: AppColors.studentInk,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: Text(copied ? '이메일이 복사됐어요' : '문의 이메일 복사하기'),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.studentInk, size: 22),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 2),
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
                if (trailing != null)
                  trailing
                else if (onTap != null)
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
      shape: const RoundedRectangleBorder(
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
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _faqItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, index) {
                      final item = _faqItems[index];
                      return Theme(
                        data: Theme.of(sheetContext).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor:
                              AppColors.studentPoint.withValues(alpha: 0.08),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _shell.detailBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _shell.cardBorder.withValues(alpha: 0.6),
                            ),
                          ),
                          child: ExpansionTile(
                            tilePadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            childrenPadding:
                                const EdgeInsets.fromLTRB(14, 0, 14, 14),
                            title: Text(
                              item.question,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _shell.titleColor,
                              ),
                            ),
                            iconColor: AppColors.studentInk,
                            collapsedIconColor: scheme.onSurfaceVariant,
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

  static const _supportEmail = 'ieum.team@gmail.com';
}

class _StudentStatCard extends StatelessWidget {
  const _StudentStatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final cardBg = Theme.of(context).brightness == Brightness.dark
        ? shell.cardBackground
        : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.studentInk,
              height: 1.15,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: shell.hintColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
