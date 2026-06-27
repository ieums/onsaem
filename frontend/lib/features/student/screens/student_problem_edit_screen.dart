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
import 'package:ieum/features/student/widgets/student_problem_image_viewer.dart';
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

  // (2) 여러 장 한 문제 — 페이지 순서 재정렬용 상태.
  // _pageUrls = 현재 서버에 저장된 순서(기준선), _order = 그 위에 얹힌 사용자 드래그 순열.
  late List<String> _pageUrls;
  late List<int> _order;
  bool _savingOrder = false;

  // 비-multiPage(여러 장 일반) 미리보기 캐러셀 상태.
  final PageController _previewController = PageController();
  int _previewPage = 0;

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  bool get _isMultiPage =>
      widget.problem.multiPage && widget.problem.imageUrls.length > 1;

  bool get _orderChanged {
    for (var i = 0; i < _order.length; i++) {
      if (_order[i] != i) return true;
    }
    return false;
  }

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

    _pageUrls = List<String>.of(p.imageUrls);
    _order = List<int>.generate(_pageUrls.length, (i) => i);
  }

  Future<void> _saveOrder() async {
    setState(() => _savingOrder = true);
    try {
      final newUrls = await ref.read(problemRepositoryProvider).reorderPages(
            problemId: widget.problem.problemId,
            order: _order,
          );
      if (!mounted) return;
      setState(() {
        // 서버 반영 순서를 새 기준선으로 — 이후 재정렬도 올바른 인덱스로 계산되게.
        _pageUrls = newUrls.isNotEmpty
            ? newUrls
            : [for (final i in _order) _pageUrls[i]];
        _order = List<int>.generate(_pageUrls.length, (i) => i);
        _savingOrder = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('페이지 순서를 변경했어요.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('순서 변경에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
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
                  if (_isMultiPage) ...[
                    _pageReorderSection(shell),
                    const SizedBox(height: 20),
                  ] else if (p.imageUrls.isNotEmpty) ...[
                    _previewCarousel(shell, p.imageUrls),
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

  /// 비-multiPage 미리보기 — 여러 장이면 좌우로 넘기고, 탭하면 전체화면 갤러리(좌우 스와이프+확대).
  Widget _previewCarousel(ShellTheme shell, List<String> urls) {
    void openGallery(int index) => showStudentProblemImageGalleryUrls(
          context,
          imageUrls: [
            for (final u in urls) ApiConstants.resolveImageUrl(u),
          ],
          initialIndex: index,
        );

    Widget tile(int i) => GestureDetector(
          onTap: () => openGallery(i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              ApiConstants.resolveImageUrl(urls[i]),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: shell.detailBackground,
                alignment: Alignment.center,
                child: Icon(Icons.image_not_supported_outlined,
                    color: shell.hintColor),
              ),
            ),
          ),
        );

    if (urls.length == 1) {
      return AspectRatio(aspectRatio: 16 / 10, child: tile(0));
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: PageView.builder(
            controller: _previewController,
            itemCount: urls.length,
            onPageChanged: (i) => setState(() => _previewPage = i),
            itemBuilder: (_, i) => tile(i),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < urls.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _previewPage ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color:
                      i == _previewPage ? AppColors.studentInk : shell.cardBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// (2) 여러 장 한 문제의 페이지 순서 재정렬 섹션. 끌어서 순서를 바꾸고 '이 순서로 저장'.
  Widget _pageReorderSection(ShellTheme shell) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '페이지 순서',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: shell.titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '여러 장이 한 문제로 인식됐어요. 순서가 어긋났다면 끌어서 바로잡아 주세요.',
          style: TextStyle(fontSize: 13, color: shell.hintColor),
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _order.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _order.removeAt(oldIndex);
              _order.insert(newIndex, item);
            });
          },
          itemBuilder: (context, i) {
            final url = _pageUrls[_order[i]];
            return Container(
              key: ValueKey('page_${_order[i]}'),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: shell.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: shell.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.studentPoint.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.studentInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => showStudentProblemImageGalleryUrls(
                      context,
                      imageUrls: [
                        for (final o in _order)
                          ApiConstants.resolveImageUrl(_pageUrls[o]),
                      ],
                      initialIndex: i,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.network(
                          ApiConstants.resolveImageUrl(url),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: shell.detailBackground,
                            alignment: Alignment.center,
                            child: Icon(Icons.image_not_supported_outlined,
                                size: 20, color: shell.hintColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${i + 1}페이지',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: shell.titleColor,
                      ),
                    ),
                  ),
                  Icon(Icons.drag_handle, color: shell.hintColor),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 46,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (_orderChanged && !_savingOrder) ? _saveOrder : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.studentInk,
              side: BorderSide(
                color: _orderChanged
                    ? AppColors.studentInk
                    : shell.cardBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _savingOrder
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text(
              '이 순서로 저장',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
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
