import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/routes/app_router.dart';

class StudentReportArgs {
  const StudentReportArgs({
    required this.tutorId,
    required this.tutorName,
  });

  final String tutorId;
  final String tutorName;
}

class StudentReportScreen extends ConsumerStatefulWidget {
  const StudentReportScreen({super.key, required this.args});

  final StudentReportArgs args;

  @override
  ConsumerState<StudentReportScreen> createState() =>
      _StudentReportScreenState();
}

class _StudentReportScreenState extends ConsumerState<StudentReportScreen> {
  static const _reportTypes = [
    '욕설 / 비방',
    '불쾌한 콘텐츠',
    '스팸 / 광고',
    '사기 / 허위 정보',
    '무단 이탈 / 노쇼',
    '기타',
  ];
  static const _maxDetailLength = 500;

  final _detailController = TextEditingController();
  int _step = 0;
  int? _selectedTypeIndex;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  ThemeData _flowTheme(bool isDark) {
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentPoint),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );
  }

  void _goNext() {
    if (_selectedTypeIndex == null) return;
    setState(() => _step = 1);
  }

  void _submit() {
    if (_selectedTypeIndex == null) return;
    if (!mounted) return;
    context.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rootContext = appRouter.routerDelegate.navigatorKey.currentContext;
      if (rootContext == null) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(content: Text('신고가 접수되었습니다.')),
      );
    });
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
          final buttonLabelColor =
              isDark ? AppColors.shellOnSurfaceLight : Colors.white;

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
                                  ? AppColors.studentPoint
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
                                  ? AppColors.studentPoint
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
                            tutorName: widget.args.tutorName,
                          ),
                          const SizedBox(height: 20),
                          if (_step == 0) ...[
                            Text(
                              '신고 유형을 선택해 주세요',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: shell.titleColor,
                              ),
                            ),
                            const SizedBox(height: 14),
                            for (var i = 0; i < _reportTypes.length; i++) ...[
                              if (i > 0) const SizedBox(height: 10),
                              _ReportTypeTile(
                                shell: shell,
                                label: _reportTypes[i],
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
                                          color: AppColors.studentPoint,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _reportTypes[_selectedTypeIndex!],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.studentPoint,
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
                                    color: AppColors.studentPoint,
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
                    colors: [AppColors.studentPoint, AppColors.primaryBlue],
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

class _ReportTargetCard extends StatelessWidget {
  const _ReportTargetCard({
    required this.shell,
    required this.tutorName,
  });

  final ShellTheme shell;
  final String tutorName;

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
                  tutorName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: shell.titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '강사',
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
              color: selected ? AppColors.studentPoint : shell.cardBorder,
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
                    color: selected ? AppColors.studentPoint : shell.cardBorder,
                    width: selected ? 2 : 1.5,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.studentPoint,
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
