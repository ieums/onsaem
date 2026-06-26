import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/repositories/mypage_repository.dart';
import 'package:ieum/routes/app_router.dart';

/// 신고 대상 상대방 종류(강의 종료 후: 학생↔강사).
enum ReportPersonType { tutor, student }

class StudentReportArgs {
  const StudentReportArgs({
    required this.lessonId,
    required this.personType,
    required this.personId,
    required this.personName,
  });

  final int lessonId;
  final ReportPersonType personType; // 상대방이 강사인지 학생인지
  final String personId;
  final String personName;
}

class StudentReportScreen extends ConsumerStatefulWidget {
  const StudentReportScreen({super.key, required this.args});

  final StudentReportArgs args;

  @override
  ConsumerState<StudentReportScreen> createState() =>
      _StudentReportScreenState();
}

class _StudentReportScreenState extends ConsumerState<StudentReportScreen> {
  // 사람(강사/학생) 신고 사유 — 백엔드 ReportReason '사람' 그룹과 동일.
  static const _personReasons = <({String label, String code})>[
    (label: '욕설/모욕', code: 'ABUSE'),
    (label: '노쇼/불참', code: 'NO_SHOW'),
    (label: '부적절한 행동', code: 'INAPPROPRIATE'),
    (label: '사기/허위', code: 'FRAUD'),
    (label: '스팸/광고', code: 'SPAM'),
    (label: '기타', code: 'ETC'),
  ];
  // 강의 신고 사유 — 백엔드 ReportReason '강의' 그룹과 동일.
  static const _lessonReasons = <({String label, String code})>[
    (label: '연결/음성·영상 문제', code: 'CONNECTION_ISSUE'),
    (label: '기술 오류(녹화·판서 등)', code: 'TECHNICAL_ISSUE'),
    (label: '강의 미진행/중단', code: 'LESSON_NOT_HELD'),
    (label: '기타', code: 'ETC'),
  ];

  // 현재 신고 대상에 맞는 사유 목록.
  List<({String label, String code})> get _activeReasons =>
      _targetIsLesson ? _lessonReasons : _personReasons;

  static const _maxDetailLength = 500;

  final _detailController = TextEditingController();
  int _step = 0;
  int? _selectedTypeIndex;
  bool _targetIsLesson = false; // false=상대방, true=강의 자체(품질이슈)
  bool _submitting = false;

  String get _personRoleLabel =>
      widget.args.personType == ReportPersonType.tutor ? '강사' : '학생';

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  ThemeData _flowTheme(bool isDark) {
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
  }

