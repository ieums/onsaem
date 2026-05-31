import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/constants/route_paths.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/providers/student_wallet_provider.dart';
import 'package:ieum/features/student/widgets/student_auto_pay_bottom_sheet.dart';
class StudentMyPageScreen extends ConsumerStatefulWidget {
  const StudentMyPageScreen({super.key});

  @override
  ConsumerState<StudentMyPageScreen> createState() => _StudentMyPageScreenState();
}

class _StudentMyPageScreenState extends ConsumerState<StudentMyPageScreen> {
  ShellTheme get _shell => ShellTheme.of(context);

  bool _matchingAlert = true;
  bool _aiTutorAlert = true;
  bool _extendTimeAlert = true;

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
      question: '수업 신청은 어떻게 하나요?',
      answer:
          '홈 탭에서 원하는 과목·강사를 선택한 뒤 수업 시간을 예약하면 됩니다. 보유 크레딧이 부족하면 충전 후 신청할 수 있어요.',
    ),
    (
      question: 'AI 튜터는 무료인가요?',
      answer:
          'AI 튜터는 별도 크레딧 없이 이용할 수 있도록 준비 중입니다. 정식 오픈 시 앱 공지로 안내드릴게요.',
    ),
    (
      question: '수업 취소·환불은 어떻게 되나요?',
      answer:
          '수업 시작 24시간 전까지 취소 시 크레딧 전액이 환급됩니다. 24시간 이내 취소는 정책에 따라 일부 차감될 수 있습니다.',
    ),
    (
      question: '프로필은 어디서 수정하나요?',
      answer:
          '마이페이지 「프로필 수정」에서 이름·생년월일·이메일·휴대폰·프로필 사진을 변경할 수 있습니다.',
    ),
    (
      question: '자동 결제는 어떻게 등록하나요?',
      answer:
          '마이페이지 「자동 결제 수단」을 누르면 신용·체크카드를 등록할 수 있습니다.',
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
              _buildStatsSection(),
              const SizedBox(height: 14),
              _buildGroupedMenuCard(
                children: [
                  _buildMenuRow(
                    icon: Icons.person_outline,
                    title: '프로필 수정',
                    onTap: () =>
                        context.push('${RoutePaths.signupStudent}?edit=true'),
                  ),
                  _buildMenuRow(
                    icon: Icons.autorenew_rounded,
                    title: '자동 결제 수단',
                    onTap: () => showStudentAutoPayBottomSheet(context),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(RoutePaths.login),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.logoutRed,
                    side: const BorderSide(color: AppColors.logoutRed),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
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
          onPressed: () => context.go(RoutePaths.login),
          icon: const Icon(Icons.logout_outlined, size: 24),
          color: AppColors.logoutRed,
          tooltip: '로그아웃',
        ),
      ],
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pageBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _shell.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.roleStudentBorder.withValues(alpha: 0.35),
            child: const Icon(
              Icons.person,
              size: 42,
              color: AppColors.studentPoint,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '테스트',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _shell.titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'student@gmail.com',
                  style: TextStyle(
                    fontSize: 13,
                    color: _shell.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard() {
    final balance = ref.watch(studentWalletProvider).balance;
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
                  foregroundColor: AppColors.studentPoint,
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
            '${formatCredits(balance)} P',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.studentPoint,
              height: 1.1,
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
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(child: _StudentStatCard(value: '24', label: '수업 횟수')),
            SizedBox(width: 8),
            Expanded(child: _StudentStatCard(value: '18시간', label: '총 수업 시간')),
            SizedBox(width: 8),
            Expanded(child: _StudentStatCard(value: '20', label: '작성 리뷰')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('설정'),
        const SizedBox(height: 8),
        _buildGroupedMenuCard(
          children: [
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
              icon: Icons.handshake_outlined,
              title: '매칭 알림',
              value: _matchingAlert,
              onChanged: (v) => setState(() => _matchingAlert = v),
            ),
            _buildNotificationRow(
              icon: Icons.smart_toy_outlined,
              title: 'AI 튜터 알림',
              value: _aiTutorAlert,
              onChanged: (v) => setState(() => _aiTutorAlert = v),
            ),
            _buildNotificationRow(
              icon: Icons.schedule_rounded,
              title: '시간 연장 알림',
              value: _extendTimeAlert,
              onChanged: (v) => setState(() => _extendTimeAlert = v),
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
                        ? AppColors.studentPoint
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
                    activeTrackColor: AppColors.studentPoint,
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
      child: Icon(icon, color: AppColors.studentPoint, size: 18),
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
                icon: Icons.phone_in_talk_outlined,
                title: '전화 문의',
                subtitle: '1588-0000',
                onTap: () => _showSnack('전화 연결은 준비 중이에요.'),
              ),
              _buildSupportTile(
                icon: Icons.mail_outline_rounded,
                title: '이메일 문의',
                subtitle: 'support@onsaem.com',
                onTap: () => _showSnack('메일 앱 연동은 준비 중이에요.'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showSnack('1:1 문의는 준비 중이에요.');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.studentPoint,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('1:1 문의하기'),
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
                Icon(icon, color: AppColors.studentPoint, size: 22),
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
                            iconColor: AppColors.studentPoint,
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
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
              color: AppColors.studentPoint,
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
