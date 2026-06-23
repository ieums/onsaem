import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ieum/core/constants/api_constants.dart';
import 'package:ieum/core/theme/app_colors.dart';
import 'package:ieum/core/theme/app_theme.dart';
import 'package:ieum/core/theme/shell_theme_extension.dart';
import 'package:ieum/features/student/models/student_problem_model.dart';
import 'package:ieum/features/student/providers/problem_provider.dart';
import 'package:ieum/features/student/utils/problem_enum_labels.dart';
import 'package:ieum/features/student/utils/problem_type_registry.dart';
import 'package:ieum/features/student/widgets/student_tutor_profile_widgets.dart';

/// 분류/내용 수정 화면. PATCH /problems/{id}/classification.
/// 저장 성공 시 Navigator.pop(true) → 목록이 새로고침.
class StudentProblemEditScreen extends ConsumerStatefulWidget {
  const StudentProblemEditScreen({super.key, required this.problem});

  final StudentProblemModel problem;

  @override
  ConsumerState<StudentProblemEditScreen> createState() =>
      _StudentProblemEditScreenState();
}

class _StudentProblemEditScreenState
    extends ConsumerState<StudentProblemEditScreen> {
  late String _subject;
  String? _difficulty;
  String? _examType;
  String? _primaryType;
  String? _secondaryType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.problem;
    _subject = subjectLabels.containsKey(p.subject) ? p.subject! : 'UNKNOWN';
    _difficulty = difficultyLabels.containsKey(p.difficulty) ? p.difficulty : null;
    _examType = examTypeLabels.containsKey(p.examType) ? p.examType : null;
    // 레지스트리에 있는 값만 채택(없으면 미선택)
    _primaryType =
        primaryTypesFor(_subject).contains(p.primaryType) ? p.primaryType : null;
    _secondaryType =
        secondaryTypesFor(_primaryType).contains(p.secondaryType)
            ? p.secondaryType
            : null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(problemRepositoryProvider).updateClassification(
            problemId: widget.problem.problemId,
            subject: _subject,
            primaryType: _primaryType,
            secondaryType: _secondaryType,
            difficulty: _difficulty,
            examType: _examType,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분류를 수정했어요.')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수정에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(shellDarkModeProvider);
    final baseTheme = isDark ? AppTheme.shellDark : AppTheme.shellLight;
    final theme = baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(primary: AppColors.studentInk),
      scaffoldBackgroundColor:
          isDark ? AppColors.shellScaffoldDark : Colors.white,
    );

    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final shell = ShellTheme.of(context);
          final p = widget.problem;
          return Scaffold(
            appBar: StudentFlowAppBar(
              title: '분류 수정',
              onBack: () => Navigator.of(context).pop(),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (p.imageUrls.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.network(
                          ApiConstants.resolveImageUrl(p.imageUrls.first),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: shell.detailBackground,
                            alignment: Alignment.center,
                            child: Icon(Icons.image_not_supported_outlined,
                                color: shell.hintColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    (p.summary?.trim().isNotEmpty ?? false)
                        ? p.summary!.trim()
                        : '문제 요약 없음',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: shell.titleColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI 분류가 정확하지 않다면 직접 바로잡아 주세요.',
                    style: TextStyle(fontSize: 13, color: shell.hintColor),
                  ),
                  const SizedBox(height: 24),
                  _label(shell, '과목'),
                  _dropdown(
                    shell: shell,
                    value: _subject,
                    labels: subjectLabels,
                    onChanged: (v) => setState(() {
                      _subject = v!;
                      _primaryType = null; // 과목이 바뀌면 대/소분류 초기화
                      _secondaryType = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  _label(shell, '난이도'),
                  _dropdown(
                    shell: shell,
                    value: _difficulty,
                    labels: difficultyLabels,
                    hint: '선택 안 함',
                    onChanged: (v) => setState(() => _difficulty = v),
                  ),
                  const SizedBox(height: 20),
                  _label(shell, '출처'),
                  _dropdown(
                    shell: shell,
                    value: _examType,
                    labels: examTypeLabels,
                    hint: '선택 안 함',
                    onChanged: (v) => setState(() => _examType = v),
                  ),
                  const SizedBox(height: 20),
                  _label(shell, '대분류 (선택)'),
                  _keywordChips(
                    shell: shell,
                    options: primaryTypesFor(_subject),
                    selected: _primaryType,
                    emptyHint: '과목을 먼저 선택하세요.',
                    onTap: (v) => setState(() {
                      // 같은 칩 다시 누르면 해제, 바뀌면 소분류 초기화
                      _primaryType = _primaryType == v ? null : v;
                      _secondaryType = null;
                    }),
                  ),
                  const SizedBox(height: 20),
                  _label(shell, '소분류 (선택)'),
                  _keywordChips(
                    shell: shell,
                    options: secondaryTypesFor(_primaryType),
                    selected: _secondaryType,
                    emptyHint: '대분류를 먼저 선택하세요.',
                    onTap: (v) => setState(
                      () => _secondaryType = _secondaryType == v ? null : v,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.studentPoint,
                        foregroundColor: AppColors.studentInk,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '저장',
                              style: TextStyle(
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

  Widget _label(ShellTheme shell, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: shell.subtitleColor,
          ),
        ),
      );

  Widget _dropdown({
    required ShellTheme shell,
    required String? value,
    required Map<String, String> labels,
    String? hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _fieldDecoration(shell),
      hint: hint == null
          ? null
          : Text(hint, style: TextStyle(color: shell.hintColor)),
      dropdownColor: shell.cardBackground,
      style: TextStyle(fontSize: 15, color: shell.titleColor),
      items: labels.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
    );
  }

  /// 키워드 칩 선택(대분류/소분류). 단일 선택 — 누르면 토글.
  /// 선택: ✓ + 연두 채움 / 미선택: + 외곽선.
  Widget _keywordChips({
    required ShellTheme shell,
    required List<String> options,
    required String? selected,
    required String emptyHint,
    required ValueChanged<String> onTap,
  }) {
    if (options.isEmpty) {
      return Text(
        emptyHint,
        style: TextStyle(fontSize: 13, color: shell.hintColor),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSel = o == selected;
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTap(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.studentPoint.withValues(alpha: 0.5)
                  : shell.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel ? AppColors.studentInk : shell.cardBorder,
                width: isSel ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSel ? Icons.check : Icons.add,
                  size: 15,
                  color: isSel ? AppColors.studentInk : shell.hintColor,
                ),
                const SizedBox(width: 4),
                Text(
                  o,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? AppColors.studentInk : shell.titleColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _fieldDecoration(ShellTheme shell) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: shell.cardBorder.withValues(alpha: 0.5)),
    );
    return InputDecoration(
      filled: true,
      fillColor: shell.cardBackground,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.studentInk, width: 1.6),
      ),
    );
  }
}