  void _goNext() {
    if (_selectedTypeIndex == null) return;
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    if (_selectedTypeIndex == null || _submitting) return;
    setState(() => _submitting = true);

    final targetType = _targetIsLesson
        ? 'LESSON'
        : (widget.args.personType == ReportPersonType.tutor ? 'TUTOR' : 'STUDENT');
    final targetId =
        _targetIsLesson ? widget.args.lessonId : int.tryParse(widget.args.personId);
    if (targetId == null) {
      setState(() => _submitting = false);
      return;
    }

    try {
      await MypageRepository().createReport(
        targetType: targetType,
        targetId: targetId,
        lessonId: widget.args.lessonId,
        reasons: [_activeReasons[_selectedTypeIndex!].code],
        description: _detailController.text,
      );
      if (!mounted) return;
      context.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final rootContext = appRouter.routerDelegate.navigatorKey.currentContext;
        if (rootContext == null) return;
        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다.')),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신고 접수에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final theme = _flowTheme(isDark);

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          final buttonLabelColor = AppColors.studentInk;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: shell.titleColor,
                          ),
                        ),
                        Text(
                          '신고하기',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: shell.titleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _ReportProgressBar(step: _step),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '신고 유형 선택',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _step == 0
                                  ? AppColors.studentInk
                                  : shell.hintColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '상세 내용',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _step == 1
                                  ? AppColors.studentInk
                                  : shell.hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ReportTargetCard(
                            shell: shell,
                            name: _targetIsLesson ? '강의' : widget.args.personName,
                            roleLabel: _targetIsLesson
                                ? '진행한 수업'
                                : _personRoleLabel,
                          ),
                          const SizedBox(height: 20),
                          if (_step == 0) ...[
                            Text(
                              '무엇을 신고하나요?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: shell.titleColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _TargetToggle(
                                    shell: shell,
                                    label: '$_personRoleLabel 신고',
                                    selected: !_targetIsLesson,
                                    onTap: () => setState(() {
                                      _targetIsLesson = false;
                                      _selectedTypeIndex = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _TargetToggle(
                                    shell: shell,
                                    label: '강의 신고',
                                    selected: _targetIsLesson,
                                    onTap: () => setState(() {
                                      _targetIsLesson = true;
                                      _selectedTypeIndex = null;
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '신고 유형을 선택해 주세요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: shell.titleColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            for (var i = 0; i < _activeReasons.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _ReportTypeTile(
                                shell: shell,
                                label: _activeReasons[i].label,
                                selected: _selectedTypeIndex == i,
                                onTap: () => setState(() => _selectedTypeIndex = i),
                              ),
                            ],
                          ] else ...[
                            if (_selectedTypeIndex != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.studentPoint.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.studentPoint.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppColors.studentInk,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _activeReasons[_selectedTypeIndex!].label,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.studentInk,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              '어떤 일이 있었나요?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: shell.titleColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '구체적으로 작성할수록 빠른 처리가 가능해요',
                              style: TextStyle(
                                fontSize: 13,
                                color: shell.subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _detailController,
                              maxLength: _maxDetailLength,
                              maxLines: 6,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: shell.titleColor,
                              ),
                              decoration: InputDecoration(
                                hintText: '신고 내용을 자세히 적어주세요 (선택)',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: shell.hintColor,
                                ),
                                filled: true,
                                fillColor: shell.detailBackground,
                                counterStyle: TextStyle(
                                  fontSize: 12,
                                  color: shell.hintColor,
                                ),
                                contentPadding: const EdgeInsets.all(14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: shell.cardBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: shell.cardBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.studentInk,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: shell.detailBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: shell.cardBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: shell.subtitleColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '허위 신고 시 서비스 이용이 제한될 수 있습니다. '
                                      '접수된 신고는 검토 후 약 7일 이내 처리됩니다.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: shell.subtitleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: FilledButton(
                      onPressed: _step == 0
                          ? (_selectedTypeIndex == null ? null : _goNext)
                          : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.studentPoint,
                        disabledBackgroundColor:
                            AppColors.studentPoint.withValues(alpha: 0.45),
                        foregroundColor: buttonLabelColor,
                        disabledForegroundColor: buttonLabelColor.withValues(
                          alpha: 0.7,
                        ),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        _step == 0 ? '다음' : '신고 제출',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
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
}

class _ReportProgressBar extends StatelessWidget {
  const _ReportProgressBar({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final shell = ShellTheme.of(context);
    final progress = step == 0 ? 0.5 : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: shell.detailBackground),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.studentInk, AppColors.primaryBlue],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetToggle extends StatelessWidget {
  const _TargetToggle({
    required this.shell,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ShellTheme shell;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.studentPoint.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.studentInk : shell.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.studentInk : shell.subtitleColor,
          ),
        ),
      ),
    );
  }
}

class _ReportTargetCard extends StatelessWidget {
  const _ReportTargetCard({
    required this.shell,
    required this.name,
    required this.roleLabel,
  });

  final ShellTheme shell;
  final String name;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: shell.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: shell.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: shell.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: shell.detailBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: shell.cardBorder),
            ),
            child: Text(
              '신고 대상',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: shell.subtitleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTypeTile extends StatelessWidget {
  const _ReportTypeTile({
    required this.shell,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ShellTheme shell;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: shell.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.studentInk : shell.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: shell.titleColor,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.studentInk : shell.cardBorder,
                    width: selected ? 2 : 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.studentInk,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
